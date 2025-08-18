import SwiftUI
import AVFoundation

@main
struct iOSOBSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Request camera and microphone permissions on app launch
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        if granted {
                            print("Camera access granted")
                        } else {
                            print("Camera access denied")
                        }
                    }
                    
                    AVCaptureDevice.requestAccess(for: .audio) { granted in
                        if granted {
                            print("Microphone access granted")
                        } else {
                            print("Microphone access denied")
                        }
                    }
                }
        }
    }
}