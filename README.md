# iOS OBS Basic Camera Streaming

A SwiftUI-based iOS application for real-time camera streaming with support for RTMP and WHIP protocols.

## Overview

This project implements a basic iOS OBS (Open Broadcaster Software) equivalent that allows users to stream camera feed in real-time. It supports both RTMP (Real-Time Messaging Protocol) and WHIP (WebRTC-HTTP Ingestion Protocol) streaming protocols.

## Features

### Core Functionality
- **Real-time Camera Streaming**: Live video capture and streaming
- **Dual Protocol Support**: RTMP and WHIP protocols
- **Camera Management**: Front/rear camera switching
- **Video Encoding**: Hardware-accelerated H.264 encoding
- **Audio Capture**: Built-in microphone support with AAC encoding
- **Settings Persistence**: Save and restore streaming configurations

### User Interface
- **SwiftUI Design**: Modern, native iOS interface
- **Real-time Preview**: Live camera preview with overlay controls
- **Settings Panel**: Comprehensive configuration options
- **Status Indicators**: Connection status and streaming state
- **Intuitive Controls**: Easy-to-use streaming controls

### Technical Features
- **Hardware Acceleration**: VideoToolbox-based H.264 encoding
- **Configurable Quality**: Multiple resolution and bitrate options
- **Background Support**: Audio background processing capability
- **Error Handling**: Comprehensive error management and logging
- **Memory Efficient**: Optimized for iOS resource constraints

## Quick Start

1. **Clone the Repository**
   ```bash
   git clone https://github.com/cobalt272727/ios-obs-streaming.git
   cd ios-obs-streaming
   ```

2. **Open in Xcode**
   ```bash
   open iOS-OBS/iOS-OBS.xcodeproj
   ```

3. **Build and Run**
   - Select a physical iOS device (iOS 15.0+)
   - Build and run the project
   - Grant camera and microphone permissions

4. **Configure Streaming**
   - Tap "Settings" to configure RTMP or WHIP settings
   - Enter your streaming server details
   - Adjust video quality settings as needed

5. **Start Streaming**
   - Tap the red record button to begin streaming
   - Use camera switch button to toggle between cameras
   - Monitor connection status in the overlay

## Project Structure

```
iOS-OBS/
├── iOS-OBS.xcodeproj           # Xcode project file
├── iOS-OBS/                    # Main app directory
│   ├── App.swift               # App entry point
│   ├── ContentView.swift       # Main UI view
│   ├── Info.plist             # App configuration
│   ├── Models/                 # Data models and business logic
│   │   ├── StreamingManager.swift      # Core streaming coordinator
│   │   ├── CameraManager.swift         # Camera session management
│   │   └── StreamingConfiguration.swift # Settings data model
│   ├── Views/                  # SwiftUI views
│   │   ├── CameraPreviewView.swift     # Camera preview
│   │   ├── StreamingControlView.swift  # Stream controls
│   │   └── SettingsView.swift          # Configuration UI
│   ├── Network/                # Streaming protocols
│   │   ├── RTMPStreamer.swift          # RTMP implementation
│   │   └── WHIPStreamer.swift          # WHIP implementation
│   ├── Utils/                  # Utility classes
│   │   └── VideoEncoder.swift          # Video encoding
│   └── Assets.xcassets         # App assets
└── README.md                   # This file
```

## Requirements

### System Requirements
- **iOS**: 15.0 or later
- **Xcode**: 13.0 or later
- **Swift**: 5.0 or later
- **Device**: Physical iOS device (camera functionality requires hardware)

### Permissions
- Camera access for video capture
- Microphone access for audio capture
- Background audio processing (optional)

## Configuration Options

### Streaming Protocols
- **RTMP**: Traditional streaming to RTMP servers (Twitch, YouTube, etc.)
- **WHIP**: Modern WebRTC-based streaming protocol

### Video Quality Settings
- **Resolution**: 720p (1280x720) or 1080p (1920x1080)
- **Bitrate**: 1-8 Mbps (Low, Medium, High, Ultra presets)
- **Frame Rate**: 15-60 fps (configurable in 5fps steps)

### Audio Settings
- Built-in microphone capture
- AAC encoding
- Background audio processing support

## Implementation Details

### Architecture Pattern
- **MVVM**: Model-View-ViewModel architecture with SwiftUI
- **Delegation**: Protocol-based communication between components
- **Reactive**: Combine framework for state management

### Key Technologies
- **SwiftUI**: Modern iOS UI framework
- **AVFoundation**: Camera and audio capture
- **VideoToolbox**: Hardware-accelerated video encoding
- **Network**: TCP/HTTP networking for streaming protocols
- **Combine**: Reactive programming for state management

### Performance Optimizations
- Hardware-accelerated encoding
- Asynchronous processing queues
- Memory-efficient buffer management
- Background processing support

## Known Limitations

This is a basic implementation suitable for educational and prototyping purposes:

1. **RTMP Protocol**: Simplified implementation without full RTMP specification
2. **WHIP Protocol**: Basic WebRTC signaling without complete peer connection
3. **Network Resilience**: Limited automatic reconnection and error recovery
4. **Audio Processing**: Basic capture without advanced audio features
5. **Adaptive Streaming**: No dynamic bitrate adjustment based on network conditions

## Future Roadmap

### Planned Enhancements
- Full WebRTC implementation for WHIP protocol
- Advanced audio processing and mixing capabilities
- Adaptive bitrate streaming based on network conditions
- Stream overlays, effects, and scene management
- Local recording functionality
- Stream analytics and performance monitoring
- Multiple camera input support
- Custom streaming server integration

### Potential Features
- Scene transitions and effects
- Real-time filters and augmented reality
- Multi-platform streaming (simultaneous RTMP/WHIP)
- Cloud-based configuration management
- Advanced audio mixing and effects
- Stream scheduling and automation

## Development

### Getting Started
1. Ensure you have Xcode 13+ installed
2. Clone the repository and open the project
3. Build and run on a physical iOS device
4. Review the code structure and architecture

### Contributing
Contributions are welcome! Areas for improvement:
- Protocol implementations (RTMP/WHIP)
- User interface enhancements
- Performance optimizations
- Error handling improvements
- Documentation and examples

### Testing
- Test on various iOS devices and versions
- Verify streaming with different server configurations
- Performance testing under various network conditions
- Memory usage and battery life optimization

## License

This project is provided for educational and development purposes.

## Support

For questions, issues, or feature requests, please use the GitHub Issues system.

---

**Note**: This is a basic implementation designed for learning and prototyping. For production use, consider additional security, error handling, and protocol compliance features.