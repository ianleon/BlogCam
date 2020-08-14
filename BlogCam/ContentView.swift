import SwiftUI
import AVKit

struct ContentView: View {
    var session = AVCaptureSession()
    
    var framesOut = AVCaptureVideoDataOutput()
    let framesQueue = DispatchQueue(
        label: "com.ianleon.blogcam",
        qos: .userInitiated,
        attributes: [],
        autoreleaseFrequency: .workItem
    )
    let viewfinder = Viewfinder(
        frame: .zero,
        device: MTLCreateSystemDefaultDevice()!
    )
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
            viewfinder,
            queue: framesQueue
        )
        
        // Connection configuratoins
        CONNECTION : for connection in session.connections {
            
            // Handle orientation and mirroring properly
            
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            if connection.isVideoMirroringSupported {
                connection.isVideoMirrored = true
            }
        }

        // END Setting configuration properties
        session.commitConfiguration()

        // Start the AVCapture session
        session.startRunning()
        
        return Rep(view: viewfinder)
    }
}
