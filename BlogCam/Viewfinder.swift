//
//  Viewfinder.swift
//  BlogCam
//
//  Created by Ian Leon on 8/14/20.
//

import AVKit
import MetalKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

class Viewfinder: MTKView {
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
    
    /// Current image to show as preview
    var image: CIImage?
    
    /// Filter applied to `image`
    var filter: CIFilter?
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        framebufferOnly = false
        backgroundColor = .clear
        delegate = self
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension Viewfinder: MTKViewDelegate {
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TODO
    }
        
    func draw(in view: MTKView) {
        guard
            let view = view as? Viewfinder,
            let image = view.image,
            let drawable = view.currentDrawable,
            let buffer = view.commandQueue.makeCommandBuffer()
        else { return }
        do {
            try view.context.startTask(
                toRender: image,
                to: view.renderDestination
            )
            buffer.present(drawable)
            buffer.commit()
        }
        catch {
            print(error.localizedDescription)
        }
    }
}

extension Viewfinder: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {

        guard let imageBuffer = sampleBuffer.imageBuffer
        else {
            
            // Could not get an image buffer
            return
        }
        
        // Get a CI Image
        let sampleImage = CIImage(cvImageBuffer: imageBuffer)

        // Get the original size of the image
        let originalSize = sampleImage.extent.size
        
        // A rect with our frame's aspect ratio that fits in the viewfinder
        let targetRect = AVMakeRect(
            aspectRatio: originalSize,
            insideRect: CGRect(
                origin: .zero,
                size: drawableSize
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
        filter?.setValue(sampleImage.clampedToExtent(),
                         forKey: kCIInputImageKey)
        
        // Apply the transforms to the image
        let scaledImage = (filter?.outputImage ?? sampleImage)
            .cropped(to: sampleImage.extent)
            .transformed(by: scale.concatenating(translate))

        // Set the image on the viewfinder
        image = scaledImage
    }
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // print(#function)
    }
}
