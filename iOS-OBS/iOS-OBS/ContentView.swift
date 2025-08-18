import SwiftUI

struct ContentView: View {
    @StateObject private var streamingManager = StreamingManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Camera Preview Tab
            CameraPreviewContainer(streamingManager: streamingManager)
                .tabItem {
                    Image(systemName: "camera")
                    Text("Camera")
                }
                .tag(0)
            
            // Control Tab
            NavigationView {
                StreamingControlView(streamingManager: streamingManager)
                    .navigationTitle("iOS OBS")
                    .navigationBarTitleDisplayMode(.large)
            }
            .tabItem {
                Image(systemName: "slider.horizontal.3")
                Text("Control")
            }
            .tag(1)
        }
        .onAppear {
            setupAppearance()
        }
    }
    
    private func setupAppearance() {
        // Configure tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
}