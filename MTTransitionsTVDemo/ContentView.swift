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

// MARK: - Main Tab View

struct ContentView: View {
    var body: some View {
        TabView {
            ImageTransitionView()
                .tabItem {
                    Image(systemName: "photo.on.rectangle")
                    Text("Image")
                }

            UIViewTransitionView()
                .tabItem {
                    Image(systemName: "rectangle.on.rectangle")
                    Text("UIView")
                }

            ViewControllerTransitionView()
                .tabItem {
                    Image(systemName: "rectangle.stack")
                    Text("ViewController")
                }
        }
    }
}

// MARK: - Image Transition Demo

struct ImageTransitionView: View {
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
            HStack(spacing: 60) {
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

                VStack(spacing: 30) {
                    Text(effects[selectedEffectIndex].description)
                        .font(.title)
                        .frame(width: 300)

                    ProgressView(value: Double(progress))
                        .frame(width: 300)

                    if isCycling {
                        Text("Effect \(selectedEffectIndex + 1) of \(effects.count)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }

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
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))

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

                selectedEffectIndex += 1
                if selectedEffectIndex >= effects.count {
                    selectedEffectIndex = 0
                }

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

// MARK: - UIView Transition Demo

struct UIViewTransitionView: View {
    var body: some View {
        UIViewTransitionWrapper()
            .edgesIgnoringSafeArea(.all)
    }
}

struct UIViewTransitionWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewTransitionDemoController {
        return UIViewTransitionDemoController()
    }

    func updateUIViewController(_ uiViewController: UIViewTransitionDemoController, context: Context) {}
}

class UIViewTransitionDemoController: UIViewController {
    private var demoLabel: UILabel!
    private var transitionButton: UIButton!
    private var cycleButton: UIButton!
    private var effectPicker: UISegmentedControl!
    private var effectLabel: UILabel!
    private var isStateA = true
    private var selectedEffect: MTTransition.Effect = .burn
    private var isCycling = false
    private var cycleIndex = 0

    private let effects = MTTransition.Effect.allCases.filter { $0 != .none }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
    }

    private func setupUI() {
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "UIView Transition Demo"
        titleLabel.font = .systemFont(ofSize: 48, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        // Demo container
        let container = UIView()
        container.backgroundColor = UIColor.darkGray.withAlphaComponent(0.5)
        container.layer.cornerRadius = 20
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        // Demo label that will transition
        demoLabel = UILabel()
        demoLabel.text = "State A"
        demoLabel.font = .systemFont(ofSize: 72, weight: .bold)
        demoLabel.textColor = .systemBlue
        demoLabel.textAlignment = .center
        demoLabel.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(demoLabel)

        // Effect label (shows current effect name)
        effectLabel = UILabel()
        effectLabel.text = effects[0].description
        effectLabel.font = .systemFont(ofSize: 32, weight: .medium)
        effectLabel.textColor = .white
        effectLabel.textAlignment = .center
        effectLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(effectLabel)

        // Buttons stack
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 40
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)

        // Transition button
        transitionButton = UIButton(type: .system)
        transitionButton.setTitle("Do Transition", for: .normal)
        transitionButton.titleLabel?.font = .systemFont(ofSize: 32, weight: .semibold)
        transitionButton.addTarget(self, action: #selector(doTransition), for: .primaryActionTriggered)
        buttonStack.addArrangedSubview(transitionButton)

        // Cycle button
        cycleButton = UIButton(type: .system)
        cycleButton.setTitle("Cycle All", for: .normal)
        cycleButton.titleLabel?.font = .systemFont(ofSize: 32, weight: .semibold)
        cycleButton.addTarget(self, action: #selector(toggleCycle), for: .primaryActionTriggered)
        buttonStack.addArrangedSubview(cycleButton)

        // Description
        let descLabel = UILabel()
        descLabel.text = "This demonstrates MTTransition.transition(with:effect:animations:) on a UIView"
        descLabel.font = .systemFont(ofSize: 24)
        descLabel.textColor = .gray
        descLabel.textAlignment = .center
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            container.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            container.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            container.widthAnchor.constraint(equalToConstant: 600),
            container.heightAnchor.constraint(equalToConstant: 300),

            demoLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            demoLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            effectLabel.topAnchor.constraint(equalTo: container.bottomAnchor, constant: 30),
            effectLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            buttonStack.topAnchor.constraint(equalTo: effectLabel.bottomAnchor, constant: 30),
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            descLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            descLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func doTransition() {
        transitionButton.isEnabled = false

        let effect = selectedEffect.transition

        MTTransition.transition(with: demoLabel, effect: effect, animations: {
            if self.isStateA {
                self.demoLabel.text = "State B"
                self.demoLabel.textColor = .systemOrange
            } else {
                self.demoLabel.text = "State A"
                self.demoLabel.textColor = .systemBlue
            }
            self.isStateA.toggle()
        }) { _ in
            self.transitionButton.isEnabled = true
        }
    }

    @objc private func toggleCycle() {
        if isCycling {
            stopCycling()
        } else {
            startCycling()
        }
    }

    private func startCycling() {
        isCycling = true
        cycleIndex = 0
        transitionButton.isEnabled = false
        cycleButton.setTitle("Stop", for: .normal)
        runNextCycleTransition()
    }

    private func stopCycling() {
        isCycling = false
        transitionButton.isEnabled = true
        cycleButton.setTitle("Cycle All", for: .normal)
    }

    private func runNextCycleTransition() {
        guard isCycling else { return }

        selectedEffect = effects[cycleIndex]
        effectLabel.text = "\(selectedEffect.description) (\(cycleIndex + 1)/\(effects.count))"

        let effect = selectedEffect.transition

        MTTransition.transition(with: demoLabel, effect: effect, animations: {
            if self.isStateA {
                self.demoLabel.text = "State B"
                self.demoLabel.textColor = .systemOrange
            } else {
                self.demoLabel.text = "State A"
                self.demoLabel.textColor = .systemBlue
            }
            self.isStateA.toggle()
        }) { _ in
            self.cycleIndex += 1
            if self.cycleIndex >= self.effects.count {
                self.cycleIndex = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.runNextCycleTransition()
            }
        }
    }
}

// MARK: - ViewController Transition Demo

struct ViewControllerTransitionView: View {
    var body: some View {
        ViewControllerTransitionWrapper()
            .edgesIgnoringSafeArea(.all)
    }
}

struct ViewControllerTransitionWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let rootVC = ViewControllerTransitionDemoController()
        let navController = UINavigationController(rootViewController: rootVC)
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

class ViewControllerTransitionDemoController: UIViewController {
    private var pushButton: UIButton!
    private var presentButton: UIButton!
    private var cycleButton: UIButton!
    private var effectLabel: UILabel!
    private var selectedEffect: MTTransition.Effect = .displacement
    private lazy var pushTransition = MTViewControllerTransition(effect: selectedEffect)
    private lazy var presentTransition = MTViewControllerTransition(effect: selectedEffect)
    private var isCycling = false
    private var cycleIndex = 0
    private var usePush = true  // Alternate between push and present

    private let effects = MTTransition.Effect.allCases.filter { $0 != .none }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ViewController Transitions"
        view.backgroundColor = .black
        setupUI()
    }

    private func setupUI() {
        // Description
        let descLabel = UILabel()
        descLabel.text = "Demonstrates MTViewControllerTransition for push and present animations"
        descLabel.font = .systemFont(ofSize: 24)
        descLabel.textColor = .gray
        descLabel.textAlignment = .center
        descLabel.numberOfLines = 0
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(descLabel)

        // Effect label
        effectLabel = UILabel()
        effectLabel.text = effects[0].description
        effectLabel.font = .systemFont(ofSize: 36, weight: .medium)
        effectLabel.textColor = .white
        effectLabel.textAlignment = .center
        effectLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(effectLabel)

        // Button stack
        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.spacing = 40
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)

        // Push button
        pushButton = UIButton(type: .system)
        pushButton.setTitle("Push", for: .normal)
        pushButton.titleLabel?.font = .systemFont(ofSize: 32, weight: .semibold)
        pushButton.addTarget(self, action: #selector(doPush), for: .primaryActionTriggered)
        buttonStack.addArrangedSubview(pushButton)

        // Present button
        presentButton = UIButton(type: .system)
        presentButton.setTitle("Present", for: .normal)
        presentButton.titleLabel?.font = .systemFont(ofSize: 32, weight: .semibold)
        presentButton.addTarget(self, action: #selector(doPresent), for: .primaryActionTriggered)
        buttonStack.addArrangedSubview(presentButton)

        // Cycle button
        cycleButton = UIButton(type: .system)
        cycleButton.setTitle("Cycle All", for: .normal)
        cycleButton.titleLabel?.font = .systemFont(ofSize: 32, weight: .semibold)
        cycleButton.addTarget(self, action: #selector(toggleCycle), for: .primaryActionTriggered)
        buttonStack.addArrangedSubview(cycleButton)

        NSLayoutConstraint.activate([
            descLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            descLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            descLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            effectLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            effectLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            buttonStack.topAnchor.constraint(equalTo: effectLabel.bottomAnchor, constant: 60),
            buttonStack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func doPush() {
        let destinationVC = DestinationViewController()
        destinationVC.titleText = "Pushed View"
        destinationVC.color = .systemBlue
        navigationController?.delegate = self
        navigationController?.pushViewController(destinationVC, animated: true)
    }

    @objc private func doPresent() {
        let destinationVC = DestinationViewController()
        destinationVC.titleText = "Presented View"
        destinationVC.color = .systemGreen
        destinationVC.showDismissButton = true
        destinationVC.modalPresentationStyle = .fullScreen
        destinationVC.transitioningDelegate = self
        present(destinationVC, animated: true)
    }

    @objc private func toggleCycle() {
        if isCycling {
            stopCycling()
        } else {
            startCycling()
        }
    }

    private func startCycling() {
        isCycling = true
        cycleIndex = 0
        usePush = true
        pushButton.isEnabled = false
        presentButton.isEnabled = false
        cycleButton.setTitle("Stop", for: .normal)
        runNextCycleTransition()
    }

    private func stopCycling() {
        isCycling = false
        pushButton.isEnabled = true
        presentButton.isEnabled = true
        cycleButton.setTitle("Cycle All", for: .normal)
    }

    private func runNextCycleTransition() {
        guard isCycling else { return }

        selectedEffect = effects[cycleIndex]
        pushTransition = MTViewControllerTransition(effect: selectedEffect)
        presentTransition = MTViewControllerTransition(effect: selectedEffect)

        let mode = usePush ? "Push" : "Present"
        effectLabel.text = "\(selectedEffect.description) - \(mode) (\(cycleIndex + 1)/\(effects.count))"

        let destinationVC = DestinationViewController()
        destinationVC.color = usePush ? .systemBlue : .systemGreen
        destinationVC.titleText = "\(selectedEffect.description)"
        destinationVC.onDismiss = { [weak self] in
            self?.continueCycle()
        }

        if usePush {
            destinationVC.autoDismissAfter = 1.0
            navigationController?.delegate = self
            navigationController?.pushViewController(destinationVC, animated: true)
        } else {
            destinationVC.showDismissButton = false
            destinationVC.autoDismissAfter = 1.0
            destinationVC.modalPresentationStyle = .fullScreen
            destinationVC.transitioningDelegate = self
            present(destinationVC, animated: true)
        }
    }

    private func continueCycle() {
        guard isCycling else { return }

        usePush.toggle()
        if usePush {
            cycleIndex += 1
            if cycleIndex >= effects.count {
                cycleIndex = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.runNextCycleTransition()
        }
    }
}

extension ViewControllerTransitionDemoController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        if operation == .push {
            return pushTransition
        }
        return nil
    }
}

extension ViewControllerTransitionDemoController: UIViewControllerTransitioningDelegate {
    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        return presentTransition
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presentTransition
    }
}

class DestinationViewController: UIViewController {
    var titleText: String = "Destination"
    var color: UIColor = .systemBlue
    var showDismissButton = false
    var autoDismissAfter: TimeInterval?
    var onDismiss: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = color

        let label = UILabel()
        label.text = titleText
        label.font = .systemFont(ofSize: 72, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        if showDismissButton {
            let dismissButton = UIButton(type: .system)
            dismissButton.setTitle("Dismiss", for: .normal)
            dismissButton.titleLabel?.font = .systemFont(ofSize: 32, weight: .semibold)
            dismissButton.setTitleColor(.white, for: .normal)
            dismissButton.addTarget(self, action: #selector(dismissSelf), for: .primaryActionTriggered)
            dismissButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(dismissButton)

            NSLayoutConstraint.activate([
                dismissButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                dismissButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 60)
            ])
        }

        title = titleText
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let delay = autoDismissAfter {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.autoDismiss()
            }
        }
    }

    private func autoDismiss() {
        if navigationController != nil {
            navigationController?.popViewController(animated: true)
            onDismiss?()
        } else {
            dismiss(animated: true) {
                self.onDismiss?()
            }
        }
    }

    @objc private func dismissSelf() {
        dismiss(animated: true) {
            self.onDismiss?()
        }
    }
}

#Preview {
    ContentView()
}
