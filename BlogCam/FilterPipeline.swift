//
//  FilterPipeline.swift
//  BlogCam
//
//  Created by Ian Leon on 8/15/20.
//

import Foundation
import CoreImage

class FilterPipeline: CIFilter {
    
    // The filters in the order they will be applied
    var filterChain: [CIFilter]
    
    // Allow setting the input image through key value coding
    @objc var inputImage: CIImage?
    
    init(_ filters: [CIFilter]) {
        filterChain = filters
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var outputImage: CIImage? {
        get {

            // Run the `inputImage` through the `filterChain`
            filterChain.reduce(inputImage) {
                image, filter -> CIImage? in
                
                // Apply the current `filter` to the `image`
                filter.setValue(image, forKey: kCIInputImageKey)
                
                // Return the new image
                return filter.outputImage
            }
        }
    }
}

extension CIFilter {
    static func pipeline(_ filters: [CIFilter]) -> FilterPipeline {
        return FilterPipeline(filters)
    }
}
