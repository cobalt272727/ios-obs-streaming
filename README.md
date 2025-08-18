# iOS OBS - Basic Camera Streaming Application

A SwiftUI-based iOS application that provides basic camera streaming functionality similar to OBS Studio. This app supports both RTMP and WHIP (WebRTC-HTTP Ingestion Protocol) streaming protocols.

## Features

### Core Functionality
- ✅ Real-time camera preview
- ✅ Front/rear camera switching
- ✅ Live audio/video capture
- ✅ H.264 video encoding
- ✅ AAC audio encoding
- ✅ RTMP streaming support
- ✅ WHIP streaming support (basic implementation)
- ✅ SwiftUI-based modern interface

### Camera & Audio
- Multi-resolution support (720p, 1080p)
- Configurable frame rates (24, 30, 60 fps)
- Adjustable video bitrates (500-8000 kbps)
- Audio capture with configurable bitrates
- Real-time preview with overlay controls

### Streaming Protocols
- **RTMP**: Traditional streaming to services like YouTube, Twitch
- **WHIP**: Modern WebRTC-based streaming protocol
- Automatic connection management
- Real-time status monitoring
- Error handling and retry logic

### User Interface
- Intuitive camera preview with overlay controls
- Comprehensive settings panel
- Real-time streaming statistics
- Status indicators and error messages
- Modern SwiftUI design

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+
- Camera and microphone permissions

## Project Structure

```
iOS-OBS/
├── iOS-OBS.xcodeproj          # Xcode project file
├── iOS-OBS/
│   ├── App.swift              # Main app entry point
│   ├── ContentView.swift      # Root view with tab navigation
│   ├── Info.plist            # App configuration and permissions
│   ├── Models/
│   │   ├── CameraManager.swift           # Camera session management
│   │   ├── StreamingManager.swift        # Main streaming orchestrator
│   │   └── StreamingConfiguration.swift  # Configuration models
│   ├── Views/
│   │   ├── CameraPreviewView.swift       # Camera preview and overlay
│   │   ├── StreamingControlView.swift    # Control panel
│   │   └── SettingsView.swift           # Settings configuration
│   ├── Network/
│   │   ├── RTMPStreamer.swift           # RTMP protocol implementation
│   │   └── WHIPStreamer.swift           # WHIP protocol implementation
│   └── Utils/
│       └── VideoEncoder.swift           # Video/audio encoding utilities
└── README.md
```

## Key Classes

### StreamingManager
The main orchestrator that coordinates all streaming components:
- Manages camera and audio sessions
- Controls video/audio encoding
- Handles protocol selection and streaming
- Provides unified state management

### CameraManager
Handles all camera-related operations:
- AVCaptureSession management
- Device configuration (resolution, frame rate)
- Camera switching (front/rear)
- Sample buffer delegation

### VideoEncoder / AudioEncoder
Real-time encoding components:
- H.264 hardware encoding for video
- AAC encoding for audio
- Configurable bitrates and quality settings
- Efficient memory management

### RTMPStreamer
RTMP protocol implementation:
- TCP connection management
- RTMP handshake simulation
- FLV packet creation
- Stream publishing

### WHIPStreamer
WHIP protocol implementation:
- HTTP-based WebRTC signaling
- SDP offer/answer handling
- Basic WebRTC connection simulation

## Usage

### Basic Setup
1. Open the app and grant camera/microphone permissions
2. Navigate to Settings to configure your streaming parameters
3. Choose between RTMP or WHIP protocol
4. Configure your streaming endpoint and credentials

### RTMP Streaming
1. Select "RTMP" as the protocol
2. Enter your RTMP URL (e.g., `rtmp://live.twitch.tv/live/`)
3. Enter your stream key
4. Configure video settings (resolution, bitrate, frame rate)
5. Start streaming

### WHIP Streaming
1. Select "WHIP" as the protocol
2. Enter your WHIP endpoint URL
3. Configure video settings
4. Start streaming

### Camera Controls
- Tap the camera rotate button to switch between front/rear cameras
- Streaming status is displayed in real-time
- Statistics show encoded frames and samples

## Configuration Options

### Video Settings
- **Resolution**: 720p (1280x720) or 1080p (1920x1080)
- **Bitrate**: 500-8000 kbps (adjustable)
- **Frame Rate**: 24, 30, or 60 fps

### Audio Settings
- **Bitrate**: 64, 128, 192, or 256 kbps
- **Sample Rate**: 44.1 kHz or 48 kHz

### Connection Settings
- **Timeout**: 10-60 seconds
- **Retry Attempts**: 1-10 attempts

## Development Notes

### Architecture
- **MVVM Pattern**: Views observe state changes in managers
- **Combine Framework**: Reactive programming for state management
- **Concurrent Queues**: Separate queues for encoding and network operations
- **Delegate Pattern**: Camera samples delivered via delegation

### Performance Considerations
- Hardware-accelerated video encoding using VideoToolbox
- Efficient memory management for sample buffers
- Background queue processing to maintain UI responsiveness
- Automatic frame dropping for real-time performance

### Error Handling
- Comprehensive error types and messages
- Automatic retry logic for connection failures
- User-friendly error display in the UI
- Logging for debugging purposes

## Limitations & Future Enhancements

### Current Limitations
- RTMP implementation is simplified (basic protocol simulation)
- WHIP implementation is basic (no full WebRTC stack)
- No advanced video filters or effects
- No background streaming support

### Potential Enhancements
- Full RTMP protocol implementation
- Complete WebRTC integration for WHIP
- Advanced camera controls (focus, exposure, white balance)
- Video filters and effects
- Background streaming capability
- Stream recording functionality
- Multiple simultaneous streams
- Custom video overlays
- Scene management

## License

This project is intended for educational and development purposes. Please ensure compliance with streaming service terms of service and applicable regulations when using for production streaming.

## Contributing

This is a basic implementation suitable for learning and development. Contributions and improvements are welcome, particularly:
- Full protocol implementations
- Additional streaming features
- Performance optimizations
- UI/UX improvements
- Documentation enhancements

## Support

For issues and questions:
1. Check the error messages in the app UI
2. Review the Xcode console for detailed logs
3. Verify camera/microphone permissions
4. Ensure valid streaming endpoints and credentials