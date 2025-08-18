import SwiftUI

struct SettingsView: View {
    @Binding var configuration: StreamingConfiguration
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Streaming Protocol") {
                    Picker("Protocol", selection: $configuration.streamingProtocol) {
                        ForEach(StreamingProtocol.allCases, id: \.self) { protocolType in
                            Text(protocolType.rawValue).tag(protocolType)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if configuration.streamingProtocol == .rtmp {
                    Section("RTMP Settings") {
                        VStack(alignment: .leading) {
                            Text("RTMP URL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("rtmp://live.twitch.tv/live/", text: $configuration.rtmpUrl)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Stream Key")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            SecureField("Enter your stream key", text: $configuration.rtmpStreamKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                } else {
                    Section("WHIP Settings") {
                        VStack(alignment: .leading) {
                            Text("WHIP Endpoint URL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("https://example.com/whip", text: $configuration.whipEndpointUrl)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                    }
                }
                
                Section("Video Settings") {
                    Picker("Resolution", selection: $configuration.videoResolution) {
                        ForEach(VideoResolution.allCases, id: \.self) { resolution in
                            Text(resolution.rawValue).tag(resolution)
                        }
                    }
                    
                    Picker("Bitrate", selection: $configuration.videoBitrate) {
                        ForEach(VideoBitrate.allCases, id: \.self) { bitrate in
                            Text(bitrate.displayName).tag(bitrate)
                        }
                    }
                    
                    Picker("Frame Rate", selection: $configuration.frameRate) {
                        ForEach(FrameRate.allCases, id: \.self) { frameRate in
                            Text(frameRate.displayName).tag(frameRate)
                        }
                    }
                }
                
                Section("Audio Settings") {
                    VStack(alignment: .leading) {
                        Text("Audio Bitrate: \(configuration.audioBitrate / 1000) kbps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(
                            value: Binding(
                                get: { Double(configuration.audioBitrate) },
                                set: { configuration.audioBitrate = Int($0) }
                            ),
                            in: 64000...320000,
                            step: 32000
                        )
                    }
                }
                
                Section("Configuration Status") {
                    HStack {
                        Image(systemName: configuration.isConfigurationValid ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundColor(configuration.isConfigurationValid ? .green : .red)
                        
                        Text(configuration.isConfigurationValid ? "Configuration is valid" : "Configuration is incomplete")
                            .foregroundColor(configuration.isConfigurationValid ? .green : .red)
                    }
                    
                    if !configuration.isConfigurationValid {
                        Text(configurationValidationMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Stream Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        configuration.saveConfiguration()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private var configurationValidationMessage: String {
        switch configuration.streamingProtocol {
        case .rtmp:
            if configuration.rtmpUrl.isEmpty && configuration.rtmpStreamKey.isEmpty {
                return "Please enter both RTMP URL and Stream Key"
            } else if configuration.rtmpUrl.isEmpty {
                return "Please enter RTMP URL"
            } else if configuration.rtmpStreamKey.isEmpty {
                return "Please enter Stream Key"
            }
        case .whip:
            if configuration.whipEndpointUrl.isEmpty {
                return "Please enter WHIP endpoint URL"
            }
        }
        return ""
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(configuration: .constant(StreamingConfiguration()))
    }
}