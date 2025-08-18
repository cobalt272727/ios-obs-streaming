import SwiftUI

struct StreamingControlView: View {
    @ObservedObject var streamingManager: StreamingManager
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Status Card
            statusCard
            
            // Control Buttons
            controlButtons
            
            // Statistics
            if streamingManager.isStreaming {
                statisticsView
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showingSettings) {
            SettingsView(streamingManager: streamingManager)
        }
    }
    
    // MARK: - Status Card
    
    private var statusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 16, height: 16)
                
                Text(streamingManager.streamingState.displayText)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if let error = streamingManager.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
            
            // Configuration summary
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Protocol:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(streamingManager.configuration.streamingProtocol.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                }
                
                HStack {
                    Text("Resolution:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(streamingManager.configuration.videoResolution.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                    Spacer()
                    Text("Bitrate:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(streamingManager.configuration.videoBitrate) kbps")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        VStack(spacing: 16) {
            // Main streaming button
            Button(action: toggleStreaming) {
                HStack {
                    Image(systemName: streamingManager.isStreaming ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)
                    
                    Text(streamingManager.isStreaming ? "Stop Streaming" : "Start Streaming")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    streamingManager.isStreaming ? Color.red : Color.green
                )
                .cornerRadius(12)
            }
            .disabled(!canToggleStreaming)
            
            // Secondary buttons
            HStack(spacing: 16) {
                Button(action: { showingSettings = true }) {
                    HStack {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .disabled(streamingManager.isStreaming)
                
                Button(action: { streamingManager.switchCamera() }) {
                    HStack {
                        Image(systemName: "camera.rotate")
                        Text("Flip")
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Statistics View
    
    private var statisticsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaming Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                StatisticItem(
                    title: "Video Frames",
                    value: "\(streamingManager.videoFramesEncoded)",
                    icon: "video"
                )
                
                Spacer()
                
                StatisticItem(
                    title: "Audio Samples",
                    value: "\(streamingManager.audioSamplesEncoded)",
                    icon: "waveform"
                )
            }
            
            // Additional stats could be added here
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Video Settings:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(streamingManager.configuration.videoResolution.displayName) @ \(streamingManager.configuration.frameRate)fps")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Video Bitrate:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(streamingManager.configuration.videoBitrate) kbps")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Audio Bitrate:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(streamingManager.configuration.audioBitrate) kbps")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch streamingManager.streamingState {
        case .idle:
            return .gray
        case .connecting:
            return .yellow
        case .connected, .streaming:
            return .green
        case .disconnecting:
            return .orange
        case .error:
            return .red
        }
    }
    
    private var canToggleStreaming: Bool {
        streamingManager.streamingState.canStartStreaming || streamingManager.isStreaming
    }
    
    // MARK: - Actions
    
    private func toggleStreaming() {
        if streamingManager.isStreaming {
            streamingManager.stopStreaming()
        } else {
            streamingManager.startStreaming()
        }
    }
}

// MARK: - Statistic Item Component

struct StatisticItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
    }
}

struct StreamingControlPreview: View {
    @StateObject private var streamingManager = StreamingManager()
    
    var body: some View {
        NavigationView {
            StreamingControlView(streamingManager: streamingManager)
                .navigationTitle("Streaming Control")
        }
    }
}

#Preview {
    StreamingControlPreview()
}