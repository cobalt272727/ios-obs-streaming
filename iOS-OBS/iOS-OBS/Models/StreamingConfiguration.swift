import Foundation
import CoreGraphics

enum StreamingProtocol: String, CaseIterable {
    case rtmp = "RTMP"
    case whip = "WHIP"
}

enum VideoResolution: String, CaseIterable {
    case hd720 = "1280x720"
    case hd1080 = "1920x1080"
    
    var size: CGSize {
        switch self {
        case .hd720:
            return CGSize(width: 1280, height: 720)
        case .hd1080:
            return CGSize(width: 1920, height: 1080)
        }
    }
}

enum BitratePreset: Int, CaseIterable {
    case low = 1000
    case medium = 2500
    case high = 5000
    case ultra = 8000
    
    var description: String {
        switch self {
        case .low:
            return "Low (1 Mbps)"
        case .medium:
            return "Medium (2.5 Mbps)"
        case .high:
            return "High (5 Mbps)"
        case .ultra:
            return "Ultra (8 Mbps)"
        }
    }
}

class StreamingConfiguration: ObservableObject {
    @Published var protocol: StreamingProtocol = .rtmp
    @Published var rtmpURL: String = ""
    @Published var streamKey: String = ""
    @Published var whipEndpoint: String = ""
    @Published var videoResolution: VideoResolution = .hd720
    @Published var bitrate: BitratePreset = .medium
    @Published var frameRate: Int = 30
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadSettings()
    }
    
    func saveSettings() {
        userDefaults.set(protocol.rawValue, forKey: "streaming_protocol")
        userDefaults.set(rtmpURL, forKey: "rtmp_url")
        userDefaults.set(streamKey, forKey: "stream_key")
        userDefaults.set(whipEndpoint, forKey: "whip_endpoint")
        userDefaults.set(videoResolution.rawValue, forKey: "video_resolution")
        userDefaults.set(bitrate.rawValue, forKey: "bitrate")
        userDefaults.set(frameRate, forKey: "frame_rate")
    }
    
    private func loadSettings() {
        if let protocolString = userDefaults.string(forKey: "streaming_protocol"),
           let loadedProtocol = StreamingProtocol(rawValue: protocolString) {
            protocol = loadedProtocol
        }
        
        rtmpURL = userDefaults.string(forKey: "rtmp_url") ?? ""
        streamKey = userDefaults.string(forKey: "stream_key") ?? ""
        whipEndpoint = userDefaults.string(forKey: "whip_endpoint") ?? ""
        
        if let resolutionString = userDefaults.string(forKey: "video_resolution"),
           let loadedResolution = VideoResolution(rawValue: resolutionString) {
            videoResolution = loadedResolution
        }
        
        let bitrateValue = userDefaults.integer(forKey: "bitrate")
        if bitrateValue > 0, let loadedBitrate = BitratePreset(rawValue: bitrateValue) {
            bitrate = loadedBitrate
        }
        
        let frameRateValue = userDefaults.integer(forKey: "frame_rate")
        if frameRateValue > 0 {
            frameRate = frameRateValue
        }
    }
}