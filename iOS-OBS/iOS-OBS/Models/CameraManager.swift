import AVFoundation
import UIKit
import os

class CameraManager: NSObject, ObservableObject {
    @Published var isSessionRunning = false
    @Published var isRecording = false
    @Published var currentCameraPosition: AVCaptureDevice.Position = .back
    @Published var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    private let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var audioDeviceInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoOutputQueue = DispatchQueue(label: "camera.video.output.queue")
    private let audioOutputQueue = DispatchQueue(label: "camera.audio.output.queue")
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "iOS-OBS", category: "CameraManager")
    
    weak var delegate: CameraManagerDelegate?
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            self?.configureSession()
        }
    }
    
    private func configureSession() {
        session.beginConfiguration()
        
        // Configure video input
        configureVideoInput()
        
        // Configure audio input
        configureAudioInput()
        
        // Configure video output
        configureVideoOutput()
        
        // Configure audio output
        configureAudioOutput()
        
        session.commitConfiguration()
        
        DispatchQueue.main.async { [weak self] in
            self?.createPreviewLayer()
        }
    }
    
    private func configureVideoInput() {
        guard let camera = bestCameraDevice(for: currentCameraPosition) else {
            logger.error("Failed to get camera device")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: camera)
            
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                videoDeviceInput = videoInput
                logger.info("Added video input: \(camera.localizedName)")
            } else {
                logger.error("Could not add video input to session")
            }
        } catch {
            logger.error("Could not create video input: \(error.localizedDescription)")
        }
    }
    
    private func configureAudioInput() {
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            logger.error("Failed to get audio device")
            return
        }
        
        do {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if session.canAddInput(audioInput) {
                session.addInput(audioInput)
                audioDeviceInput = audioInput
                logger.info("Added audio input")
            } else {
                logger.error("Could not add audio input to session")
            }
        } catch {
            logger.error("Could not create audio input: \(error.localizedDescription)")
        }
    }
    
    private func configureVideoOutput() {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
            logger.info("Added video output")
        } else {
            logger.error("Could not add video output to session")
        }
    }
    
    private func configureAudioOutput() {
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: audioOutputQueue)
        
        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
            self.audioOutput = audioOutput
            logger.info("Added audio output")
        } else {
            logger.error("Could not add audio output to session")
        }
    }
    
    private func createPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer = previewLayer
    }
    
    private func bestCameraDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTripleCamera],
            mediaType: .video,
            position: position
        ).devices
        
        return devices.first
    }
    
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if !self.session.isRunning {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                }
                self.logger.info("Camera session started")
            }
        }
    }
    
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.session.isRunning {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = false
                }
                self.logger.info("Camera session stopped")
            }
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            let newPosition: AVCaptureDevice.Position = self.currentCameraPosition == .back ? .front : .back
            
            guard let newCamera = self.bestCameraDevice(for: newPosition) else {
                self.logger.error("No camera available for position: \(newPosition.rawValue)")
                return
            }
            
            do {
                let newVideoInput = try AVCaptureDeviceInput(device: newCamera)
                
                self.session.beginConfiguration()
                
                if let currentInput = self.videoDeviceInput {
                    self.session.removeInput(currentInput)
                }
                
                if self.session.canAddInput(newVideoInput) {
                    self.session.addInput(newVideoInput)
                    self.videoDeviceInput = newVideoInput
                    
                    DispatchQueue.main.async {
                        self.currentCameraPosition = newPosition
                    }
                    
                    self.logger.info("Switched to camera: \(newCamera.localizedName)")
                } else {
                    // Re-add the old input if we couldn't add the new one
                    if let oldInput = self.videoDeviceInput {
                        self.session.addInput(oldInput)
                    }
                    self.logger.error("Could not add new camera input")
                }
                
                self.session.commitConfiguration()
                
            } catch {
                self.logger.error("Error switching camera: \(error.localizedDescription)")
            }
        }
    }
    
    func configureVideoSettings(resolution: VideoResolution, frameRate: FrameRate) {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let videoDevice = self.videoDeviceInput?.device else { return }
            
            do {
                try videoDevice.lockForConfiguration()
                
                // Find the best format for the requested resolution
                let formats = videoDevice.formats.filter { format in
                    let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                    return dimensions.width == resolution.dimensions.width &&
                           dimensions.height == resolution.dimensions.height
                }
                
                if let bestFormat = formats.first {
                    videoDevice.activeFormat = bestFormat
                    
                    // Set frame rate
                    let frameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate.rawValue))
                    videoDevice.activeVideoMinFrameDuration = frameDuration
                    videoDevice.activeVideoMaxFrameDuration = frameDuration
                    
                    self.logger.info("Configured video: \(resolution.rawValue) at \(frameRate.displayName)")
                }
                
                videoDevice.unlockForConfiguration()
                
            } catch {
                self.logger.error("Error configuring video settings: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate & AVCaptureAudioDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output == videoOutput {
            delegate?.cameraManager(self, didOutput: sampleBuffer, from: .video)
        } else if output == audioOutput {
            delegate?.cameraManager(self, didOutput: sampleBuffer, from: .audio)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        logger.warning("Dropped sample buffer from \(output == videoOutput ? "video" : "audio") output")
    }
}

// MARK: - CameraManagerDelegate

protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer, from mediaType: MediaType)
}

enum MediaType {
    case video
    case audio
}