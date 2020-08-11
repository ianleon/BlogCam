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

class FramesDelegate:NSObject,AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        
        print(#function)
    }
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print(#function)
    }
}

struct ContentView: View {
    var session = AVCaptureSession()
    
    var framesOut = AVCaptureVideoDataOutput()
    let framesQueue = DispatchQueue(
        label: "com.ianleon.blogcam",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    let framesDelegate = FramesDelegate()
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
        
        session.addOutput(framesOut)
        framesOut.setSampleBufferDelegate(
            framesDelegate,
            queue: framesQueue
        )

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
