import SwiftUI

struct ContentView: View {
    @StateObject private var streamingManager = StreamingManager()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera Preview
                CameraPreviewView(cameraManager: streamingManager.cameraManager)
                    .ignoresSafeArea()
                
                // Overlay Controls
                VStack {
                    Spacer()
                    
                    StreamingControlView(streamingManager: streamingManager)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(15)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("iOS OBS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingSettings = true
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(configuration: $streamingManager.configuration)
            }
        }
        .onAppear {
            streamingManager.setupCamera()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}