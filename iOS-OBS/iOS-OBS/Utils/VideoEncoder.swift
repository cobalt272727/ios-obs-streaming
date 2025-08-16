import Foundation
import AVFoundation
import VideoToolbox
import os.log

protocol VideoEncoderDelegate: AnyObject {
    func videoEncoder(_ encoder: VideoEncoder, didEncodeFrame data: Data, timestamp: CMTime)
    func videoEncoder(_ encoder: VideoEncoder, didEncounterError error: Error)
}

class VideoEncoder {
    weak var delegate: VideoEncoderDelegate?
    
    private var compressionSession: VTCompressionSession?
    private let encodingQueue = DispatchQueue(label: "video.encoding.queue")
    
    private let resolution: CGSize
    private let bitrate: Int
    private let frameRate: Int
    
    private let logger = Logger(subsystem: "com.example.iOS-OBS", category: "VideoEncoder")
    
    private var frameCount: Int64 = 0
    private var isEncoding = false
    
    init(resolution: CGSize, bitrate: Int, frameRate: Int) {
        self.resolution = resolution
        self.bitrate = bitrate
        self.frameRate = frameRate
        
        setupCompressionSession()
    }
    
    deinit {
        stopEncoding()
    }
    
    func encode(sampleBuffer: CMSampleBuffer) {
        guard isEncoding else { return }
        
        encodingQueue.async { [weak self] in
            self?.encodeFrame(sampleBuffer)
        }
    }
    
    func startEncoding() {
        encodingQueue.async { [weak self] in
            guard let self = self else { return }
            self.isEncoding = true
            self.logger.info("Video encoding started")
        }
    }
    
    func stopEncoding() {
        encodingQueue.async { [weak self] in
            guard let self = self else { return }
            self.isEncoding = false
            
            if let session = self.compressionSession {
                VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: CMTime.invalid)
                VTCompressionSessionInvalidate(session)
                self.compressionSession = nil
            }
            
            self.frameCount = 0
            self.logger.info("Video encoding stopped")
        }
    }
    
    private func setupCompressionSession() {
        encodingQueue.async { [weak self] in
            guard let self = self else { return }
            
            let width = Int32(self.resolution.width)
            let height = Int32(self.resolution.height)
            
            let status = VTCompressionSessionCreate(
                allocator: kCFAllocatorDefault,
                width: width,
                height: height,
                codecType: kCMVideoCodecType_H264,
                encoderSpecification: nil,
                imageBufferAttributes: nil,
                compressedDataAllocator: kCFAllocatorDefault,
                outputCallback: self.compressionOutputCallback,
                refcon: Unmanaged.passUnretained(self).toOpaque(),
                compressionSessionOut: &self.compressionSession
            )
            
            guard status == noErr, let session = self.compressionSession else {
                self.logger.error("Failed to create compression session: \(status)")
                self.delegate?.videoEncoder(self, didEncounterError: VideoEncoderError.compressionSessionCreationFailed)
                return
            }
            
            // Configure session properties
            self.configureCompressionSession(session)
            
            // Prepare session
            VTCompressionSessionPrepareToEncodeFrames(session)
            
            self.logger.info("Video encoder configured: \(width)x\(height) @ \(self.bitrate)kbps, \(self.frameRate)fps")
        }
    }
    
    private func configureCompressionSession(_ session: VTCompressionSession) {
        // Set bitrate
        VTSessionSetProperty(session, kVTCompressionPropertyKey_AverageBitRate, NSNumber(value: bitrate * 1000))
        
        // Set frame rate
        VTSessionSetProperty(session, kVTCompressionPropertyKey_ExpectedFrameRate, NSNumber(value: frameRate))
        
        // Set key frame interval
        VTSessionSetProperty(session, kVTCompressionPropertyKey_MaxKeyFrameInterval, NSNumber(value: frameRate * 2))
        
        // Set profile level
        VTSessionSetProperty(session, kVTCompressionPropertyKey_ProfileLevel, kVTProfileLevel_H264_Main_AutoLevel)
        
        // Enable real-time encoding
        VTSessionSetProperty(session, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue)
        
        // Set entropy mode
        VTSessionSetProperty(session, kVTCompressionPropertyKey_H264EntropyMode, kVTH264EntropyMode_CABAC)
        
        // Allow frame reordering
        VTSessionSetProperty(session, kVTCompressionPropertyKey_AllowFrameReordering, kCFBooleanFalse)
    }
    
    private func encodeFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let session = compressionSession,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetDuration(sampleBuffer)
        
        frameCount += 1
        
        let status = VTCompressionSessionEncodeFrame(
            session,
            imageBuffer: pixelBuffer,
            presentationTimeStamp: presentationTime,
            duration: duration,
            frameProperties: nil,
            sourceFrameRefcon: nil,
            infoFlagsOut: nil
        )
        
        if status != noErr {
            logger.error("Failed to encode frame: \(status)")
            delegate?.videoEncoder(self, didEncounterError: VideoEncoderError.frameEncodingFailed)
        }
    }
    
    private let compressionOutputCallback: VTCompressionOutputCallback = { (
        outputCallbackRefCon: UnsafeMutableRawPointer?,
        sourceFrameRefCon: UnsafeMutableRawPointer?,
        status: OSStatus,
        infoFlags: VTEncodeInfoFlags,
        sampleBuffer: CMSampleBuffer?
    ) in
        guard let outputCallbackRefCon = outputCallbackRefCon else { return }
        
        let encoder = Unmanaged<VideoEncoder>.fromOpaque(outputCallbackRefCon).takeUnretainedValue()
        
        guard status == noErr,
              let sampleBuffer = sampleBuffer,
              CMSampleBufferDataIsReady(sampleBuffer) else {
            encoder.logger.error("Compression callback error: \(status)")
            encoder.delegate?.videoEncoder(encoder, didEncounterError: VideoEncoderError.compressionCallbackError)
            return
        }
        
        encoder.handleEncodedFrame(sampleBuffer)
    }
    
    private func handleEncodedFrame(_ sampleBuffer: CMSampleBuffer) {
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            logger.error("Failed to get data buffer from encoded sample")
            return
        }
        
        var length: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        
        let status = CMBlockBufferGetDataPointer(dataBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)
        
        guard status == noErr,
              let pointer = dataPointer else {
            logger.error("Failed to get data pointer: \(status)")
            return
        }
        
        let data = Data(bytes: pointer, count: length)
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Check if this is a key frame
        let isKeyFrame = checkIfKeyFrame(sampleBuffer)
        
        logger.debug("Encoded frame: \(data.count) bytes, keyframe: \(isKeyFrame)")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.delegate?.videoEncoder(self, didEncodeFrame: data, timestamp: timestamp)
        }
    }
    
    private func checkIfKeyFrame(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[CFString: Any]],
              let attachment = attachments.first else {
            return false
        }
        
        return attachment[kCMSampleAttachmentKey_NotSync] == nil
    }
}

enum VideoEncoderError: Error, LocalizedError {
    case compressionSessionCreationFailed
    case frameEncodingFailed
    case compressionCallbackError
    
    var errorDescription: String? {
        switch self {
        case .compressionSessionCreationFailed:
            return "Failed to create video compression session"
        case .frameEncodingFailed:
            return "Failed to encode video frame"
        case .compressionCallbackError:
            return "Video compression callback error"
        }
    }
}