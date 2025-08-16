import SwiftUI

struct SettingsView: View {
    @Binding var configuration: StreamingConfiguration
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Streaming Protocol")) {
                    Picker("Protocol", selection: $configuration.protocol) {
                        ForEach(StreamingProtocol.allCases, id: \.self) { protocol in
                            Text(protocol.rawValue).tag(protocol)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if configuration.protocol == .rtmp {
                    Section(header: Text("RTMP Settings")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Server URL")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("rtmp://server.com/live", text: $configuration.rtmpURL)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Stream Key")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            SecureField("Stream Key", text: $configuration.streamKey)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                }
                
                if configuration.protocol == .whip {
                    Section(header: Text("WHIP Settings")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("WHIP Endpoint")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("https://whip.server.com/endpoint", text: $configuration.whipEndpoint)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                    }
                }
                
                Section(header: Text("Video Quality")) {
                    Picker("Resolution", selection: $configuration.videoResolution) {
                        ForEach(VideoResolution.allCases, id: \.self) { resolution in
                            Text(resolution.rawValue).tag(resolution)
                        }
                    }
                    
                    Picker("Bitrate", selection: $configuration.bitrate) {
                        ForEach(BitratePreset.allCases, id: \.self) { bitrate in
                            Text(bitrate.description).tag(bitrate)
                        }
                    }
                    
                    Stepper("Frame Rate: \(configuration.frameRate) fps", 
                           value: $configuration.frameRate, 
                           in: 15...60, 
                           step: 5)
                }
                
                Section(header: Text("Information")) {
                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(title: "Protocol", value: configuration.protocol.rawValue)
                        InfoRow(title: "Resolution", value: configuration.videoResolution.rawValue)
                        InfoRow(title: "Bitrate", value: "\(configuration.bitrate.rawValue) kbps")
                        InfoRow(title: "Frame Rate", value: "\(configuration.frameRate) fps")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        configuration.saveSettings()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(configuration: .constant(StreamingConfiguration()))
    }
}