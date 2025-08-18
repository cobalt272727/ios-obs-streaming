import Foundation
import AVFoundation
import Combine

class StreamingManager: ObservableObject {
    @Published var streamingState: StreamingState = .idle
    @Published var configuration = StreamingConfiguration()
    @Published var isStreaming = false
    @Published var error: String?
    
    // Core components
    private let cameraManager = CameraManager()
    private let videoEncoder = VideoEncoder()
    private let audioEncoder = AudioEncoder()
    
    // Streaming protocols
    private var rtmpStreamer: RTMPStreamer
    private var whipStreamer: WHIPStreamer
    
    // Current active streamer
    private var activeStreamer: (any StreamingProtocolProvider)?
    
    // State management
    private var cancellables = Set<AnyCancellable>()
    private var encodingQueue = DispatchQueue(label: "streaming.encoding.queue")
    
    // Statistics
    @Published var videoFramesEncoded: Int = 0
    @Published var audioSamplesEncoded: Int = 0
    
    init() {
        rtmpStreamer = RTMPStreamer(configuration: configuration)
        whipStreamer = WHIPStreamer(configuration: configuration)
        
        setupBindings()
        setupCameraManager()
        setupEncoders()
    }
    
    // MARK: - Public Methods
    
    func updateConfiguration(_ config: StreamingConfiguration) {
        configuration = config
        rtmpStreamer.updateConfiguration(config)
        whipStreamer.updateConfiguration(config)
        
        // Update camera settings
        cameraManager.configure(
            resolution: config.videoResolution,
            frameRate: config.frameRate
        )
        
        // Reconfigure encoder if needed
        if streamingState == .idle {
            configureEncoder()
        }
    }
    
    func startStreaming() {
        guard streamingState.canStartStreaming else {
            error = "Cannot start streaming in current state"
            return
        }
        
        guard !configuration.rtmpURL.isEmpty || !configuration.whipEndpoint.isEmpty else {
            error = "No streaming endpoint configured"
            return
        }
        
        // Configure encoder with current settings
        guard configureEncoder() else {
            error = "Failed to configure video encoder"
            return
        }
        
        // Select and configure active streamer
        switch configuration.streamingProtocol {
        case .rtmp:
            activeStreamer = rtmpStreamer
        case .whip:
            activeStreamer = whipStreamer
        }
        
        // Start camera session
        cameraManager.startSession()
        
        // Connect to streaming service
        activeStreamer?.connect()
        
        streamingState = .connecting
        error = nil
    }
    
    func stopStreaming() {
        // Stop camera
        cameraManager.stopSession()
        
        // Disconnect streaming
        activeStreamer?.disconnect()
        activeStreamer = nil
        
        // Reset state
        streamingState = .idle
        isStreaming = false
        videoFramesEncoded = 0
        audioSamplesEncoded = 0
    }
    
    func switchCamera() {
        cameraManager.switchCamera()
    }
    
    func createPreviewLayer() -> AVCaptureVideoPreviewLayer {
        return cameraManager.createPreviewLayer()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Bind camera manager state
        cameraManager.$isRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRunning in
                // Update UI based on camera state
            }
            .store(in: &cancellables)
        
        cameraManager.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if let error = error {
                    self?.error = error.localizedDescription
                }
            }
            .store(in: &cancellables)
        
        // Bind RTMP streamer state
        rtmpStreamer.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if self?.activeStreamer === self?.rtmpStreamer {
                    self?.streamingState = state
                    self?.isStreaming = state.isStreaming
                }
            }
            .store(in: &cancellables)
        
        // Bind WHIP streamer state
        whipStreamer.$connectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if self?.activeStreamer === self?.whipStreamer {
                    self?.streamingState = state
                    self?.isStreaming = state.isStreaming
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupCameraManager() {
        cameraManager.delegate = self
    }
    
    private func setupEncoders() {
        videoEncoder.delegate = self
        audioEncoder.delegate = self
    }
    
    private func configureEncoder() -> Bool {
        let resolution = configuration.videoResolution.dimensions
        
        do {
            try videoEncoder.configure(
                width: resolution.width,
                height: resolution.height,
                bitrate: configuration.videoBitrate,
                frameRate: configuration.frameRate
            )
            return true
        } catch {
            self.error = "Video encoder configuration failed: \(error.localizedDescription)"
            return false
        }
    }
}

// MARK: - CameraManagerDelegate

extension StreamingManager: CameraManagerDelegate {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer, from mediaType: MediaType) {
        
        switch mediaType {
        case .video:
            encodingQueue.async { [weak self] in
                self?.videoEncoder.encode(sampleBuffer: sampleBuffer)
            }
            
        case .audio:
            encodingQueue.async { [weak self] in
                do {
                    try self?.audioEncoder.configure(with: sampleBuffer)
                } catch {
                    print("Audio encoder configuration error: \(error)")
                }
                self?.audioEncoder.encode(sampleBuffer: sampleBuffer)
            }
        }
    }
}

// MARK: - VideoEncoderDelegate

extension StreamingManager: VideoEncoderDelegate {
    func videoEncoder(_ encoder: VideoEncoder, didOutput sampleBuffer: CMSampleBuffer, isKeyframe: Bool) {
        
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            print("Failed to get data buffer from video sample")
            return
        }
        
        var data = Data()
        var totalLength: Int = 0
        
        let status = CMBlockBufferGetDataPointer(
            blockBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &totalLength,
            dataPointerOut: nil
        )
        
        guard status == noErr else {
            print("Failed to get video data pointer")
            return
        }
        
        data = Data(count: totalLength)
        let copyStatus = data.withUnsafeMutableBytes { bytes in
            CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: totalLength, destination: bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        guard copyStatus == noErr else {
            print("Failed to copy video data")
            return
        }
        
        // Send to active streamer
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        activeStreamer?.send(videoData: data, timestamp: timestamp, isKeyframe: isKeyframe)
        
        DispatchQueue.main.async {
            self.videoFramesEncoded += 1
        }
    }
}

// MARK: - AudioEncoderDelegate

extension StreamingManager: AudioEncoderDelegate {
    func audioEncoder(_ encoder: AudioEncoder, didOutput sampleBuffer: CMSampleBuffer) {
        
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            print("Failed to get data buffer from audio sample")
            return
        }
        
        var data = Data()
        var totalLength: Int = 0
        
        let status = CMBlockBufferGetDataPointer(
            blockBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &totalLength,
            dataPointerOut: nil
        )
        
        guard status == noErr else {
            print("Failed to get audio data pointer")
            return
        }
        
        data = Data(count: totalLength)
        let copyStatus = data.withUnsafeMutableBytes { bytes in
            CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: totalLength, destination: bytes.bindMemory(to: UInt8.self).baseAddress!)
        }
        
        guard copyStatus == noErr else {
            print("Failed to copy audio data")
            return
        }
        
        // Send to active streamer
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        activeStreamer?.send(audioData: data, timestamp: timestamp)
        
        DispatchQueue.main.async {
            self.audioSamplesEncoded += 1
        }
    }
}

// MARK: - Streaming Protocol Provider

protocol StreamingProtocolProvider: AnyObject {
    func connect()
    func disconnect()
    func send(videoData: Data, timestamp: CMTime, isKeyframe: Bool)
    func send(audioData: Data, timestamp: CMTime)
}

extension RTMPStreamer: StreamingProtocolProvider {}
extension WHIPStreamer: StreamingProtocolProvider {}