import SwiftUI
import AVFoundation
import UIKit

struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            previewLayer.frame = uiView.bounds
        }
    }
}

struct CameraPreviewOverlay: View {
    @ObservedObject var streamingManager: StreamingManager
    let onSwitchCamera: () -> Void
    let onToggleStreaming: () -> Void
    
    var body: some View {
        VStack {
            // Top overlay - Status and camera switch
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 12, height: 12)
                        
                        Text(streamingManager.streamingState.displayText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    if streamingManager.isStreaming {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("Video")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(streamingManager.videoFramesEncoded)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Audio")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.7))
                                Text("\(streamingManager.audioSamplesEncoded)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                
                Spacer()
                
                Button(action: onSwitchCamera) {
                    Image(systemName: "camera.rotate")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .padding()
            
            Spacer()
            
            // Bottom overlay - Streaming controls
            VStack(spacing: 16) {
                if let error = streamingManager.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
                
                Button(action: onToggleStreaming) {
                    HStack {
                        Image(systemName: streamingManager.isStreaming ? "stop.circle.fill" : "play.circle.fill")
                            .font(.title2)
                        
                        Text(streamingManager.isStreaming ? "Stop Streaming" : "Start Streaming")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        streamingManager.isStreaming ? 
                        Color.red : Color.green
                    )
                    .clipShape(Capsule())
                }
                .disabled(!streamingManager.streamingState.canStartStreaming && !streamingManager.isStreaming)
            }
            .padding(.bottom, 32)
        }
    }
    
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
}

struct CameraPreviewContainer: View {
    @ObservedObject var streamingManager: StreamingManager
    @State private var previewLayer: AVCaptureVideoPreviewLayer?
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if let previewLayer = previewLayer {
                CameraPreviewView(previewLayer: previewLayer)
                    .ignoresSafeArea()
            } else {
                VStack {
                    Image(systemName: "camera")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("Camera Preview")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.top, 8)
                }
            }
            
            CameraPreviewOverlay(
                streamingManager: streamingManager,
                onSwitchCamera: {
                    streamingManager.switchCamera()
                },
                onToggleStreaming: {
                    if streamingManager.isStreaming {
                        streamingManager.stopStreaming()
                    } else {
                        streamingManager.startStreaming()
                    }
                }
            )
        }
        .onAppear {
            setupPreviewLayer()
        }
    }
    
    private func setupPreviewLayer() {
        previewLayer = streamingManager.createPreviewLayer()
    }
}

#Preview {
    CameraPreviewContainer(streamingManager: StreamingManager())
}