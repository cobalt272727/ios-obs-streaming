import Foundation
import Network
import AVFoundation
import os

class RTMPStreamer: NSObject {
    weak var delegate: StreamerDelegate?
    
    private let url: String
    private let streamKey: String
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "iOS-OBS", category: "RTMPStreamer")
    
    private var connection: NWConnection?
    private var isConnected = false
    private var connectionQueue = DispatchQueue(label: "rtmp.connection.queue")
    
    // RTMP state
    private var chunkSize: UInt32 = 128
    private var serverBandwidth: UInt32 = 0
    private var clientBandwidth: UInt32 = 0
    
    // Stream statistics
    private var bytesSent: Int64 = 0
    private var lastBitrateUpdate = Date()
    
    init(url: String, streamKey: String) {
        self.url = url
        self.streamKey = streamKey
        super.init()
    }
    
    func connect() {
        guard let rtmpUrl = URL(string: url),
              let host = rtmpUrl.host else {
            delegate?.streamer(self, didFailWithError: RTMPError.invalidURL)
            return
        }
        
        let port = rtmpUrl.port ?? 1935
        
        connectionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.logger.info("Connecting to RTMP server: \(host):\(port)")
            
            let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: UInt16(port)))
            let parameters = NWParameters.tcp
            
            self.connection = NWConnection(to: endpoint, using: parameters)
            
            self.connection?.stateUpdateHandler = { [weak self] state in
                self?.handleConnectionState(state)
            }
            
            self.connection?.start(queue: self.connectionQueue)
        }
    }
    
    func disconnect() {
        connectionQueue.async { [weak self] in
            self?.connection?.cancel()
            self?.isConnected = false
            self?.logger.info("RTMP connection cancelled")
        }
    }
    
    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            logger.info("RTMP connection established")
            performRTMPHandshake()
            
        case .failed(let error):
            logger.error("RTMP connection failed: \(error.localizedDescription)")
            delegate?.streamer(self, didFailWithError: error)
            
        case .cancelled:
            logger.info("RTMP connection cancelled")
            delegate?.streamerDidDisconnect(self)
            
        default:
            break
        }
    }
    
    private func performRTMPHandshake() {
        // Simplified RTMP handshake
        // In a real implementation, this would be much more complex
        
        // Send C0 + C1
        var handshakeData = Data()
        handshakeData.append(0x03) // RTMP version 3
        
        // C1: 1536 bytes of timestamp + zero + random data
        let timestamp = UInt32(Date().timeIntervalSince1970)
        handshakeData.append(withUnsafeBytes(of: timestamp.bigEndian) { Data($0) })
        handshakeData.append(Data(count: 4)) // Zero bytes
        handshakeData.append(Data((0..<1528).map { _ in UInt8.random(in: 0...255) }))
        
        connection?.send(content: handshakeData, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.logger.error("Handshake send error: \(error.localizedDescription)")
                self?.delegate?.streamer(self!, didFailWithError: error)
            } else {
                self?.receiveHandshakeResponse()
            }
        })
    }
    
    private func receiveHandshakeResponse() {
        // Receive S0 + S1 + S2 (3073 bytes)
        connection?.receive(minimumIncompleteLength: 3073, maximumLength: 3073) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Handshake receive error: \(error.localizedDescription)")
                self.delegate?.streamer(self, didFailWithError: error)
                return
            }
            
            guard let data = data, data.count == 3073 else {
                self.delegate?.streamer(self, didFailWithError: RTMPError.handshakeFailed)
                return
            }
            
            // Send C2 (echo of S1)
            let c2Data = data.subdata(in: 1..<1537)
            self.connection?.send(content: c2Data, completion: .contentProcessed { error in
                if let error = error {
                    self.logger.error("C2 send error: \(error.localizedDescription)")
                    self.delegate?.streamer(self, didFailWithError: error)
                } else {
                    self.startRTMPCommunication()
                }
            })
        }
    }
    
    private func startRTMPCommunication() {
        // Send connect command
        sendConnectCommand()
        
        // Start receiving messages
        receiveMessages()
    }
    
    private func sendConnectCommand() {
        // Simplified connect command
        // In a real implementation, this would use proper AMF encoding
        
        let connectCommand = createRTMPMessage(
            messageType: 0x14, // Command message
            data: "connect command placeholder".data(using: .utf8)!
        )
        
        connection?.send(content: connectCommand, completion: .contentProcessed { [weak self] error in
            if let error = error {
                self?.logger.error("Connect command error: \(error.localizedDescription)")
                self?.delegate?.streamer(self!, didFailWithError: error)
            }
        })
    }
    
    private func receiveMessages() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, isComplete, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("Message receive error: \(error.localizedDescription)")
                self.delegate?.streamer(self, didFailWithError: error)
                return
            }
            
            if let data = data {
                self.processReceivedData(data)
            }
            
            // Continue receiving if connection is still active
            if !isComplete {
                self.receiveMessages()
            }
        }
    }
    
    private func processReceivedData(_ data: Data) {
        // Process RTMP messages
        // For this basic implementation, we'll assume connection is successful
        // after receiving any response
        
        if !isConnected {
            isConnected = true
            logger.info("RTMP stream connected")
            delegate?.streamerDidConnect(self)
        }
    }
    
    func sendVideoData(_ data: Data) {
        guard isConnected else { return }
        
        connectionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let message = self.createRTMPMessage(messageType: 0x09, data: data) // Video message
            
            self.connection?.send(content: message, completion: .contentProcessed { error in
                if let error = error {
                    self.logger.error("Video send error: \(error.localizedDescription)")
                } else {
                    self.updateBitrate(bytes: Int64(data.count))
                }
            })
        }
    }
    
    func sendAudioData(_ sampleBuffer: CMSampleBuffer) {
        guard isConnected else { return }
        
        // Convert sample buffer to raw audio data
        // This is a simplified version - real implementation would encode to AAC
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        
        var length: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        
        let status = CMBlockBufferGetDataPointer(
            dataBuffer,
            atOffset: 0,
            lengthAtOffsetOut: nil,
            totalLengthOut: &length,
            dataPointerOut: &dataPointer
        )
        
        guard status == noErr, let pointer = dataPointer else { return }
        
        let audioData = Data(bytes: pointer, count: length)
        
        connectionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let message = self.createRTMPMessage(messageType: 0x08, data: audioData) // Audio message
            
            self.connection?.send(content: message, completion: .contentProcessed { error in
                if let error = error {
                    self.logger.error("Audio send error: \(error.localizedDescription)")
                } else {
                    self.updateBitrate(bytes: Int64(audioData.count))
                }
            })
        }
    }
    
    private func createRTMPMessage(messageType: UInt8, data: Data) -> Data {
        // Simplified RTMP message format
        var message = Data()
        
        // Basic header (1 byte)
        message.append(0x00 | (messageType & 0x3F))
        
        // Message length (3 bytes, big endian)
        let length = UInt32(data.count)
        message.append(UInt8((length >> 16) & 0xFF))
        message.append(UInt8((length >> 8) & 0xFF))
        message.append(UInt8(length & 0xFF))
        
        // Timestamp (3 bytes)
        let timestamp = UInt32(Date().timeIntervalSince1970 * 1000) & 0xFFFFFF
        message.append(UInt8((timestamp >> 16) & 0xFF))
        message.append(UInt8((timestamp >> 8) & 0xFF))
        message.append(UInt8(timestamp & 0xFF))
        
        // Message stream ID (3 bytes)
        message.append(contentsOf: [0x00, 0x00, 0x00])
        
        // Message data
        message.append(data)
        
        return message
    }
    
    private func updateBitrate(bytes: Int64) {
        bytesSent += bytes
        
        let now = Date()
        let timeDiff = now.timeIntervalSince(lastBitrateUpdate)
        
        if timeDiff >= 1.0 { // Update every second
            let bitrate = Double(bytesSent * 8) / timeDiff // bits per second
            delegate?.streamer(self, didUpdateBitrate: bitrate)
            
            bytesSent = 0
            lastBitrateUpdate = now
        }
    }
}

enum RTMPError: Error, LocalizedError {
    case invalidURL
    case handshakeFailed
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid RTMP URL"
        case .handshakeFailed:
            return "RTMP handshake failed"
        case .connectionFailed:
            return "RTMP connection failed"
        }
    }
}