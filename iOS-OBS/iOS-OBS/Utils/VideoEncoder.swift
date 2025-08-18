import VideoToolbox
import AVFoundation
import Foundation

class VideoEncoder {
    
    private var compressionSession: VTCompressionSession?
    private var formatDescription: CMFormatDescription?
    
    weak var delegate: VideoEncoderDelegate?
    
    private let encodingQueue = DispatchQueue(label: "video.encoding.queue")
    
    // Encoding parameters
    private var bitrate: Int = 2500 // kbps
    private var keyframeInterval: Int = 60 // frames
    
    init() {}
    
    deinit {
        invalidate()
    }
    
    // MARK: - Public Methods
    
    func configure(width: Int, height: Int, bitrate: Int, frameRate: Int) throws {
        self.bitrate = bitrate
        
        invalidate()
        
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: Int32(width),
            height: Int32(height),
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: nil,
            imageBufferAttributes: nil,
            compressedDataAllocator: nil,
            outputCallback: outputCallback,
            refcon: Unmanaged.passUnretained(self).toOpaque(),
            compressionSessionOut: &compressionSession
        )
        
        guard status == noErr else {
            throw VideoEncoderError.failedToCreateSession(status)
        }
        
        guard let session = compressionSession else {
            throw VideoEncoderError.invalidSession
        }
        
        // Configure encoding properties
        try setProperty(session: session, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        try setProperty(session: session, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_High_AutoLevel)
        try setProperty(session: session, key: kVTCompressionPropertyKey_AllowFrameReordering, value: kCFBooleanFalse)
        try setProperty(session: session, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: keyframeInterval as CFNumber)
        try setProperty(session: session, key: kVTCompressionPropertyKey_AverageBitRate, value: (bitrate * 1000) as CFNumber)
        try setProperty(session: session, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: frameRate as CFNumber)
        
        // Prepare the session
        let prepareStatus = VTCompressionSessionPrepareToEncodeFrames(session)
        guard prepareStatus == noErr else {
            throw VideoEncoderError.failedToPrepareSession(prepareStatus)
        }
        
        print("Video encoder configured: \(width)x\(height) @ \(bitrate)kbps, \(frameRate)fps")
    }
    
    func encode(sampleBuffer: CMSampleBuffer) {
        guard let session = compressionSession else {
            print("Compression session not configured")
            return
        }
        
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get image buffer from sample buffer")
            return
        }
        
        let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetDuration(sampleBuffer)
        
        encodingQueue.async { [weak self] in
            let status = VTCompressionSessionEncodeFrame(
                session,
                imageBuffer: imageBuffer,
                presentationTimeStamp: presentationTimeStamp,
                duration: duration,
                frameProperties: nil,
                sourceFrameRefcon: nil,
                infoFlagsOut: nil
            )
            
            if status != noErr {
                print("Failed to encode frame: \(status)")
            }
        }
    }
    
    func invalidate() {
        if let session = compressionSession {
            VTCompressionSessionInvalidate(session)
            compressionSession = nil
        }
    }
    
    // MARK: - Private Methods
    
    private func setProperty(session: VTCompressionSession, key: CFString, value: CFTypeRef) throws {
        let status = VTSessionSetProperty(session, key: key, value: value)
        guard status == noErr else {
            throw VideoEncoderError.failedToSetProperty(key as String, status)
        }
    }
}

// MARK: - Compression Callback

private let outputCallback: VTCompressionOutputCallback = { (outputCallbackRefCon, sourceFrameRefCon, status, infoFlags, sampleBuffer) in
    
    guard status == noErr else {
        print("Encoding error: \(status)")
        return
    }
    
    guard let sampleBuffer = sampleBuffer else {
        print("Sample buffer is nil")
        return
    }
    
    guard let refcon = outputCallbackRefCon else {
        print("Refcon is nil")
        return
    }
    
    let encoder = Unmanaged<VideoEncoder>.fromOpaque(refcon).takeUnretainedValue()
    
    // Check if this is a keyframe
    let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false)
    var isKeyframe = false
    
    if let attachmentsArray = attachments,
       let attachment = CFArrayGetValueAtIndex(attachmentsArray, 0) {
        let attachmentDict = Unmanaged<CFDictionary>.fromOpaque(attachment).takeUnretainedValue()
        
        if CFDictionaryContainsKey(attachmentDict, Unmanaged.passUnretained(kCMSampleAttachmentKey_NotSync).toOpaque()) {
            isKeyframe = false
        } else {
            isKeyframe = true
        }
    }
    
    encoder.delegate?.videoEncoder(encoder, didOutput: sampleBuffer, isKeyframe: isKeyframe)
}

// MARK: - Audio Encoder

class AudioEncoder {
    private var converter: AudioConverterRef?
    private var destinationFormat: AudioStreamBasicDescription
    
    weak var delegate: AudioEncoderDelegate?
    
    init() {
        // Configure AAC output format
        destinationFormat = AudioStreamBasicDescription(
            mSampleRate: 44100.0,
            mFormatID: kAudioFormatMPEG4AAC,
            mFormatFlags: kMPEG4Object_AAC_LC,
            mBytesPerPacket: 0,
            mFramesPerPacket: 1024,
            mBytesPerFrame: 0,
            mChannelsPerFrame: 2,
            mBitsPerChannel: 0,
            mReserved: 0
        )
    }
    
    deinit {
        if let converter = converter {
            AudioConverterDispose(converter)
        }
    }
    
    func configure(with sampleBuffer: CMSampleBuffer) throws {
        guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) else {
            throw AudioEncoderError.invalidFormatDescription
        }
        
        let sourceFormat = CMAudioFormatDescriptionGetStreamBasicDescription(formatDesc)?.pointee
        guard let sourceFormat = sourceFormat else {
            throw AudioEncoderError.invalidSourceFormat
        }
        
        if converter != nil {
            AudioConverterDispose(converter!)
        }
        
        let status = AudioConverterNew(&sourceFormat, &destinationFormat, &converter)
        guard status == noErr else {
            throw AudioEncoderError.failedToCreateConverter(status)
        }
        
        print("Audio encoder configured: \(sourceFormat.mSampleRate)Hz -> \(destinationFormat.mSampleRate)Hz")
    }
    
    func encode(sampleBuffer: CMSampleBuffer) {
        delegate?.audioEncoder(self, didOutput: sampleBuffer)
    }
}

// MARK: - Encoder Delegates

protocol VideoEncoderDelegate: AnyObject {
    func videoEncoder(_ encoder: VideoEncoder, didOutput sampleBuffer: CMSampleBuffer, isKeyframe: Bool)
}

protocol AudioEncoderDelegate: AnyObject {
    func audioEncoder(_ encoder: AudioEncoder, didOutput sampleBuffer: CMSampleBuffer)
}

// MARK: - Errors

enum VideoEncoderError: Error {
    case failedToCreateSession(OSStatus)
    case invalidSession
    case failedToPrepareSession(OSStatus)
    case failedToSetProperty(String, OSStatus)
    
    var localizedDescription: String {
        switch self {
        case .failedToCreateSession(let status):
            return "Failed to create compression session: \(status)"
        case .invalidSession:
            return "Invalid compression session"
        case .failedToPrepareSession(let status):
            return "Failed to prepare compression session: \(status)"
        case .failedToSetProperty(let property, let status):
            return "Failed to set property \(property): \(status)"
        }
    }
}

enum AudioEncoderError: Error {
    case invalidFormatDescription
    case invalidSourceFormat
    case failedToCreateConverter(OSStatus)
    
    var localizedDescription: String {
        switch self {
        case .invalidFormatDescription:
            return "Invalid audio format description"
        case .invalidSourceFormat:
            return "Invalid source audio format"
        case .failedToCreateConverter(let status):
            return "Failed to create audio converter: \(status)"
        }
    }
}