import SwiftUI

struct StreamingControlView: View {
    @ObservedObject var streamingManager: StreamingManager
    
    var body: some View {
        VStack(spacing: 20) {
            // Status info
            VStack(spacing: 8) {
                if !streamingManager.connectionInfo.isEmpty {
                    Text(streamingManager.connectionInfo)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(statusBackgroundColor)
                        .cornerRadius(8)
                }
                
                if !streamingManager.bitrateInfo.isEmpty {
                    Text(streamingManager.bitrateInfo)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                }
            }
            
            // Control buttons
            HStack(spacing: 30) {
                // Camera switch button
                Button(action: {
                    streamingManager.switchCamera()
                }) {
                    Image(systemName: "camera.rotate")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .disabled(streamingManager.streamingState == .connecting || streamingManager.streamingState == .disconnecting)
                
                // Main streaming button
                Button(action: {
                    if case .streaming = streamingManager.streamingState {
                        streamingManager.stopStreaming()
                    } else if case .idle = streamingManager.streamingState {
                        streamingManager.startStreaming()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(streamingButtonColor)
                            .frame(width: 80, height: 80)
                        
                        if case .connecting = streamingManager.streamingState {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else if case .disconnecting = streamingManager.streamingState {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: streamingButtonIcon)
                                .font(.title)
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(streamingManager.streamingState == .connecting || 
                         streamingManager.streamingState == .disconnecting ||
                         !streamingManager.configuration.isConfigurationValid)
                
                // Settings indicator (placeholder for now)
                Button(action: {
                    // This could show a quick settings overlay
                }) {
                    VStack {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(.white)
                        
                        Text(streamingManager.configuration.streamingProtocol.rawValue)
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(8)
                }
                .disabled(streamingManager.streamingState != .idle)
            }
        }
    }
    
    private var statusBackgroundColor: Color {
        switch streamingManager.streamingState {
        case .idle:
            return Color.gray.opacity(0.8)
        case .connecting, .disconnecting:
            return Color.orange.opacity(0.8)
        case .streaming:
            return Color.green.opacity(0.8)
        case .error:
            return Color.red.opacity(0.8)
        }
    }
    
    private var streamingButtonColor: Color {
        switch streamingManager.streamingState {
        case .idle:
            return streamingManager.configuration.isConfigurationValid ? Color.red : Color.gray
        case .connecting, .disconnecting:
            return Color.orange
        case .streaming:
            return Color.red
        case .error:
            return Color.gray
        }
    }
    
    private var streamingButtonIcon: String {
        switch streamingManager.streamingState {
        case .idle:
            return streamingManager.configuration.isConfigurationValid ? "play.fill" : "exclamationmark.triangle.fill"
        case .connecting:
            return "play.fill"
        case .streaming:
            return "stop.fill"
        case .disconnecting:
            return "stop.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }
}

struct StreamingControlView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingControlView(streamingManager: StreamingManager())
            .background(Color.black)
    }
}