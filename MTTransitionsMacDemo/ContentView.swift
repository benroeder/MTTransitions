//
//  ContentView.swift
//  MTTransitionsMacDemo
//
//  Main view for the macOS demo app
//

import SwiftUI
import MetalKit
import MetalPetal
import MTTransitions

struct ContentView: View {
    @State private var selectedEffect: MTTransition.Effect = .fade
    @State private var isAnimating = false
    @State private var isCycling = false
    @State private var progress: Float = 0.0
    @State private var fromImage: NSImage?
    @State private var toImage: NSImage?
    @State private var outputImage: NSImage?
    @State private var timer: Timer?
    @State private var currentEffectIndex: Int = 0

    private let effects = MTTransition.Effect.allCases.filter { $0 != .none }

    var body: some View {
        HSplitView {
            // Left panel - Effect list
            VStack(alignment: .leading, spacing: 0) {
                Text("Transitions")
                    .font(.headline)
                    .padding()

                List(effects, id: \.self, selection: $selectedEffect) { effect in
                    Text(effect.description)
                        .tag(effect)
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 200, maxWidth: 250)

            // Right panel - Preview
            VStack(spacing: 20) {
                // Image display
                ZStack {
                    if let output = outputImage {
                        Image(nsImage: output)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if let from = fromImage {
                        Image(nsImage: from)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Text("Select images to preview transitions")
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)

                // Progress bar
                VStack(spacing: 8) {
                    ProgressView(value: Double(progress))
                        .progressViewStyle(.linear)

                    Text("Progress: \(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Controls
                HStack(spacing: 20) {
                    Button("Load Sample Images") {
                        loadSampleImages()
                    }

                    Button(isAnimating ? "Stop" : "Play Transition") {
                        if isAnimating {
                            stopAnimation()
                        } else {
                            playTransition()
                        }
                    }
                    .disabled(fromImage == nil || toImage == nil || isCycling)

                    Button(isCycling ? "Stop Cycling" : "Cycle All") {
                        if isCycling {
                            stopCycling()
                        } else {
                            startCycling()
                        }
                    }
                    .disabled(fromImage == nil || toImage == nil || isAnimating)

                    Slider(value: Binding(
                        get: { Double(progress) },
                        set: { newValue in
                            if !isAnimating && !isCycling {
                                progress = Float(newValue)
                                updateTransitionFrame()
                            }
                        }
                    ), in: 0...1)
                    .frame(width: 200)
                    .disabled(isAnimating || isCycling || fromImage == nil)
                }
                .padding()

                // Effect name when cycling
                if isCycling {
                    Text("Effect \(currentEffectIndex + 1)/\(effects.count): \(selectedEffect.description)")
                        .font(.headline)
                        .padding(.bottom)
                }
            }
            .padding()
        }
        .frame(minWidth: 800, minHeight: 600)
        .onChange(of: selectedEffect) { _ in
            if fromImage != nil && toImage != nil {
                updateTransitionFrame()
            }
        }
    }

    private func loadSampleImages() {
        // Create sample colored images
        fromImage = createColoredImage(color: .systemBlue, text: "FROM")
        toImage = createColoredImage(color: .systemOrange, text: "TO")
        progress = 0
        updateTransitionFrame()
    }

    private func createColoredImage(color: NSColor, text: String) -> NSImage {
        let size = NSSize(width: 640, height: 480)
        let image = NSImage(size: size)
        image.lockFocus()

        // Fill background
        color.setFill()
        NSRect(origin: .zero, size: size).fill()

        // Draw text
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 72),
            .foregroundColor: NSColor.white
        ]
        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        text.draw(in: textRect, withAttributes: attributes)

        image.unlockFocus()
        return image
    }

    private func playTransition() {
        isAnimating = true
        progress = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            progress += 0.01
            if progress >= 1.0 {
                progress = 1.0
                stopAnimation()
            }
            updateTransitionFrame()
        }
    }

    private func stopAnimation() {
        isAnimating = false
        timer?.invalidate()
        timer = nil
    }

    private func startCycling() {
        isCycling = true
        currentEffectIndex = 0
        selectedEffect = effects[currentEffectIndex]
        playCycleTransition()
    }

    private func stopCycling() {
        isCycling = false
        timer?.invalidate()
        timer = nil
    }

    private func playCycleTransition() {
        progress = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            progress += 0.02  // Faster for cycling
            if progress >= 1.0 {
                progress = 1.0
                updateTransitionFrame()
                timer?.invalidate()
                timer = nil

                // Move to next effect
                currentEffectIndex += 1
                if currentEffectIndex >= effects.count {
                    currentEffectIndex = 0
                }
                selectedEffect = effects[currentEffectIndex]

                // Brief pause then start next
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if isCycling {
                        playCycleTransition()
                    }
                }
                return
            }
            updateTransitionFrame()
        }
    }

    private func updateTransitionFrame() {
        guard let fromImg = fromImage, let toImg = toImage else { return }

        guard let fromCG = fromImg.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let toCG = toImg.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return
        }

        let fromMTI = MTIImage(cgImage: fromCG, isOpaque: true).oriented(.downMirrored)
        let toMTI = MTIImage(cgImage: toCG, isOpaque: true).oriented(.downMirrored)

        let transition = selectedEffect.transition
        transition.inputImage = fromMTI
        transition.destImage = toMTI
        transition.progress = progress

        guard let output = transition.outputImage,
              let context = MTTransition.context else {
            return
        }

        do {
            let cgImage = try context.makeCGImage(from: output)
            outputImage = NSImage(cgImage: cgImage, size: fromImg.size)
        } catch {
            print("Render error: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
