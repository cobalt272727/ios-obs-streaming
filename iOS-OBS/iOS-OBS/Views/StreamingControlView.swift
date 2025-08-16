import SwiftUI

struct StreamingControlView: View {
    @ObservedObject var streamingManager: StreamingManager
    
    var body: some View {
        VStack(spacing: 15) {
            // Connection Status
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                
                Text(streamingManager.connectionStatus)
                    .foregroundColor(.white)
                    .font(.caption)
                
                Spacer()
            }
            
            // Main Controls
            HStack(spacing: 20) {
                // Camera Switch Button
                Button(action: {
                    streamingManager.switchCamera()
                }) {
                    Image(systemName: "camera.rotate")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.8))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Stream Control Button
                Button(action: {
                    switch streamingManager.streamingState {
                    case .idle:
                        streamingManager.startStreaming()
                    case .streaming:
                        streamingManager.stopStreaming()
                    case .preparing:
                        break // Do nothing while preparing
                    case .error(_):
                        streamingManager.stopStreaming()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(streamButtonColor)
                            .frame(width: 70, height: 70)
                        
                        Image(systemName: streamButtonIcon)
                            .font(.title)
                            .foregroundColor(.white)
                    }
                }
                .disabled(streamingManager.streamingState == .preparing)
                .opacity(streamingManager.streamingState == .preparing ? 0.6 : 1.0)
                
                Spacer()
                
                // Settings indicator (placeholder for future use)
                Button(action: {
                    // This could open quick settings
                }) {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.gray.opacity(0.8))
                        .clipShape(Circle())
                }
            }
            
            // Error Message
            if case .error(let message) = streamingManager.streamingState {
                Text(message)
                    .foregroundColor(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
    
    private var statusColor: Color {
        switch streamingManager.streamingState {
        case .idle:
            return .gray
        case .preparing:
            return .yellow
        case .streaming:
            return .green
        case .error(_):
            return .red
        }
    }
    
    private var streamButtonColor: Color {
        switch streamingManager.streamingState {
        case .idle, .error(_):
            return .red
        case .preparing:
            return .yellow
        case .streaming:
            return .red
        }
    }
    
    private var streamButtonIcon: String {
        switch streamingManager.streamingState {
        case .idle, .error(_):
            return "record.circle"
        case .preparing:
            return "clock"
        case .streaming:
            return "stop.circle"
        }
    }
}

struct StreamingControlView_Previews: PreviewProvider {
    static var previews: some View {
        StreamingControlView(streamingManager: StreamingManager())
            .background(Color.black.opacity(0.7))
            .cornerRadius(15)
            .padding()
    }
}