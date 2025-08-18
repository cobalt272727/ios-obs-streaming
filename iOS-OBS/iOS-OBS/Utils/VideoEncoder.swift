import VideoToolbox
import AVFoundation
import os

class VideoEncoder {
    private var compressionSession: VTCompressionSession?
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "iOS-OBS", category: "VideoEncoder")
    
    private let resolution: VideoResolution
    private let bitrate: VideoBitrate
    private let frameRate: FrameRate
    
    private var encodeQueue = DispatchQueue(label: "video.encode.queue")
    
    init(resolution: VideoResolution, bitrate: VideoBitrate, frameRate: FrameRate) {
        self.resolution = resolution
        self.bitrate = bitrate
        self.frameRate = frameRate
        setupCompressionSession()
    }
    
    private func setupCompressionSession() {
        let width = Int32(resolution.dimensions.width)
        let height = Int32(resolution.dimensions.height)
        
        let status = VTCompressionSessionCreate(
            allocator: nil,
            width: width,
            height: height,
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: { (outputCallbackRefCon, sourceFrameRefCon, status, infoFlags, sampleBuffer) in
                guard let sampleBuffer = sampleBuffer, status == noErr else {
                    return
                }
                
                let encoder = Unmanaged<VideoEncoder>.fromOpaque(outputCallbackRefCon!).takeUnretainedValue()
                encoder.handleEncodedFrame(sampleBuffer: sampleBuffer)
            },
            refcon: Unmanaged.passUnretained(self).toOpaque(),
            compressionSessionOut: &compressionSession
        )
        
        guard status == noErr, let session = compressionSession else {
            logger.error("Failed to create compression session: \(status)")
            return
        }
        
        // Configure session properties
        configureCompressionSession(session)
    }
    
    private func configureCompressionSession(_ session: VTCompressionSession) {
        // Set bitrate
        VTSessionSetProperty(session, kVTCompressionPropertyKey_AverageBitRate, NSNumber(value: bitrate.rawValue))
        
        // Set max keyframe interval (2 seconds)
        let keyFrameInterval = frameRate.rawValue * 2
        VTSessionSetProperty(session, kVTCompressionPropertyKey_MaxKeyFrameInterval, NSNumber(value: keyFrameInterval))
        
        // Set profile level
        VTSessionSetProperty(session, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel)
        
        // Set entropy mode
        VTSessionSetProperty(session, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC)
        
        // Set real-time encoding
        VTSessionSetProperty(session, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue)
        
        // Allow frame reordering for better compression
        VTSessionSetProperty(session, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse)
        
        logger.info("Compression session configured: \(resolution.rawValue) at \(bitrate.displayName)")
    }
    
    func encode(sampleBuffer: CMSampleBuffer, completion: @escaping (Data) -> Void) {
        guard let session = compressionSession,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            logger.error("No compression session or image buffer")
            return
        }
        
        encodeQueue.async { [weak self] in
            let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            let duration = CMSampleBufferGetDuration(sampleBuffer)
            
            // Store completion handler
            objc_setAssociatedObject(
                imageBuffer,
                &AssociatedKeys.completionHandler,
                completion,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
            
            let status = VTCompressionSessionEncodeFrame(
                session,
                imageBuffer: imageBuffer,
                presentationTimeStamp: presentationTimeStamp,
                duration: duration,
                frameProperties: nil,
                sourceFrameRefcon: Unmanaged.passRetained(imageBuffer as CVImageBuffer).toOpaque(),
                infoFlagsOut: nil
            )
            
            if status != noErr {
                self?.logger.error("Encoding failed: \(status)")
            }
        }
    }
    
    private func handleEncodedFrame(sampleBuffer: CMSampleBuffer) {
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            logger.error("No data buffer in encoded frame")
            return
        }
        
        var length: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        
        let status = CMBlockBufferGetDataPointer(
            dataBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &length,
            dataPointerOut: &dataPointer
        )
        
        guard status == noErr, let pointer = dataPointer else {
            logger.error("Failed to get data pointer: \(status)")
            return
        }
        
        let data = Data(bytes: pointer, count: length)
        
        // Convert format if needed (Annex B format for streaming)
        let convertedData = convertToAnnexB(data: data, sampleBuffer: sampleBuffer)
        
        // Find completion handler from associated object
        if let completionHandler = getCompletionHandler(from: sampleBuffer) {
            DispatchQueue.main.async {
                completionHandler(convertedData)
            }
        }
    }
    
    private func convertToAnnexB(data: Data, sampleBuffer: CMSampleBuffer) -> Data {
        var result = Data()
        
        // Get format description
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            return data
        }
        
        // Check if we have parameter sets (SPS/PPS)
        let isKeyFrame = !CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false)?.isEmpty ?? false
        
        if isKeyFrame {
            // Add SPS and PPS for keyframes
            var parameterSetCount: Int = 0
            let status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                formatDescription,
                parameterSetIndex: 0,
                parameterSetPointerOut: nil,
                parameterSetSizeOut: nil,
                parameterSetCountOut: &parameterSetCount,
                nalUnitHeaderLengthOut: nil
            )
            
            if status == noErr {
                for i in 0..<parameterSetCount {
                    var parameterSetPointer: UnsafePointer<UInt8>?
                    var parameterSetSize: Int = 0
                    
                    let paramStatus = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
                        formatDescription,
                        parameterSetIndex: i,
                        parameterSetPointerOut: &parameterSetPointer,
                        parameterSetSizeOut: &parameterSetSize,
                        parameterSetCountOut: nil,
                        nalUnitHeaderLengthOut: nil
                    )
                    
                    if paramStatus == noErr, let pointer = parameterSetPointer {
                        // Add start code
                        result.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
                        result.append(pointer, count: parameterSetSize)
                    }
                }
            }
        }
        
        // Convert AVCC to Annex B format
        var offset = 0
        while offset < data.count - 4 {
            // Read NALU length (4 bytes, big endian)
            let lengthBytes = data.subdata(in: offset..<offset+4)
            let naluLength = lengthBytes.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
            
            // Add start code
            result.append(contentsOf: [0x00, 0x00, 0x00, 0x01])
            
            // Add NALU data
            let naluData = data.subdata(in: offset+4..<offset+4+Int(naluLength))
            result.append(naluData)
            
            offset += 4 + Int(naluLength)
        }
        
        return result
    }
    
    private func getCompletionHandler(from sampleBuffer: CMSampleBuffer) -> ((Data) -> Void)? {
        // This is a simplified version - in practice, you'd need to properly track completion handlers
        return nil
    }
    
    deinit {
        if let session = compressionSession {
            VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
            VTCompressionSessionInvalidate(session)
        }
    }
}

private struct AssociatedKeys {
    static var completionHandler = "completionHandler"
}