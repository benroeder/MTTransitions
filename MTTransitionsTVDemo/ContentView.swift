//
//  ContentView.swift
//  MTTransitionsTVDemo
//
//  Main view for the tvOS demo app
//

import SwiftUI
import MetalKit
import MetalPetal
import MTTransitions

struct ContentView: View {
    @State private var selectedEffectIndex: Int = 0
    @State private var isAnimating = false
    @State private var isCycling = false
    @State private var progress: Float = 0.0
    @State private var fromImage: UIImage?
    @State private var toImage: UIImage?
    @State private var outputImage: UIImage?
    @State private var timer: Timer?

    private let effects = MTTransition.Effect.allCases.filter { $0 != .none }

    var body: some View {
        VStack(spacing: 40) {
            // Top section - Preview and controls
            HStack(spacing: 60) {
                // Transition preview
                ZStack {
                    if let output = outputImage {
                        Image(uiImage: output)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if let from = fromImage {
                        Image(uiImage: from)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Text("Select an effect and press Play")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            )
                    }
                }
                .frame(width: 960, height: 540)
                .cornerRadius(20)

                // Right side - Info and controls
                VStack(spacing: 30) {
                    // Current effect name
                    Text(effects[selectedEffectIndex].description)
                        .font(.title)
                        .frame(width: 300)

                    // Progress indicator
                    ProgressView(value: Double(progress))
                        .frame(width: 300)

                    if isCycling {
                        Text("Effect \(selectedEffectIndex + 1) of \(effects.count)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }

                    // Controls
                    VStack(spacing: 20) {
                        Button(action: playTransition) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Play")
                            }
                            .frame(width: 200)
                        }
                        .disabled(isAnimating || isCycling)

                        Button(
                            action: {
                                if isCycling {
                                    stopCycling()
                                } else {
                                    startCycling()
                                }
                            },
                            label: {
                                HStack {
                                    Image(systemName: isCycling ? "stop.fill" : "repeat")
                                    Text(isCycling ? "Stop" : "Cycle All")
                                }
                                .frame(width: 200)
                            }
                        )
                    }
                    .font(.title3)
                }
                .frame(width: 320)
            }

            // Bottom section - Effect list (horizontal scroll)
            VStack(alignment: .leading, spacing: 10) {
                Text("Effects")
                    .font(.title3)
                    .padding(.leading, 40)

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(0..<effects.count, id: \.self) { index in
                                Button(
                                    action: {
                                        selectedEffectIndex = index
                                        if !isCycling {
                                            progress = 0
                                            updateTransitionFrame()
                                        }
                                    },
                                    label: {
                                        Text(effects[index].description)
                                            .font(.body)
                                            .padding(.horizontal, 20)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(index == selectedEffectIndex ? Color.blue : Color.clear)
                                            )
                                    }
                                )
                                .buttonStyle(.plain)
                                .id(index)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    .onChange(of: selectedEffectIndex) { newIndex in
                        withAnimation {
                            proxy.scrollTo(newIndex, anchor: .center)
                        }
                    }
                }
            }
            .frame(height: 120)
        }
        .padding(40)
        .onAppear {
            loadSampleImages()
        }
    }

    private func loadSampleImages() {
        fromImage = createColoredImage(color: .systemBlue, text: "FROM")
        toImage = createColoredImage(color: .systemOrange, text: "TO")
        progress = 0
        updateTransitionFrame()
    }

    private func createColoredImage(color: UIColor, text: String) -> UIImage {
        let size = CGSize(width: 1280, height: 720)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Fill background
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Draw text
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 120),
                .foregroundColor: UIColor.white
            ]
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: attributes)
        }
    }

    private func playTransition() {
        isAnimating = true
        progress = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            progress += 0.01
            if progress >= 1.0 {
                progress = 1.0
                updateTransitionFrame()
                stopAnimation()
                return
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
        selectedEffectIndex = 0
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
            progress += 0.02
            if progress >= 1.0 {
                progress = 1.0
                updateTransitionFrame()
                timer?.invalidate()
                timer = nil

                // Move to next effect
                selectedEffectIndex += 1
                if selectedEffectIndex >= effects.count {
                    selectedEffectIndex = 0
                }

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

        guard let fromCG = fromImg.cgImage, let toCG = toImg.cgImage else { return }

        let fromMTI = MTIImage(cgImage: fromCG, isOpaque: true).oriented(.downMirrored)
        let toMTI = MTIImage(cgImage: toCG, isOpaque: true).oriented(.downMirrored)

        let transition = effects[selectedEffectIndex].transition
        transition.inputImage = fromMTI
        transition.destImage = toMTI
        transition.progress = progress

        guard let output = transition.outputImage,
              let context = MTTransition.context else {
            return
        }

        do {
            let cgImage = try context.makeCGImage(from: output)
            outputImage = UIImage(cgImage: cgImage)
        } catch {
            print("Render error: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
