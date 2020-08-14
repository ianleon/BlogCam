import SwiftUI
import AVKit
import MetalKit
import CoreImage
import CoreImage.CIFilterBuiltins

class LegacyMetalViewfinder: MTKView {

    // https://developer.apple.com/wwdc20/10008
    lazy var commandQueue = device!.makeCommandQueue()!
    lazy var context = CIContext(
        mtlCommandQueue: commandQueue,
        options: [
            .name : "FilterContext",
            .cacheIntermediates: false
        ]
    )
    lazy var renderDestination = CIRenderDestination(
        width: Int(drawableSize.width),
        height: Int(drawableSize.height),
        pixelFormat: colorPixelFormat,
        commandBuffer: nil,
        mtlTextureProvider: { self.currentDrawable!.texture }
    )
    var image: CIImage?
}

class LegacyMetalViewFinderDelegate: NSObject, MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TODO
    }
        
    func draw(in view: MTKView) {
        guard
            let view = view as? LegacyMetalViewfinder,
            let image = view.image,
            let drawable = view.currentDrawable,
            let buffer = view.commandQueue.makeCommandBuffer()
        else { return }
        try! view.context.startTask(
            toRender: image,
            to: view.renderDestination
        )
        buffer.present(drawable)
        buffer.commit()
    }
}

struct MetalViewfinder: UIViewRepresentable {
    
    typealias UIViewType = UIView
    
    var legacyViewfinder: LegacyMetalViewfinder
    var metalDelegate = LegacyMetalViewFinderDelegate()
    
    func makeUIView(context: Context) -> UIView {
        legacyViewfinder.backgroundColor = .clear
        legacyViewfinder.delegate = metalDelegate
        return legacyViewfinder
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        // TODO
    }
}

class FramesDelegate:NSObject,AVCaptureVideoDataOutputSampleBufferDelegate {
    let metalViewfinder: LegacyMetalViewfinder
    
    init(viewfinder: LegacyMetalViewfinder) {
        metalViewfinder = viewfinder
        metalViewfinder.framebufferOnly = false
        
        super.init()
    }
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        
        print(#function)
        guard let imageBuffer = sampleBuffer.imageBuffer
        else {
            
            // Could not get an image buffer
            return
        }
        
        // Get a CI Image
        let image = CIImage(cvImageBuffer: imageBuffer)

        // Get the original size of the image
        let originalSize = image.extent.size
        
        // A rect with our frame's aspect ratio that fits in the viewfinder
        let targetRect = AVMakeRect(
            aspectRatio: originalSize,
            insideRect: CGRect(
                origin: .zero,
                size: metalViewfinder.drawableSize
            )
        )
        
        // A transform to size our frame to targetRect
        let scale = CGAffineTransform(
            scaleX: targetRect.size.width / originalSize.width,
            y: targetRect.size.height / originalSize.height
        )
        
        // A transform to center our frame within the viewfinder
        let translate = CGAffineTransform(
            translationX: targetRect.origin.x,
            y: targetRect.origin.y
        )
        
        // Apply a filter
        let filter = CIFilter.pixellate()
        filter.scale = 12
        // We use clamping to resolve some issues with the pixellate filter
        // TODO: Try removing the call to clamped and change the scale.
        // What happens? Do you see what this does for us?
        filter.inputImage = image.clampedToExtent()
        
        // Apply the transforms to the image
        let scaledImage = (filter.outputImage ?? image)
            .cropped(to: image.extent)
            .transformed(by: scale.concatenating(translate))

        // Set the image on the viewfinder
        metalViewfinder.image = scaledImage
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
    let framesDelegate = FramesDelegate(
        viewfinder: LegacyMetalViewfinder(
            frame: .zero,
            device: MTLCreateSystemDefaultDevice()!
        )
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
            framesDelegate,
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
        
        return MetalViewfinder(legacyViewfinder: framesDelegate.metalViewfinder)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
