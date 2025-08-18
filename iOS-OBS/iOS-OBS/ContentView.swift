import SwiftUI

struct ContentView: View {
    @StateObject private var streamingManager = StreamingManager()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Camera preview background
                CameraPreviewView(cameraManager: streamingManager.cameraManager)
                    .ignoresSafeArea()
                
                // Control overlay
                VStack {
                    Spacer()
                    
                    StreamingControlView(streamingManager: streamingManager)
                        .padding()
                }
            }
            .navigationTitle("iOS OBS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Settings") {
                        showingSettings = true
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(configuration: $streamingManager.configuration)
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}