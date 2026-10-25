import SwiftUI
import UIKit
import QuartzCore

/// Bass Impact rendered by Core Animation at a preferred 60 fps. The layers are
/// built once; the render server animates transforms/opacity without per-frame
/// SwiftUI layout, independent state updates, or animated full-screen blur.
struct SplashView: View {
    let onFinish: () -> Void

    var body: some View {
        SplashAnimation(onFinish: onFinish).ignoresSafeArea()
    }
}

private struct SplashAnimation: UIViewRepresentable {
    let onFinish: () -> Void

    func makeUIView(context: Context) -> BassImpactView {
        let view = BassImpactView()
        view.onFinish = onFinish
        return view
    }

    func updateUIView(_ uiView: BassImpactView, context: Context) {
        uiView.onFinish = onFinish
    }

    static func dismantleUIView(_ uiView: BassImpactView, coordinator: ()) {
        uiView.stop()
    }
}

private final class BassImpactView: UIView {
    var onFinish: (() -> Void)?
    private let content = CALayer()
    private var started = false
    private var finishing = false
    private var automaticFinish: DispatchWorkItem?
    private var completion: DispatchWorkItem?
    private let red = UIColor(red: 1, green: 0.063, blue: 0.165, alpha: 1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        layer.addSublayer(content)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(finish)))
        isAccessibilityElement = true
        accessibilityLabel = L("Omitir animación de inicio", "Skip opening animation")
        accessibilityTraits = .button
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard !started, bounds.width > 0, bounds.height > 0 else { return }
        started = true
        content.frame = bounds
        buildLayers()
        let work = DispatchWorkItem { [weak self] in self?.finish() }
        automaticFinish = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.08, execute: work)
    }

    private func buildLayers() {
        let stage = min(bounds.width * 0.62, 280)
        let center = CGPoint(x: bounds.midX, y: bounds.midY - 30)
        let reduceMotion = UIAccessibility.isReduceMotionEnabled

        let bloom = CAGradientLayer()
        bloom.type = .radial
        bloom.colors = [red.withAlphaComponent(0.42).cgColor, UIColor.clear.cgColor]
        bloom.startPoint = CGPoint(x: 0.5, y: 0.5)
        bloom.endPoint = CGPoint(x: 1, y: 1)
        bloom.bounds = CGRect(x: 0, y: 0, width: stage * 1.1, height: stage * 1.1)
        bloom.position = center
        content.addSublayer(bloom)

        if !reduceMotion {
            for delay in [0.20, 0.43, 0.66] {
                let ring = CAShapeLayer()
                let size = stage * 0.42
                ring.bounds = CGRect(x: 0, y: 0, width: size, height: size)
                ring.position = center
                ring.path = UIBezierPath(ovalIn: ring.bounds.insetBy(dx: 1, dy: 1)).cgPath
                ring.strokeColor = red.withAlphaComponent(0.8).cgColor
                ring.fillColor = UIColor.clear.cgColor
                ring.lineWidth = 2
                ring.opacity = 0
                content.addSublayer(ring)
                animate(ring, keyPath: "transform.scale", values: [0.12, 2.9], duration: 1.9, delay: delay)
                animate(ring, keyPath: "opacity", values: [0, 0.9, 0], times: [0, 0.13, 1], duration: 1.9, delay: delay)
            }
            animate(bloom, keyPath: "opacity", values: [0, 1], duration: 1.1, delay: 0.3)
            animate(bloom, keyPath: "transform.scale", values: [0.4, 1.08], duration: 1.1, delay: 0.3)
        }

        let logo = CALayer()
        logo.contents = UIImage(named: "EpicenterLogo")?.cgImage
        logo.contentsGravity = .resizeAspect
        logo.bounds = CGRect(x: 0, y: 0, width: stage * 0.68, height: stage * 0.68)
        logo.position = center
        content.addSublayer(logo)
        if !reduceMotion {
            animate(logo, keyPath: "opacity", values: [0, 1], duration: 0.45, delay: 0.4)
            animate(logo, keyPath: "transform.scale", values: [0.62, 1.05, 1], times: [0, 0.7, 1], duration: 0.7, delay: 0.4)
        }

        if !reduceMotion {
            let sweep = CAGradientLayer()
            sweep.colors = [UIColor.clear.cgColor, red.cgColor, UIColor.clear.cgColor]
            sweep.startPoint = CGPoint(x: 0, y: 0.5)
            sweep.endPoint = CGPoint(x: 1, y: 0.5)
            sweep.bounds = CGRect(x: 0, y: 0, width: stage * 0.88, height: 2)
            sweep.position = CGPoint(x: center.x, y: center.y + stage * 0.30)
            sweep.opacity = 0
            content.addSublayer(sweep)
            animate(sweep, keyPath: "transform.scale.x", values: [0, 1.02], duration: 0.45, delay: 1.2)
            animate(sweep, keyPath: "opacity", values: [0, 1, 0], times: [0, 0.35, 1], duration: 1.3, delay: 1.2)
        }

        for index in 0..<28 {
            let bar = CAGradientLayer()
            bar.colors = [red.cgColor, red.withAlphaComponent(0.35).cgColor]
            bar.bounds = CGRect(x: 0, y: 0, width: 3, height: 34)
            bar.anchorPoint = CGPoint(x: 0.5, y: 1)
            bar.position = CGPoint(x: center.x + CGFloat(index) * 6 - 81, y: center.y + stage / 2 + 64)
            bar.cornerRadius = 1.5
            content.addSublayer(bar)
            let peak = 0.36 + Double((index * 37) % 52) / 100
            if reduceMotion {
                bar.transform = CATransform3DMakeScale(1, CGFloat(peak), 1)
            } else {
                let delay = 0.95 + Double(index % 7) * 0.04
                animate(bar, keyPath: "opacity", values: [0, 1], duration: 0.3, delay: delay)
                animate(bar, keyPath: "transform.scale.y", values: [0.08, peak, 0.15], times: [0, 0.5, 1], duration: 1.3, delay: delay, repeats: true)
            }
        }

        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        addText("v\(version) (\(build))", y: bounds.height - 102, size: 11, opacity: 1)
        addText("BASS RECONSTRUCTION TECHNOLOGY", y: bounds.height - 72, size: 10, opacity: 0.5)
    }

    private func addText(_ text: String, y: CGFloat, size: CGFloat, opacity: Float) {
        let label = CATextLayer()
        label.string = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: size, weight: .semibold),
            .foregroundColor: UIColor.white,
            .kern: size == 10 ? 2 : 0,
        ])
        label.contentsScale = UIScreen.main.scale
        label.alignmentMode = .center
        label.frame = CGRect(x: 12, y: y, width: bounds.width - 24, height: 24)
        label.opacity = opacity
        content.addSublayer(label)
        if !UIAccessibility.isReduceMotionEnabled {
            animate(label, keyPath: "opacity", values: [0, Double(opacity)], duration: 0.7, delay: 1)
        }
    }

    private func animate(_ target: CALayer, keyPath: String, values: [Double], times: [Double]? = nil,
                         duration: Double, delay: Double = 0, repeats: Bool = false) {
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.values = values.map { NSNumber(value: $0) }
        animation.keyTimes = (times ?? [0, 1]).map { NSNumber(value: $0) }
        animation.duration = duration
        animation.beginTime = CACurrentMediaTime() + delay
        animation.fillMode = .both
        animation.isRemovedOnCompletion = false
        animation.repeatCount = repeats ? .infinity : 0
        animation.calculationMode = .linear
        animation.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 60, preferred: 60)
        target.add(animation, forKey: keyPath)
    }

    @objc private func finish() {
        guard !finishing else { return }
        finishing = true
        automaticFinish?.cancel()
        let duration = UIAccessibility.isReduceMotionEnabled ? 0.15 : 0.52
        animate(content, keyPath: "opacity", values: [1, 0], duration: duration)
        let work = DispatchWorkItem { [weak self] in self?.onFinish?() }
        completion = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }

    override func accessibilityActivate() -> Bool { finish(); return true }

    func stop() {
        automaticFinish?.cancel()
        completion?.cancel()
        content.removeAllAnimations()
        content.sublayers?.forEach { $0.removeAllAnimations() }
    }
}
