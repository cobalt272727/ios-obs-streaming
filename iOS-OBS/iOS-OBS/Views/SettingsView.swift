import SwiftUI

struct SettingsView: View {
    @ObservedObject var streamingManager: StreamingManager
    @State private var configuration: StreamingConfiguration
    @Environment(\.dismiss) private var dismiss
    
    init(streamingManager: StreamingManager) {
        self.streamingManager = streamingManager
        self._configuration = State(initialValue: streamingManager.configuration)
    }
    
    var body: some View {
        NavigationView {
            Form {
                protocolSection
                
                if configuration.streamingProtocol == .rtmp {
                    rtmpSection
                } else {
                    whipSection
                }
                
                videoSection
                audioSection
                connectionSection
            }
            .navigationTitle("Streaming Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveConfiguration()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var protocolSection: some View {
        Section("Streaming Protocol") {
            Picker("Protocol", selection: $configuration.streamingProtocol) {
                ForEach(StreamingProtocol.allCases, id: \.self) { streamingProtocol in
                    Text(streamingProtocol.displayName).tag(streamingProtocol)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    private var rtmpSection: some View {
        Section("RTMP Configuration") {
            VStack(alignment: .leading, spacing: 8) {
                Text("RTMP URL")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("rtmp://live.example.com/live", text: $configuration.rtmpURL)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Stream Key")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                SecureField("Your stream key", text: $configuration.streamKey)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Text("Enter your RTMP server URL and stream key. These are typically provided by your streaming service (e.g., YouTube, Twitch).")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var whipSection: some View {
        Section("WHIP Configuration") {
            VStack(alignment: .leading, spacing: 8) {
                Text("WHIP Endpoint")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("https://ingest.example.com/whip", text: $configuration.whipEndpoint)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .keyboardType(.URL)
            }
            
            Text("Enter your WHIP endpoint URL. This is provided by your WebRTC-compatible streaming service.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var videoSection: some View {
        Section("Video Settings") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Resolution")
                            .font(.headline)
                        Spacer()
                        Text(configuration.videoResolution.displayName)
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Resolution", selection: $configuration.videoResolution) {
                        ForEach(VideoResolution.allCases, id: \.self) { resolution in
                            Text(resolution.displayName).tag(resolution)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Video Bitrate")
                            .font(.headline)
                        Spacer()
                        Text("\(configuration.videoBitrate) kbps")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(configuration.videoBitrate) },
                            set: { configuration.videoBitrate = Int($0) }
                        ),
                        in: 500...8000,
                        step: 250
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Frame Rate")
                            .font(.headline)
                        Spacer()
                        Text("\(configuration.frameRate) fps")
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Frame Rate", selection: $configuration.frameRate) {
                        Text("24 fps").tag(24)
                        Text("30 fps").tag(30)
                        Text("60 fps").tag(60)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
    
    private var audioSection: some View {
        Section("Audio Settings") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Audio Bitrate")
                            .font(.headline)
                        Spacer()
                        Text("\(configuration.audioBitrate) kbps")
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Audio Bitrate", selection: $configuration.audioBitrate) {
                        Text("64 kbps").tag(64)
                        Text("128 kbps").tag(128)
                        Text("192 kbps").tag(192)
                        Text("256 kbps").tag(256)
                    }
                    .pickerStyle(.segmented)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sample Rate")
                            .font(.headline)
                        Spacer()
                        Text("\(configuration.audioSampleRate) Hz")
                            .foregroundColor(.secondary)
                    }
                    
                    Picker("Sample Rate", selection: $configuration.audioSampleRate) {
                        Text("44.1 kHz").tag(44100)
                        Text("48 kHz").tag(48000)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }
    
    private var connectionSection: some View {
        Section("Connection Settings") {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Connection Timeout")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(configuration.connectionTimeout))s")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $configuration.connectionTimeout,
                        in: 10...60,
                        step: 5
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Retry Attempts")
                            .font(.headline)
                        Spacer()
                        Text("\(configuration.retryAttempts)")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(configuration.retryAttempts) },
                            set: { configuration.retryAttempts = Int($0) }
                        ),
                        in: 1...10,
                        step: 1
                    )
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func saveConfiguration() {
        streamingManager.updateConfiguration(configuration)
        dismiss()
    }
}

struct SettingsPreview: View {
    @StateObject private var streamingManager = StreamingManager()
    
    var body: some View {
        SettingsView(streamingManager: streamingManager)
    }
}

#Preview {
    SettingsPreview()
}