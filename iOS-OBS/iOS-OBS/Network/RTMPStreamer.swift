import Foundation
import AVFoundation
import Network

class RTMPStreamer: NSObject, ObservableObject {
    @Published var connectionState: StreamingState = .idle
    
    private var configuration: StreamingConfiguration
    private var connection: NWConnection?
    private let connectionQueue = DispatchQueue(label: "rtmp.connection.queue")
    
    // Streaming data
    private var videoSPSPPS: Data?
    private var isConfigured = false
    
    init(configuration: StreamingConfiguration) {
        self.configuration = configuration
        super.init()
    }
    
    // MARK: - Public Methods
    
    func updateConfiguration(_ config: StreamingConfiguration) {
        self.configuration = config
    }
    
    func connect() {
        guard !configuration.rtmpURL.isEmpty && !configuration.streamKey.isEmpty else {
            DispatchQueue.main.async {
                self.connectionState = .error("RTMP URL and Stream Key are required")
            }
            return
        }
        
        guard let url = URL(string: configuration.rtmpURL) else {
            DispatchQueue.main.async {
                self.connectionState = .error("Invalid RTMP URL")
            }
            return
        }
        
        guard let host = url.host else {
            DispatchQueue.main.async {
                self.connectionState = .error("Invalid RTMP host")
            }
            return
        }
        
        let port = url.port ?? 1935 // Default RTMP port
        
        DispatchQueue.main.async {
            self.connectionState = .connecting
        }
        
        connectionQueue.async { [weak self] in
            self?.establishConnection(host: host, port: port)
        }
    }
    
    func disconnect() {
        connectionQueue.async { [weak self] in
            self?.connection?.cancel()
            self?.connection = nil
            
            DispatchQueue.main.async {
                self?.connectionState = .idle
            }
        }
    }
    
    func send(videoData: Data, timestamp: CMTime, isKeyframe: Bool) {
        guard connectionState == .streaming else { return }
        
        connectionQueue.async { [weak self] in
            self?.sendVideoData(data: videoData, timestamp: timestamp, isKeyframe: isKeyframe)
        }
    }
    
    func send(audioData: Data, timestamp: CMTime) {
        guard connectionState == .streaming else { return }
        
        connectionQueue.async { [weak self] in
            self?.sendAudioData(data: audioData, timestamp: timestamp)
        }
    }
    
    func configureWithSPS(_ spsData: Data, pps ppsData: Data) {
        videoSPSPPS = spsData + ppsData
        isConfigured = true
        print("RTMP: Video configuration set")
    }
    
    // MARK: - Private Methods
    
    private func establishConnection(host: String, port: Int) {
        let nwEndpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: UInt16(port)))
        let parameters = NWParameters.tcp
        
        connection = NWConnection(to: nwEndpoint, using: parameters)
        
        connection?.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                self?.handleConnectionState(state)
            }
        }
        
        connection?.start(queue: connectionQueue)
    }
    
    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .setup:
            connectionState = .connecting
            
        case .waiting(let error):
            connectionState = .error("Connection waiting: \(error.localizedDescription)")
            
        case .preparing:
            connectionState = .connecting
            
        case .ready:
            connectionState = .connected
            performRTMPHandshake()
            
        case .failed(let error):
            connectionState = .error("Connection failed: \(error.localizedDescription)")
            
        case .cancelled:
            connectionState = .idle
            
        @unknown default:
            connectionState = .error("Unknown connection state")
        }
    }
    
    private func performRTMPHandshake() {
        // Simplified RTMP handshake simulation
        // In a real implementation, you would implement the full RTMP protocol
        
        connectionQueue.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            // Simulate successful handshake
            self?.sendConnect()
        }
    }
    
    private func sendConnect() {
        // Simulate RTMP connect command
        connectionQueue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.sendCreateStream()
        }
    }
    
    private func sendCreateStream() {
        // Simulate RTMP createStream command
        connectionQueue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.sendPublish()
        }
    }
    
    private func sendPublish() {
        // Simulate RTMP publish command
        connectionQueue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            DispatchQueue.main.async {
                self?.connectionState = .streaming
            }
            print("RTMP: Ready to stream to \(self?.configuration.rtmpURL ?? "")")
        }
    }
    
    private func sendVideoData(data: Data, timestamp: CMTime, isKeyframe: Bool) {
        guard let connection = connection else { return }
        
        // Create RTMP video message
        let rtmpMessage = createRTMPVideoMessage(data: data, timestamp: timestamp, isKeyframe: isKeyframe)
        
        connection.send(content: rtmpMessage, completion: .contentProcessed { error in
            if let error = error {
                print("RTMP: Failed to send video data: \(error)")
            }
        })
    }
    
    private func sendAudioData(data: Data, timestamp: CMTime) {
        guard let connection = connection else { return }
        
        // Create RTMP audio message
        let rtmpMessage = createRTMPAudioMessage(data: data, timestamp: timestamp)
        
        connection.send(content: rtmpMessage, completion: .contentProcessed { error in
            if let error = error {
                print("RTMP: Failed to send audio data: \(error)")
            }
        })
    }
    
    private func createRTMPVideoMessage(data: Data, timestamp: CMTime, isKeyframe: Bool) -> Data {
        // Simplified RTMP video message creation
        // In a real implementation, you would create proper RTMP FLV video tags
        
        var message = Data()
        
        // RTMP message header (simplified)
        let messageType: UInt8 = 0x09 // Video message
        let messageLength = UInt32(data.count + 5)
        let timestampMs = UInt32(CMTimeGetSeconds(timestamp) * 1000)
        
        // Message header
        message.append(messageType)
        message.append(contentsOf: withUnsafeBytes(of: messageLength.bigEndian) { Array($0) })
        message.append(contentsOf: withUnsafeBytes(of: timestampMs.bigEndian) { Array($0) })
        
        // Video data header
        let frameType: UInt8 = isKeyframe ? 0x17 : 0x27 // Key frame or Inter frame + AVC
        let avcPacketType: UInt8 = 0x01 // AVC NALU
        
        message.append(frameType)
        message.append(avcPacketType)
        message.append(contentsOf: [0x00, 0x00, 0x00]) // Composition time offset
        
        // Append video data
        message.append(data)
        
        return message
    }
    
    private func createRTMPAudioMessage(data: Data, timestamp: CMTime) -> Data {
        // Simplified RTMP audio message creation
        // In a real implementation, you would create proper RTMP FLV audio tags
        
        var message = Data()
        
        // RTMP message header (simplified)
        let messageType: UInt8 = 0x08 // Audio message
        let messageLength = UInt32(data.count + 2)
        let timestampMs = UInt32(CMTimeGetSeconds(timestamp) * 1000)
        
        // Message header
        message.append(messageType)
        message.append(contentsOf: withUnsafeBytes(of: messageLength.bigEndian) { Array($0) })
        message.append(contentsOf: withUnsafeBytes(of: timestampMs.bigEndian) { Array($0) })
        
        // Audio data header
        let soundFormat: UInt8 = 0xAF // AAC
        let aacPacketType: UInt8 = 0x01 // AAC raw
        
        message.append(soundFormat)
        message.append(aacPacketType)
        
        // Append audio data
        message.append(data)
        
        return message
    }
}