import SwiftUI
import AVKit

class LegacyViewfinder: UIView
{

    // We need to set a type for our layer
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
}

struct Viewfinder:UIViewRepresentable {
    
    var session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let legacyView = LegacyViewfinder()
        PREVIEW : if let previewLayer = legacyView.layer as? AVCaptureVideoPreviewLayer {
            previewLayer.session = session
        }
        return legacyView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        
        // TODO: Handle orientation updates
    }
    
    typealias UIViewType = UIView
}

struct ContentView: View {
    var session = AVCaptureSession()
    
    var body: some View {
        
        // START Setting configuration properties
        session.beginConfiguration()

        
        // Get the capture device
        DEVICE : if let frontCameraDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        ) {

            // Set the capture device
            do {
                try! session.addInput(AVCaptureDeviceInput(device: frontCameraDevice))
            }
        }

        // END Setting configuration properties
        session.commitConfiguration()

        // Start the AVCapture session
        session.startRunning()
        
        return Viewfinder(session: session)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
