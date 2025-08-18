import AVFoundation
import UIKit
import Combine

class CameraManager: NSObject, ObservableObject {
    @Published var isRunning = false
    @Published var isFrontCamera = false
    @Published var error: Error?
    
    private let captureSession = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    
    // Delegate for receiving video/audio samples
    weak var delegate: CameraManagerDelegate?
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoDataOutputQueue = DispatchQueue(label: "camera.video.queue")
    private let audioDataOutputQueue = DispatchQueue(label: "camera.audio.queue")
    
    override init() {
        super.init()
        setupCaptureSession()
    }
    
    // MARK: - Public Methods
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
                
                DispatchQueue.main.async {
                    self.isRunning = self.captureSession.isRunning
                }
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
                
                DispatchQueue.main.async {
                    self.isRunning = false
                }
            }
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            
            // Remove current video input
            if let currentInput = self.videoInput {
                self.captureSession.removeInput(currentInput)
            }
            
            // Switch camera position
            let newPosition: AVCaptureDevice.Position = self.isFrontCamera ? .back : .front
            
            if let newDevice = self.getCamera(for: newPosition),
               let newInput = try? AVCaptureDeviceInput(device: newDevice) {
                
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.videoDevice = newDevice
                    self.videoInput = newInput
                    
                    DispatchQueue.main.async {
                        self.isFrontCamera = newPosition == .front
                    }
                }
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    func configure(resolution: VideoResolution, frameRate: Int) {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let device = self.videoDevice else { return }
            
            do {
                try device.lockForConfiguration()
                
                // Set frame rate
                let frameDuration = CMTime(value: 1, timescale: CMTimeScale(frameRate))
                device.activeVideoMinFrameDuration = frameDuration
                device.activeVideoMaxFrameDuration = frameDuration
                
                // Configure session preset based on resolution
                self.captureSession.beginConfiguration()
                
                switch resolution {
                case .hd720p:
                    if self.captureSession.canSetSessionPreset(.hd1280x720) {
                        self.captureSession.sessionPreset = .hd1280x720
                    }
                case .hd1080p:
                    if self.captureSession.canSetSessionPreset(.hd1920x1080) {
                        self.captureSession.sessionPreset = .hd1920x1080
                    }
                }
                
                self.captureSession.commitConfiguration()
                device.unlockForConfiguration()
                
            } catch {
                DispatchQueue.main.async {
                    self.error = error
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupCaptureSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            
            // Configure video
            self.setupVideo()
            
            // Configure audio
            self.setupAudio()
            
            self.captureSession.commitConfiguration()
        }
    }
    
    private func setupVideo() {
        // Add video input
        guard let videoDevice = getCamera(for: .back) else {
            print("Failed to get video device")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                self.videoDevice = videoDevice
                self.videoInput = videoInput
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
            return
        }
        
        // Add video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            self.videoOutput = videoOutput
        }
    }
    
    private func setupAudio() {
        // Add audio input
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("Failed to get audio device")
            return
        }
        
        do {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
                self.audioInput = audioInput
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
            return
        }
        
        // Add audio output
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: audioDataOutputQueue)
        
        if captureSession.canAddOutput(audioOutput) {
            captureSession.addOutput(audioOutput)
            self.audioOutput = audioOutput
        }
    }
    
    private func getCamera(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )
        
        return discoverySession.devices.first
    }
    
    // MARK: - Preview Layer
    
    func createPreviewLayer() -> AVCaptureVideoPreviewLayer {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        return previewLayer
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if output == videoOutput {
            delegate?.cameraManager(self, didOutput: sampleBuffer, from: .video)
        } else if output == audioOutput {
            delegate?.cameraManager(self, didOutput: sampleBuffer, from: .audio)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("Sample buffer dropped")
    }
}

// MARK: - Camera Manager Delegate

protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer, from mediaType: MediaType)
}

enum MediaType {
    case video
    case audio
}