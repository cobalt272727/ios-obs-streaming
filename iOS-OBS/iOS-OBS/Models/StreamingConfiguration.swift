import Foundation

// MARK: - Streaming Configuration
struct StreamingConfiguration {
    // RTMP Configuration
    var rtmpURL: String = ""
    var streamKey: String = ""
    
    // WHIP Configuration
    var whipEndpoint: String = ""
    
    // Video Settings
    var videoResolution: VideoResolution = .hd720p
    var videoBitrate: Int = 2500 // kbps
    var frameRate: Int = 30
    
    // Audio Settings
    var audioBitrate: Int = 128 // kbps
    var audioSampleRate: Int = 44100
    
    // Streaming Protocol
    var streamingProtocol: StreamingProtocol = .rtmp
    
    // Connection Settings
    var connectionTimeout: TimeInterval = 30.0
    var retryAttempts: Int = 3
}

// MARK: - Enums
enum StreamingProtocol: String, CaseIterable {
    case rtmp = "RTMP"
    case whip = "WHIP"
    
    var displayName: String {
        return self.rawValue
    }
}

enum VideoResolution: String, CaseIterable {
    case hd720p = "720p"
    case hd1080p = "1080p"
    
    var displayName: String {
        return self.rawValue
    }
    
    var dimensions: (width: Int, height: Int) {
        switch self {
        case .hd720p:
            return (1280, 720)
        case .hd1080p:
            return (1920, 1080)
        }
    }
}

enum StreamingState {
    case idle
    case connecting
    case connected
    case streaming
    case disconnecting
    case error(String)
    
    var displayText: String {
        switch self {
        case .idle:
            return "Ready"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .streaming:
            return "Streaming"
        case .disconnecting:
            return "Disconnecting..."
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var isStreaming: Bool {
        if case .streaming = self {
            return true
        }
        return false
    }
    
    var canStartStreaming: Bool {
        switch self {
        case .idle, .error:
            return true
        default:
            return false
        }
    }
}