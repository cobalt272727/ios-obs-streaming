# iOS OBS - Basic Camera Streaming Application

A SwiftUI-based iOS application that provides basic OBS-style camera streaming functionality with support for RTMP and WHIP protocols.

## Features

### Core Functionality
- **Real-time Camera Preview**: Live camera feed with support for front/rear camera switching
- **Dual Protocol Support**: Stream via RTMP or WHIP protocols
- **Video Encoding**: H.264 hardware-accelerated video encoding
- **Audio Capture**: Microphone audio input with basic processing
- **User-Friendly Interface**: SwiftUI-based modern interface with streaming controls

### Streaming Protocols
- **RTMP**: Traditional streaming to platforms like Twitch, YouTube Live, etc.
- **WHIP**: WebRTC-based HTTP Ingestion Protocol for modern streaming

### Video Settings
- **Resolution Options**: 720p (1280x720) and 1080p (1920x1080)
- **Bitrate Control**: 1 Mbps to 8 Mbps configurable bitrates
- **Frame Rate**: 24, 30, or 60 FPS options
- **Real-time Encoding**: Hardware-accelerated H.264 encoding

### Audio Settings
- **Audio Bitrate**: Configurable from 64 kbps to 320 kbps
- **AAC Encoding**: Standard audio encoding for streaming
- **Background Audio**: Supports audio streaming in background mode

## Project Structure

```
iOS-OBS/
├── iOS-OBS.xcodeproj
├── iOS-OBS/
│   ├── App.swift                     # Main app entry point
│   ├── ContentView.swift             # Main UI view
│   ├── Info.plist                    # App configuration and permissions
│   ├── Models/
│   │   ├── StreamingManager.swift    # Core streaming coordination
│   │   ├── CameraManager.swift       # Camera session management
│   │   └── StreamingConfiguration.swift # Configuration model
│   ├── Views/
│   │   ├── CameraPreviewView.swift   # Camera preview UI component
│   │   ├── StreamingControlView.swift # Streaming control buttons
│   │   └── SettingsView.swift        # Configuration settings UI
│   ├── Network/
│   │   ├── RTMPStreamer.swift        # RTMP protocol implementation
│   │   └── WHIPStreamer.swift        # WHIP protocol implementation
│   ├── Utils/
│   │   └── VideoEncoder.swift        # H.264 video encoding
│   ├── Assets.xcassets               # App icons and assets
│   └── Preview Content/              # SwiftUI preview assets
└── README.md
```

## Requirements

- **iOS**: 15.0 or later
- **Xcode**: 14.0 or later
- **Swift**: 5.7 or later
- **Device**: iPhone or iPad with camera and microphone

## Permissions

The app requires the following permissions (configured in Info.plist):
- **Camera Access**: `NSCameraUsageDescription`
- **Microphone Access**: `NSMicrophoneUsageDescription`
- **Background Audio**: `UIBackgroundModes` with `audio`

## Setup Instructions

### 1. Clone and Open Project
```bash
git clone [repository-url]
cd ios-obs-streaming/iOS-OBS
open iOS-OBS.xcodeproj
```

### 2. Configure Development Team
- Open the project in Xcode
- Select the iOS-OBS target
- Set your development team in Signing & Capabilities

### 3. Install Dependencies (if needed)
For the WHIP implementation to work fully, you may need to add WebRTC:
```bash
# Add WebRTC via Swift Package Manager or CocoaPods
# See WebRTC installation documentation
```

### 4. Run on Device
- Connect an iOS device (camera/microphone required)
- Build and run the project

## Usage

### Basic Streaming Setup

1. **Launch the App**: Open iOS OBS on your device
2. **Configure Settings**: Tap the Settings button to configure:
   - Choose streaming protocol (RTMP or WHIP)
   - Enter server details (RTMP URL/Stream Key or WHIP endpoint)
   - Set video quality (resolution, bitrate, frame rate)
   - Adjust audio settings

3. **Start Streaming**: Tap the red record button to begin streaming
4. **Camera Controls**: Use the camera rotate button to switch between front/rear cameras
5. **Monitor Status**: View connection status and bitrate information

### RTMP Configuration

For RTMP streaming, you'll need:
- **RTMP URL**: Server endpoint (e.g., `rtmp://live.twitch.tv/live/`)
- **Stream Key**: Unique key provided by streaming platform

### WHIP Configuration

For WHIP streaming, you'll need:
- **Endpoint URL**: WHIP server endpoint (e.g., `https://live.example.com/whip`)

## Architecture Overview

### StreamingManager
Central coordinator that manages:
- Camera session lifecycle
- Encoder configuration
- Protocol selection and streaming
- State management and error handling

### CameraManager
Handles AVFoundation camera operations:
- Camera session setup and management
- Device configuration (resolution, frame rate)
- Real-time video/audio capture
- Camera switching functionality

### Protocol Implementations
- **RTMPStreamer**: Basic RTMP protocol implementation with handshake and messaging
- **WHIPStreamer**: WebRTC-based WHIP protocol for modern streaming

### Video Encoding
- Hardware-accelerated H.264 encoding using VideoToolbox
- Configurable bitrate and resolution
- Real-time encoding with low latency

## Limitations and Notes

### Current Implementation Status
- ✅ Basic UI and camera preview
- ✅ Camera management and controls
- ✅ Settings persistence
- ✅ Video encoding infrastructure
- ⚠️ RTMP implementation (basic/simplified)
- ⚠️ WHIP implementation (requires WebRTC framework)
- ⚠️ Audio encoding (basic implementation)

### Known Limitations
1. **RTMP Implementation**: Simplified version, may need enhancement for production use
2. **WHIP Support**: Requires WebRTC framework integration
3. **Audio Encoding**: Basic implementation, not production-ready AAC encoding
4. **Error Recovery**: Basic error handling, could be more robust
5. **Background Streaming**: Limited background capabilities

### Production Considerations
- Add comprehensive error handling and recovery
- Implement proper AAC audio encoding
- Add network adaptive bitrate streaming
- Include detailed logging and analytics
- Add stream quality monitoring
- Implement reconnection logic
- Add support for custom RTMP parameters

## Development Notes

### Testing
- Test on physical iOS devices (simulator lacks camera/microphone)
- Test with actual RTMP servers (Twitch, YouTube, etc.)
- Verify permissions are granted properly
- Test camera switching and app backgrounding

### Performance
- Monitor CPU usage during encoding
- Check memory usage with long streaming sessions
- Test battery consumption impact
- Verify thermal management

### Security
- Never hardcode stream keys or credentials
- Use secure storage for sensitive configuration
- Validate all user inputs
- Implement secure network communications

## Contributing

When contributing to this project:
1. Follow Swift coding conventions
2. Add appropriate error handling
3. Include unit tests for new functionality
4. Update documentation for new features
5. Test on multiple device types and iOS versions

## License

[Add appropriate license information]

## Support

For issues and questions:
- Check the GitHub issues
- Review the documentation
- Test with minimal configuration first

---

*This is a basic implementation intended for educational and development purposes. Production use requires additional testing, optimization, and feature completion.*