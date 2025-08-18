import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.cameraManager = cameraManager
        return view
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Update the preview layer if needed
        uiView.updatePreviewLayer()
    }
}

class CameraPreviewUIView: UIView {
    var cameraManager: CameraManager? {
        didSet {
            updatePreviewLayer()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updatePreviewLayerFrame()
    }
    
    func updatePreviewLayer() {
        // Remove existing preview layer
        layer.sublayers?.removeAll { $0 is AVCaptureVideoPreviewLayer }
        
        guard let previewLayer = cameraManager?.videoPreviewLayer else { return }
        
        previewLayer.frame = bounds
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }
    
    private func updatePreviewLayerFrame() {
        if let previewLayer = layer.sublayers?.first(where: { $0 is AVCaptureVideoPreviewLayer }) as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = bounds
        }
    }
}

struct CameraPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        CameraPreviewView(cameraManager: CameraManager())
    }
}