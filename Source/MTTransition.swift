//
//  MTTransition.swift
//  MTTransitions
//
//  Created by alexiscn on 2019/1/24.
//

import Foundation
import MetalPetal
#if os(iOS) || os(tvOS)
import QuartzCore
#endif

/// The callback when transition updated
public typealias MTTransitionUpdater = (_ image: MTIImage) -> Void

/// The callback when transition completed
public typealias MTTransitionCompletion = (_ finished: Bool) -> Void

public class MTTransition: NSObject, MTIUnaryFilter {

    public static let context = try? MTIContext(device: MTLCreateSystemDefaultDevice()!)

    public override init() { }

    public var inputImage: MTIImage?

    public var destImage: MTIImage?

    public var outputPixelFormat: MTLPixelFormat = .invalid

    public var progress: Float = 0.0

    /// The duration of the transition. 1.2 second by default.
    public var duration: TimeInterval = 1.2

    var completion: MTTransitionCompletion?

    private var updater: MTTransitionUpdater?
    private var startTime: TimeInterval?

    #if os(iOS) || os(tvOS)
    private weak var displayLink: CADisplayLink?
    #elseif os(macOS)
    private var timer: Timer?
    #endif

    // Subclasses must provide fragmentName
    var fragmentName: String { return "" }
    var parameters: [String: Any] { return [:] }
    var samplers: [String: String] { return [:] }

    public var outputImage: MTIImage? {
        guard let input = inputImage, let dest = destImage else {
            return inputImage
        }
        var images: [MTIImage] = [input, dest]
        let outputDescriptors = [ MTIRenderPassOutputDescriptor(dimensions: MTITextureDimensions(cgSize: input.size), pixelFormat: outputPixelFormat)]

        for key in samplers.keys {
            if let name = samplers[key], let samplerImage = samplerImage(name: name) {
                images.append(samplerImage)
            }
        }

        var params = parameters
        params["ratio"] = Float(input.size.width / input.size.height)
        params["progress"] = progress

        let output = kernel.apply(toInputImages: images, parameters: params, outputDescriptors: outputDescriptors).first
        return output
    }

    var kernel: MTIRenderPipelineKernel {
        let vertexDescriptor = MTIFunctionDescriptor(name: MTIFilterPassthroughVertexFunctionName)
        let fragmentDescriptor = MTIFunctionDescriptor(name: fragmentName, libraryURL: MTIDefaultLibraryURLForBundle(Bundle(for: MTTransition.self)))
        let kernel = MTIRenderPipelineKernel(vertexFunctionDescriptor: vertexDescriptor, fragmentFunctionDescriptor: fragmentDescriptor)
        return kernel
    }

    private func samplerImage(name: String) -> MTIImage? {
        let bundle = Bundle(for: MTTransition.self)
        guard let bundleUrl = bundle.url(forResource: "Assets", withExtension: "bundle"),
            let resourceBundle = Bundle(url: bundleUrl) else {
            return nil
        }

        if let imageUrl = resourceBundle.url(forResource: name, withExtension: nil) {
            let ciImage = CIImage(contentsOf: imageUrl)
            return MTIImage(ciImage: ciImage!, isOpaque: true)
        }
        return nil
    }

    #if os(iOS) || os(tvOS)
    public func transition(from fromImage: MTIImage, to toImage: MTIImage, updater: @escaping MTTransitionUpdater, completion: MTTransitionCompletion?) {
        self.inputImage = fromImage
        self.destImage = toImage
        self.updater = updater
        self.completion = completion
        self.startTime = nil
        let link = CADisplayLink(target: self, selector: #selector(render(sender:)))
        link.add(to: .main, forMode: .common)
        self.displayLink = link
    }

    @objc private func render(sender: CADisplayLink) {
        let startTime: CFTimeInterval
        if let time = self.startTime {
            startTime = time
        } else {
            startTime = sender.timestamp
            self.startTime = startTime
        }

        let progress = (sender.timestamp - startTime) / duration
        if progress > 1 {
            self.progress = 1.0
            if let image = outputImage {
                self.updater?(image)
            }
            self.displayLink?.invalidate()
            self.displayLink = nil
            self.updater = nil
            self.completion?(true)
            self.completion = nil
            return
        }

        self.progress = Float(progress)
        if let image = outputImage {
            self.updater?(image)
        }
    }
    #elseif os(macOS)
    public func transition(from fromImage: MTIImage, to toImage: MTIImage, updater: @escaping MTTransitionUpdater, completion: MTTransitionCompletion?) {
        self.inputImage = fromImage
        self.destImage = toImage
        self.updater = updater
        self.completion = completion
        self.startTime = CACurrentMediaTime()

        // Use Timer on macOS (60 fps)
        let timer = Timer(timeInterval: 1.0/60.0, repeats: true) { [weak self] timer in
            self?.renderFrame()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func renderFrame() {
        guard let startTime = self.startTime else { return }

        let elapsed = CACurrentMediaTime() - startTime
        let progress = elapsed / duration

        if progress > 1 {
            self.progress = 1.0
            if let image = outputImage {
                self.updater?(image)
            }
            self.timer?.invalidate()
            self.timer = nil
            self.updater = nil
            self.completion?(true)
            self.completion = nil
            return
        }

        self.progress = Float(progress)
        if let image = outputImage {
            self.updater?(image)
        }
    }
    #endif

    public func cancel() {
        #if os(iOS) || os(tvOS)
        self.displayLink?.invalidate()
        self.displayLink = nil
        #elseif os(macOS)
        self.timer?.invalidate()
        self.timer = nil
        #endif
        self.completion?(false)
    }
}
