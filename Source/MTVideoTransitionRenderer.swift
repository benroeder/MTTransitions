//
//  MTVideoTransitionRenderer.swift
//  MTTransitions
//
//  Created by alexiscn on 2020/3/23.
//

import Foundation
import MetalPetal
import VideoToolbox
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

public class MTVideoTransitionRenderer: NSObject {
 
    let effect: MTTransition.Effect
    
    private let transition: MTTransition
    
    public init(effect: MTTransition.Effect) {
        self.effect = effect
        self.transition = effect.transition
        super.init()
    }
    
    public func renderPixelBuffer(_ destinationPixelBuffer: CVPixelBuffer,
                                  usingForegroundSourceBuffer foregroundPixelBuffer: CVPixelBuffer,
                                  andBackgroundSourceBuffer backgroundPixelBuffer: CVPixelBuffer,
                                  forTweenFactor tween: Float) {
        
        let foregroundImage = MTIImage(cvPixelBuffer: foregroundPixelBuffer, alphaType: .alphaIsOne)
        let backgroundImage = MTIImage(cvPixelBuffer: backgroundPixelBuffer, alphaType: .alphaIsOne)
        
        transition.inputImage = foregroundImage.oriented(.downMirrored)
        transition.destImage = backgroundImage.oriented(.downMirrored)
        transition.progress = tween

        if let output = transition.outputImage {
            try? MTTransition.context?.render(output, to: destinationPixelBuffer)
        }
    }
}

#if os(iOS) || os(tvOS)
extension UIImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        guard let image = cgImage else {
            return nil
        }
        self.init(cgImage: image)
    }
}
#elseif os(macOS)
extension NSImage {
    public convenience init?(pixelBuffer: CVPixelBuffer) {
        var cgImage: CGImage?
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        guard let image = cgImage else {
            return nil
        }
        let size = NSSize(width: CGFloat(CVPixelBufferGetWidth(pixelBuffer)),
                          height: CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
        self.init(cgImage: image, size: size)
    }
}
#endif
