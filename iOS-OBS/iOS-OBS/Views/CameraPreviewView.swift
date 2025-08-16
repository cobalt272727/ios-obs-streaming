import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> CameraPreviewUIView {
        return CameraPreviewUIView(cameraManager: cameraManager)
    }
    
    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        // Update view if needed
    }
}

class CameraPreviewUIView: UIView {
    private let cameraManager: CameraManager
    
    init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
        super.init(frame: .zero)
        setupPreview()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cameraManager.previewLayer?.frame = bounds
    }
    
    private func setupPreview() {
        guard let previewLayer = cameraManager.previewLayer else { return }
        previewLayer.frame = bounds
        layer.addSublayer(previewLayer)
    }
}

struct CameraPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        CameraPreviewView(cameraManager: CameraManager())
    }
}