import AVFoundation
import UIKit
import os.log

protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutput sampleBuffer: CMSampleBuffer)
    func cameraManager(_ manager: CameraManager, didEncounterError error: Error)
}

class CameraManager: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    
    weak var delegate: CameraManagerDelegate?
    
    @Published var isSessionRunning = false
    @Published var isUsingFrontCamera = false
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let dataOutputQueue = DispatchQueue(label: "camera.data.output.queue")
    
    private let logger = Logger(subsystem: "com.example.iOS-OBS", category: "CameraManager")
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Configure session preset
            if self.session.canSetSessionPreset(.hd1280x720) {
                self.session.sessionPreset = .hd1280x720
            }
            
            self.setupVideoInput()
            self.setupAudioInput()
            self.setupVideoOutput()
            self.setupAudioOutput()
            
            self.session.commitConfiguration()
            
            DispatchQueue.main.async {
                self.setupPreviewLayer()
            }
        }
    }
    
    private func setupVideoInput() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            logger.error("Failed to get back camera")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                self.videoDevice = videoDevice
                self.videoInput = videoInput
                logger.info("Video input added successfully")
            }
        } catch {
            logger.error("Failed to create video input: \(error.localizedDescription)")
        }
    }
    
    private func setupAudioInput() {
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            logger.error("Failed to get audio device")
            return
        }
        
        do {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            if session.canAddInput(audioInput) {
                session.addInput(audioInput)
                self.audioInput = audioInput
                logger.info("Audio input added successfully")
            }
        } catch {
            logger.error("Failed to create audio input: \(error.localizedDescription)")
        }
    }
    
    private func setupVideoOutput() {
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
            logger.info("Video output added successfully")
        }
    }
    
    private func setupAudioOutput() {
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
        
        if session.canAddOutput(audioOutput) {
            session.addOutput(audioOutput)
            self.audioOutput = audioOutput
            logger.info("Audio output added successfully")
        }
    }
    
    private func setupPreviewLayer() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        self.previewLayer = previewLayer
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
                    self.isSessionRunning = self.session.isRunning
                }
                self.logger.info("Camera session stopped")
            }
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Remove current video input
            if let currentInput = self.videoInput {
                self.session.removeInput(currentInput)
            }
            
            // Get new camera
            let newPosition: AVCaptureDevice.Position = self.isUsingFrontCamera ? .back : .front
            guard let newVideoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
                self.logger.error("Failed to get camera for position: \(newPosition)")
                self.session.commitConfiguration()
                return
            }
            
            // Add new video input
            do {
                let newVideoInput = try AVCaptureDeviceInput(device: newVideoDevice)
                if self.session.canAddInput(newVideoInput) {
                    self.session.addInput(newVideoInput)
                    self.videoDevice = newVideoDevice
                    self.videoInput = newVideoInput
                    
                    DispatchQueue.main.async {
                        self.isUsingFrontCamera = newPosition == .front
                    }
                    
                    self.logger.info("Camera switched to: \(newPosition)")
                }
            } catch {
                self.logger.error("Failed to switch camera: \(error.localizedDescription)")
            }
            
            self.session.commitConfiguration()
        }
    }
    
    func updateVideoResolution(_ resolution: VideoResolution) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            switch resolution {
            case .hd720:
                if self.session.canSetSessionPreset(.hd1280x720) {
                    self.session.sessionPreset = .hd1280x720
                }
            case .hd1080:
                if self.session.canSetSessionPreset(.hd1920x1080) {
                    self.session.sessionPreset = .hd1920x1080
                }
            }
            
            self.session.commitConfiguration()
            self.logger.info("Video resolution updated to: \(resolution.rawValue)")
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.cameraManager(self, didOutput: sampleBuffer)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        logger.warning("Sample buffer dropped")
    }
}