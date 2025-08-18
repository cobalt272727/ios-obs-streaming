import Foundation

enum StreamingProtocol: String, CaseIterable {
    case rtmp = "RTMP"
    case whip = "WHIP"
}

enum VideoResolution: String, CaseIterable {
    case hd720 = "720p"
    case hd1080 = "1080p"
    
    var dimensions: (width: Int, height: Int) {
        switch self {
        case .hd720:
            return (1280, 720)
        case .hd1080:
            return (1920, 1080)
        }
    }
}

enum VideoBitrate: Int, CaseIterable {
    case low = 1000000    // 1 Mbps
    case medium = 2500000 // 2.5 Mbps
    case high = 5000000   // 5 Mbps
    case veryHigh = 8000000 // 8 Mbps
    
    var displayName: String {
        switch self {
        case .low:
            return "1 Mbps"
        case .medium:
            return "2.5 Mbps"
        case .high:
            return "5 Mbps"
        case .veryHigh:
            return "8 Mbps"
        }
    }
}

enum FrameRate: Int, CaseIterable {
    case fps24 = 24
    case fps30 = 30
    case fps60 = 60
    
    var displayName: String {
        return "\(rawValue) FPS"
    }
}

class StreamingConfiguration: ObservableObject {
    @Published var streamingProtocol: StreamingProtocol = .rtmp
    @Published var rtmpUrl: String = ""
    @Published var rtmpStreamKey: String = ""
    @Published var whipEndpointUrl: String = ""
    @Published var videoResolution: VideoResolution = .hd720
    @Published var videoBitrate: VideoBitrate = .medium
    @Published var frameRate: FrameRate = .fps30
    @Published var audioBitrate: Int = 128000 // 128 kbps
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadConfiguration()
    }
    
    private func loadConfiguration() {
        if let protocolString = userDefaults.object(forKey: "streamingProtocol") as? String,
           let streamingProtocol = StreamingProtocol(rawValue: protocolString) {
            self.streamingProtocol = streamingProtocol
        }
        
        rtmpUrl = userDefaults.string(forKey: "rtmpUrl") ?? ""
        rtmpStreamKey = userDefaults.string(forKey: "rtmpStreamKey") ?? ""
        whipEndpointUrl = userDefaults.string(forKey: "whipEndpointUrl") ?? ""
        
        if let resolutionString = userDefaults.object(forKey: "videoResolution") as? String,
           let resolution = VideoResolution(rawValue: resolutionString) {
            self.videoResolution = resolution
        }
        
        if let bitrateValue = userDefaults.object(forKey: "videoBitrate") as? Int,
           let bitrate = VideoBitrate(rawValue: bitrateValue) {
            self.videoBitrate = bitrate
        }
        
        if let frameRateValue = userDefaults.object(forKey: "frameRate") as? Int,
           let frameRate = FrameRate(rawValue: frameRateValue) {
            self.frameRate = frameRate
        }
        
        audioBitrate = userDefaults.integer(forKey: "audioBitrate")
        if audioBitrate == 0 {
            audioBitrate = 128000
        }
    }
    
    func saveConfiguration() {
        userDefaults.set(streamingProtocol.rawValue, forKey: "streamingProtocol")
        userDefaults.set(rtmpUrl, forKey: "rtmpUrl")
        userDefaults.set(rtmpStreamKey, forKey: "rtmpStreamKey")
        userDefaults.set(whipEndpointUrl, forKey: "whipEndpointUrl")
        userDefaults.set(videoResolution.rawValue, forKey: "videoResolution")
        userDefaults.set(videoBitrate.rawValue, forKey: "videoBitrate")
        userDefaults.set(frameRate.rawValue, forKey: "frameRate")
        userDefaults.set(audioBitrate, forKey: "audioBitrate")
    }
    
    var isConfigurationValid: Bool {
        switch streamingProtocol {
        case .rtmp:
            return !rtmpUrl.isEmpty && !rtmpStreamKey.isEmpty
        case .whip:
            return !whipEndpointUrl.isEmpty
        }
    }
}