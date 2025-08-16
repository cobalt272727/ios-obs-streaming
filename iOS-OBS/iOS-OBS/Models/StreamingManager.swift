import Foundation
import AVFoundation
import os.log

enum StreamingState {
    case idle
    case preparing
    case streaming
    case error(String)
}

class StreamingManager: ObservableObject, CameraManagerDelegate {
    @Published var configuration = StreamingConfiguration()
    @Published var streamingState: StreamingState = .idle
    @Published var connectionStatus: String = "Disconnected"
    
    let cameraManager = CameraManager()
    private var videoEncoder: VideoEncoder?
    private var rtmpStreamer: RTMPStreamer?
    private var whipStreamer: WHIPStreamer?
    
    private let logger = Logger(subsystem: "com.example.iOS-OBS", category: "StreamingManager")
    
    init() {
        cameraManager.delegate = self
        
        // Observe configuration changes
        configuration.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
        .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    func setupCamera() {
        cameraManager.startSession()
    }
    
    func startStreaming() {
        guard streamingState == .idle else {
            logger.warning("Cannot start streaming: current state is \(String(describing: streamingState))")
            return
        }
        
        logger.info("Starting streaming with protocol: \(configuration.protocol.rawValue)")
        streamingState = .preparing
        connectionStatus = "Connecting..."
        
        setupEncoder()
        setupStreamer()
    }
    
    func stopStreaming() {
        logger.info("Stopping streaming")
        
        videoEncoder?.stopEncoding()
        rtmpStreamer?.disconnect()
        whipStreamer?.disconnect()
        
        streamingState = .idle
        connectionStatus = "Disconnected"
    }
    
    func switchCamera() {
        cameraManager.switchCamera()
    }
    
    private func setupEncoder() {
        videoEncoder = VideoEncoder(
            resolution: configuration.videoResolution.size,
            bitrate: configuration.bitrate.rawValue,
            frameRate: configuration.frameRate
        )
        
        videoEncoder?.delegate = self
    }
    
    private func setupStreamer() {
        switch configuration.protocol {
        case .rtmp:
            setupRTMPStreamer()
        case .whip:
            setupWHIPStreamer()
        }
    }
    
    private func setupRTMPStreamer() {
        guard !configuration.rtmpURL.isEmpty && !configuration.streamKey.isEmpty else {
            streamingState = .error("RTMP URL and Stream Key are required")
            return
        }
        
        rtmpStreamer = RTMPStreamer(
            url: configuration.rtmpURL,
            streamKey: configuration.streamKey
        )
        
        rtmpStreamer?.delegate = self
        rtmpStreamer?.connect()
    }
    
    private func setupWHIPStreamer() {
        guard !configuration.whipEndpoint.isEmpty else {
            streamingState = .error("WHIP endpoint URL is required")
            return
        }
        
        whipStreamer = WHIPStreamer(endpoint: configuration.whipEndpoint)
        whipStreamer?.delegate = self
        whipStreamer?.connect()
    }
    
    // MARK: - CameraManagerDelegate
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer) {
        videoEncoder?.encode(sampleBuffer: sampleBuffer)
    }
    
    func cameraManager(_ manager: CameraManager, didEncounterError error: Error) {
        logger.error("Camera error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.streamingState = .error("Camera error: \(error.localizedDescription)")
        }
    }
}

// MARK: - VideoEncoderDelegate
extension StreamingManager: VideoEncoderDelegate {
    func videoEncoder(_ encoder: VideoEncoder, didEncodeFrame data: Data, timestamp: CMTime) {
        // Send encoded data to active streamer
        if streamingState == .streaming {
            rtmpStreamer?.sendVideoData(data, timestamp: timestamp)
            whipStreamer?.sendVideoData(data, timestamp: timestamp)
        }
    }
    
    func videoEncoder(_ encoder: VideoEncoder, didEncounterError error: Error) {
        logger.error("Video encoder error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.streamingState = .error("Encoder error: \(error.localizedDescription)")
        }
    }
}

// MARK: - RTMPStreamerDelegate
extension StreamingManager: RTMPStreamerDelegate {
    func rtmpStreamerDidConnect(_ streamer: RTMPStreamer) {
        logger.info("RTMP connected")
        DispatchQueue.main.async {
            self.streamingState = .streaming
            self.connectionStatus = "Connected (RTMP)"
        }
    }
    
    func rtmpStreamerDidDisconnect(_ streamer: RTMPStreamer) {
        logger.info("RTMP disconnected")
        DispatchQueue.main.async {
            self.streamingState = .idle
            self.connectionStatus = "Disconnected"
        }
    }
    
    func rtmpStreamer(_ streamer: RTMPStreamer, didEncounterError error: Error) {
        logger.error("RTMP error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.streamingState = .error("RTMP error: \(error.localizedDescription)")
            self.connectionStatus = "Error"
        }
    }
}

// MARK: - WHIPStreamerDelegate
extension StreamingManager: WHIPStreamerDelegate {
    func whipStreamerDidConnect(_ streamer: WHIPStreamer) {
        logger.info("WHIP connected")
        DispatchQueue.main.async {
            self.streamingState = .streaming
            self.connectionStatus = "Connected (WHIP)"
        }
    }
    
    func whipStreamerDidDisconnect(_ streamer: WHIPStreamer) {
        logger.info("WHIP disconnected")
        DispatchQueue.main.async {
            self.streamingState = .idle
            self.connectionStatus = "Disconnected"
        }
    }
    
    func whipStreamer(_ streamer: WHIPStreamer, didEncounterError error: Error) {
        logger.error("WHIP error: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.streamingState = .error("WHIP error: \(error.localizedDescription)")
            self.connectionStatus = "Error"
        }
    }
}

// Import Combine for publishers
import Combine