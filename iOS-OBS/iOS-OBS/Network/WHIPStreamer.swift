import Foundation
import AVFoundation
import os.log

protocol WHIPStreamerDelegate: AnyObject {
    func whipStreamerDidConnect(_ streamer: WHIPStreamer)
    func whipStreamerDidDisconnect(_ streamer: WHIPStreamer)
    func whipStreamer(_ streamer: WHIPStreamer, didEncounterError error: Error)
}

class WHIPStreamer {
    weak var delegate: WHIPStreamerDelegate?
    
    private let endpoint: String
    private var session: URLSession
    private let logger = Logger(subsystem: "com.example.iOS-OBS", category: "WHIPStreamer")
    
    private var isConnected = false
    private var sessionId: String?
    private var connectionTask: URLSessionDataTask?
    
    // WebRTC-like components (simplified for basic implementation)
    private var localDescription: String?
    private var remoteDescription: String?
    
    init(endpoint: String) {
        self.endpoint = endpoint
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }
    
    func connect() {
        logger.info("Attempting to connect to WHIP endpoint: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            delegate?.whipStreamer(self, didEncounterError: WHIPError.invalidEndpoint)
            return
        }
        
        // Step 1: Create offer (simplified SDP)
        createOffer { [weak self] offer in
            guard let self = self else { return }
            self.sendOffer(offer, to: url)
        }
    }
    
    func disconnect() {
        logger.info("Disconnecting from WHIP endpoint")
        connectionTask?.cancel()
        deleteSession()
        isConnected = false
        delegate?.whipStreamerDidDisconnect(self)
    }
    
    func sendVideoData(_ data: Data, timestamp: CMTime) {
        guard isConnected else { return }
        
        // In a real WebRTC implementation, this would be sent via RTP packets
        // For now, we'll simulate the process
        logger.debug("Sending video data via WHIP: \(data.count) bytes")
        
        // Simulate RTP packet sending
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.sendRTPPacket(data, isVideo: true, timestamp: timestamp)
        }
    }
    
    func sendAudioData(_ data: Data, timestamp: CMTime) {
        guard isConnected else { return }
        
        logger.debug("Sending audio data via WHIP: \(data.count) bytes")
        
        // Simulate RTP packet sending
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.sendRTPPacket(data, isVideo: false, timestamp: timestamp)
        }
    }
    
    private func createOffer(completion: @escaping (String) -> Void) {
        // Simplified SDP offer creation
        // In a real implementation, this would use WebRTC's RTCPeerConnection
        let offer = """
        v=0
        o=- 123456789 123456789 IN IP4 0.0.0.0
        s=-
        t=0 0
        m=video 9 UDP/TLS/RTP/SAVPF 96
        c=IN IP4 0.0.0.0
        a=rtcp:9 IN IP4 0.0.0.0
        a=ice-ufrag:4ZcD
        a=ice-pwd:2/1muCWoOi3ueFDdzYSYJ2Q+
        a=fingerprint:sha-256 AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78
        a=setup:actpass
        a=mid:video
        a=sendonly
        a=rtcp-mux
        a=rtpmap:96 H264/90000
        a=fmtp:96 profile-level-id=42e01e
        m=audio 9 UDP/TLS/RTP/SAVPF 111
        c=IN IP4 0.0.0.0
        a=rtcp:9 IN IP4 0.0.0.0
        a=ice-ufrag:4ZcD
        a=ice-pwd:2/1muCWoOi3ueFDdzYSYJ2Q+
        a=fingerprint:sha-256 AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78
        a=setup:actpass
        a=mid:audio
        a=sendonly
        a=rtcp-mux
        a=rtpmap:111 opus/48000/2
        """
        
        localDescription = offer
        completion(offer)
    }
    
    private func sendOffer(_ offer: String, to url: URL) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.setValue("application/sdp", forHTTPHeaderField: "Accept")
        request.httpBody = offer.data(using: .utf8)
        
        logger.info("Sending WHIP offer")
        
        connectionTask = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                self.logger.error("WHIP offer failed: \(error.localizedDescription)")
                self.delegate?.whipStreamer(self, didEncounterError: error)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.delegate?.whipStreamer(self, didEncounterError: WHIPError.invalidResponse)
                return
            }
            
            switch httpResponse.statusCode {
            case 201:
                // Success - extract session URL from Location header
                if let location = httpResponse.value(forHTTPHeaderField: "Location") {
                    self.sessionId = location
                }
                
                if let data = data, let answer = String(data: data, encoding: .utf8) {
                    self.handleAnswer(answer)
                }
                
            case 400...499:
                self.delegate?.whipStreamer(self, didEncounterError: WHIPError.badRequest)
                
            case 500...599:
                self.delegate?.whipStreamer(self, didEncounterError: WHIPError.serverError)
                
            default:
                self.delegate?.whipStreamer(self, didEncounterError: WHIPError.unexpectedResponse)
            }
        }
        
        connectionTask?.resume()
    }
    
    private func handleAnswer(_ answer: String) {
        logger.info("Received WHIP answer")
        remoteDescription = answer
        
        // In a real implementation, this would configure the WebRTC peer connection
        // For now, we'll mark as connected
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isConnected = true
            self.delegate?.whipStreamerDidConnect(self)
        }
    }
    
    private func sendRTPPacket(_ data: Data, isVideo: Bool, timestamp: CMTime) {
        // This is a placeholder for actual RTP packet creation and sending
        // In a real WebRTC implementation, this would be handled by the peer connection
        
        logger.debug("Simulating RTP packet send - \(isVideo ? "video" : "audio"): \(data.count) bytes")
        
        // Simulate network processing
        usleep(1000) // 1ms delay
    }
    
    private func deleteSession() {
        guard let sessionId = sessionId,
              let url = URL(string: sessionId) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        logger.info("Deleting WHIP session")
        
        session.dataTask(with: request) { [weak self] _, response, error in
            if let error = error {
                self?.logger.error("Failed to delete WHIP session: \(error.localizedDescription)")
            } else {
                self?.logger.info("WHIP session deleted successfully")
            }
        }.resume()
        
        self.sessionId = nil
    }
}

enum WHIPError: Error, LocalizedError {
    case invalidEndpoint
    case invalidResponse
    case badRequest
    case serverError
    case unexpectedResponse
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "Invalid WHIP endpoint URL"
        case .invalidResponse:
            return "Invalid response from WHIP server"
        case .badRequest:
            return "Bad request to WHIP server"
        case .serverError:
            return "WHIP server error"
        case .unexpectedResponse:
            return "Unexpected response from WHIP server"
        case .connectionFailed:
            return "Failed to connect to WHIP server"
        }
    }
}