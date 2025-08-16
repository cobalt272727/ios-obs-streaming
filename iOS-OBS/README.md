# iOS OBS Basic Camera Streaming

A basic iOS camera streaming application built with SwiftUI that supports both RTMP and WHIP streaming protocols.

## Features

- **Real-time Camera Streaming**: Live camera feed with front/rear camera switching
- **Multiple Streaming Protocols**: 
  - RTMP (Real-Time Messaging Protocol)
  - WHIP (WebRTC-HTTP Ingestion Protocol)
- **Video Encoding**: H.264 hardware-accelerated encoding
- **Audio Capture**: AAC audio encoding support
- **Configurable Quality**: 720p/1080p resolution with adjustable bitrate
- **User-Friendly Interface**: SwiftUI-based modern iOS interface

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.0+
- Camera and microphone permissions

## Getting Started

### Installation

1. Clone the repository
2. Open `iOS-OBS.xcodeproj` in Xcode
3. Build and run on a physical iOS device (camera streaming requires physical device)

### Configuration

1. Open the app and tap the "Settings" button
2. Choose your streaming protocol (RTMP or WHIP)
3. Configure the appropriate settings:

#### RTMP Settings
- **Server URL**: Your RTMP server URL (e.g., `rtmp://live.twitch.tv/live/`)
- **Stream Key**: Your unique stream key from your streaming platform

#### WHIP Settings
- **WHIP Endpoint**: Your WHIP server endpoint URL

#### Video Quality Settings
- **Resolution**: 720p (1280x720) or 1080p (1920x1080)
- **Bitrate**: Low (1 Mbps), Medium (2.5 Mbps), High (5 Mbps), or Ultra (8 Mbps)
- **Frame Rate**: 15-60 fps (adjustable in 5fps increments)

### Usage

1. Configure your streaming settings in the Settings panel
2. Grant camera and microphone permissions when prompted
3. Point your camera at what you want to stream
4. Tap the red record button to start streaming
5. Use the camera switch button to toggle between front and rear cameras
6. Tap the stop button to end the stream

## Architecture

### Project Structure

```
iOS-OBS/
├── iOS-OBS.xcodeproj
├── iOS-OBS/
│   ├── App.swift                    # Main app entry point
│   ├── ContentView.swift            # Main UI view
│   ├── Info.plist                   # App configuration and permissions
│   ├── Models/
│   │   ├── StreamingManager.swift   # Core streaming coordination
│   │   ├── CameraManager.swift      # Camera session management
│   │   └── StreamingConfiguration.swift # Settings data model
│   ├── Views/
│   │   ├── CameraPreviewView.swift  # Camera preview display
│   │   ├── StreamingControlView.swift # Stream controls UI
│   │   └── SettingsView.swift       # Configuration interface
│   ├── Network/
│   │   ├── RTMPStreamer.swift       # RTMP protocol implementation
│   │   └── WHIPStreamer.swift       # WHIP protocol implementation
│   ├── Utils/
│   │   └── VideoEncoder.swift       # H.264 video encoding
│   └── Assets.xcassets             # App icons and assets
└── README.md
```

### Key Components

#### StreamingManager
- Coordinates between camera, encoder, and network components
- Manages streaming state and error handling
- Acts as delegate for camera, encoder, and streaming components

#### CameraManager
- Manages AVCaptureSession for video and audio input
- Handles camera switching and configuration
- Provides real-time preview layer

#### VideoEncoder
- Hardware-accelerated H.264 encoding using VideoToolbox
- Configurable bitrate, resolution, and frame rate
- Real-time frame processing

#### RTMPStreamer
- Basic RTMP protocol implementation
- TCP connection management
- Simplified RTMP handshake and packet formatting

#### WHIPStreamer
- WebRTC-HTTP Ingestion Protocol implementation
- HTTP-based WebRTC signaling
- SDP offer/answer handling

## Permissions

The app requires the following permissions (configured in Info.plist):

- **NSCameraUsageDescription**: Camera access for video streaming
- **NSMicrophoneUsageDescription**: Microphone access for audio streaming
- **UIBackgroundModes**: Background audio processing support

## Known Limitations

This is a basic implementation intended for educational and prototype purposes:

1. **RTMP Implementation**: Simplified RTMP protocol implementation
2. **WHIP Implementation**: Basic WebRTC signaling without full peer connection
3. **Error Recovery**: Limited automatic reconnection capabilities
4. **Audio Processing**: Basic audio capture without advanced processing
5. **Network Optimization**: No adaptive bitrate or network condition handling

## Future Enhancements

- Full WebRTC implementation for WHIP
- Advanced audio processing and mixing
- Adaptive bitrate streaming
- Stream overlays and effects
- Recording to local storage
- Stream analytics and monitoring
- Multiple camera inputs
- Custom RTMP server integration

## License

This project is available for educational and development purposes.

## Contributing

Contributions are welcome! Please feel free to submit issues and enhancement requests.

## Support

For questions and support, please open an issue in this repository.