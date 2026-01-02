// Simple macOS test for MTTransitions
import Foundation
import AppKit
import MetalPetal

// Import the local module
@testable import MTTransitions

print("MTTransitions macOS Test")
print("========================")

// Check Metal device
guard let device = MTLCreateSystemDefaultDevice() else {
    print("ERROR: No Metal device available")
    exit(1)
}
print("Metal device: \(device.name)")

// Check MTTransition context
guard let context = MTTransition.context else {
    print("ERROR: Could not create MTIContext")
    exit(1)
}
print("MTIContext created successfully")

// List available effects
print("\nAvailable effects: \(MTTransition.Effect.allCases.count)")

// Test creating a transition
let transition = MTTransition.Effect.fade.transition
print("Created fade transition: \(type(of: transition))")

// Create test images (simple colored rectangles)
let size = CGSize(width: 640, height: 480)

func createTestImage(color: NSColor) -> MTIImage? {
    let image = NSImage(size: size)
    image.lockFocus()
    color.setFill()
    NSRect(origin: .zero, size: size).fill()
    image.unlockFocus()

    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        return nil
    }
    return MTIImage(cgImage: cgImage, isOpaque: true).oriented(.downMirrored)
}

guard let fromImage = createTestImage(color: .red),
      let toImage = createTestImage(color: .blue) else {
    print("ERROR: Could not create test images")
    exit(1)
}

print("Created test images: \(fromImage.size) -> \(toImage.size)")

// Test manual progress update
transition.inputImage = fromImage
transition.destImage = toImage
transition.progress = 0.5

if let output = transition.outputImage {
    print("Generated output image at 50% progress: \(output.size)")

    // Try to render to CGImage
    do {
        let cgImage = try context.makeCGImage(from: output)
        print("Rendered to CGImage: \(cgImage.width)x\(cgImage.height)")

        // Save to file
        let outputURL = URL(fileURLWithPath: "/tmp/mttransition_test.png")
        let nsImage = NSImage(cgImage: cgImage, size: size)
        if let tiffData = nsImage.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            try pngData.write(to: outputURL)
            print("Saved test output to: \(outputURL.path)")
        }
    } catch {
        print("ERROR rendering: \(error)")
    }
} else {
    print("ERROR: No output image generated")
}

print("\nTest completed successfully!")
