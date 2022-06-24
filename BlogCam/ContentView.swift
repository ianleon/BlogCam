import SwiftUI
import AVKit

struct ContentView: View  {
    var session = AVCaptureSession()
    
    var framesOut = AVCaptureVideoDataOutput()
    var photoOut = AVCapturePhotoOutput()
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
    
    func takePicture() {
        photoOut.capturePhoto(
            with: AVCapturePhotoSettings(),
            delegate: viewfinder
        )
    }
    
    func makeFilter() -> CIFilter{
        
        let pixellate = CIFilter.pixellate()
        pixellate.scale = 40
        
        let invert = CIFilter.colorInvert()
        
        _ = CIFilter.holeDistortion()
        
        let hue = CIFilter.hueAdjust()
        hue.angle = .pi
        
        let sharp = CIFilter.sharpenLuminance()
        sharp.sharpness = 40
        
        let unsharp = CIFilter.unsharpMask()
        unsharp.radius = 40
                
        let bloom = CIFilter.bloom()
        bloom.radius = 25
        
        let convolution = CIFilter.convolution3X3()
        convolution.weights = .init(values: [  0, 1,0,
                                              -1, 0,1,
                                               0,-1,0], count: 9)
        convolution.bias = 0.6
        
        let motionBlur = CIFilter.motionBlur()
        motionBlur.radius = 20
        
        let zoom = CIFilter.zoomBlur()
        zoom.amount = 20
        zoom.center = .init(x: 500, y: 500)
        
        return invert
    }
    
    fileprivate func configureSession() {
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
        
        if session.canAddOutput(framesOut) {
            session.addOutput(framesOut)
        }
        
        if session.canAddOutput(photoOut) {
            session.addOutput(photoOut)
        }
        
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
    }
    
    var body: some View {
        
        configureSession()
        
        viewfinder.filter = makeFilter()
        
        return Rep(view: viewfinder)
    }
}
