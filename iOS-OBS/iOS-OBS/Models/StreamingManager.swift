import Foundation
import AVFoundation
import os

enum StreamingState {
    case idle
    case connecting
    case streaming
    case disconnecting
    case error(String)
}

class StreamingManager: ObservableObject {
    @Published var streamingState: StreamingState = .idle
    @Published var configuration = StreamingConfiguration()
    @Published var connectionInfo: String = ""
    @Published var bitrateInfo: String = ""
    
    let cameraManager = CameraManager()
    private var videoEncoder: VideoEncoder?
    private var rtmpStreamer: RTMPStreamer?
    private var whipStreamer: WHIPStreamer?
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "iOS-OBS", category: "StreamingManager")
    
    init() {
        cameraManager.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
            logger.info("Audio session configured")
        } catch {
            logger.error("Failed to configure audio session: \(error.localizedDescription)")
        }
    }
    
    func startStreaming() {
        guard configuration.isConfigurationValid else {
            streamingState = .error("Invalid configuration")
            return
        }
        
        streamingState = .connecting
        connectionInfo = "Connecting..."
        
        // Configure camera settings
        cameraManager.configureVideoSettings(
            resolution: configuration.videoResolution,
            frameRate: configuration.frameRate
        )
        
        // Initialize video encoder
        videoEncoder = VideoEncoder(
            resolution: configuration.videoResolution,
            bitrate: configuration.videoBitrate,
            frameRate: configuration.frameRate
        )
        
        // Start camera session
        cameraManager.startSession()
        
        // Initialize appropriate streamer
        switch configuration.streamingProtocol {
        case .rtmp:
            startRTMPStreaming()
        case .whip:
            startWHIPStreaming()
        }
    }
    
    func stopStreaming() {
        streamingState = .disconnecting
        connectionInfo = "Disconnecting..."
        
        // Stop streaming
        rtmpStreamer?.disconnect()
        whipStreamer?.disconnect()
        
        // Stop camera
        cameraManager.stopSession()
        
        // Clean up
        videoEncoder = nil
        rtmpStreamer = nil
        whipStreamer = nil
        
        streamingState = .idle
        connectionInfo = ""
        bitrateInfo = ""
        
        logger.info("Streaming stopped")
    }
    
    private func startRTMPStreaming() {
        rtmpStreamer = RTMPStreamer(
            url: configuration.rtmpUrl,
            streamKey: configuration.rtmpStreamKey
        )
        
        rtmpStreamer?.delegate = self
        rtmpStreamer?.connect()
    }
    
    private func startWHIPStreaming() {
        whipStreamer = WHIPStreamer(
            endpointUrl: configuration.whipEndpointUrl
        )
        
        whipStreamer?.delegate = self
        whipStreamer?.connect()
    }
    
    func switchCamera() {
        cameraManager.switchCamera()
    }
    
    func updateConfiguration() {
        configuration.saveConfiguration()
    }
}

// MARK: - CameraManagerDelegate

extension StreamingManager: CameraManagerDelegate {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer, from mediaType: MediaType) {
        switch mediaType {
        case .video:
            videoEncoder?.encode(sampleBuffer: sampleBuffer) { [weak self] encodedData in
                self?.sendVideoData(encodedData)
            }
        case .audio:
            // For now, pass audio directly to streamers
            // In a full implementation, you'd also encode audio
            sendAudioData(sampleBuffer)
        }
    }
    
    private func sendVideoData(_ data: Data) {
        switch configuration.streamingProtocol {
        case .rtmp:
            rtmpStreamer?.sendVideoData(data)
        case .whip:
            whipStreamer?.sendVideoData(data)
        }
    }
    
    private func sendAudioData(_ sampleBuffer: CMSampleBuffer) {
        switch configuration.streamingProtocol {
        case .rtmp:
            rtmpStreamer?.sendAudioData(sampleBuffer)
        case .whip:
            whipStreamer?.sendAudioData(sampleBuffer)
        }
    }
}

// MARK: - StreamerDelegate

extension StreamingManager: StreamerDelegate {
    func streamerDidConnect(_ streamer: Any) {
        DispatchQueue.main.async {
            self.streamingState = .streaming
            self.connectionInfo = "Connected"
            self.logger.info("Streamer connected")
        }
    }
    
    func streamerDidDisconnect(_ streamer: Any) {
        DispatchQueue.main.async {
            self.streamingState = .idle
            self.connectionInfo = ""
            self.bitrateInfo = ""
            self.logger.info("Streamer disconnected")
        }
    }
    
    func streamer(_ streamer: Any, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.streamingState = .error(error.localizedDescription)
            self.connectionInfo = "Error: \(error.localizedDescription)"
            self.logger.error("Streamer error: \(error.localizedDescription)")
        }
    }
    
    func streamer(_ streamer: Any, didUpdateBitrate bitrate: Double) {
        DispatchQueue.main.async {
            self.bitrateInfo = String(format: "%.1f Mbps", bitrate / 1_000_000)
        }
    }
}

// MARK: - StreamerDelegate Protocol

protocol StreamerDelegate: AnyObject {
    func streamerDidConnect(_ streamer: Any)
    func streamerDidDisconnect(_ streamer: Any)
    func streamer(_ streamer: Any, didFailWithError error: Error)
    func streamer(_ streamer: Any, didUpdateBitrate bitrate: Double)
}