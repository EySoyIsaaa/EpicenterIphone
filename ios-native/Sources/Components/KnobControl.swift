import SwiftUI

/// Perilla metálica estilo "hardware" (equivalente nativa del KnobControl de la web).
/// Arco segmentado rojo, cuerpo biselado, aguja y arrastre vertical para cambiar el valor.
struct KnobControl: View {
    let label: String
    let value: Double
    let range: ClosedRange<Double>
    var unit: String = ""
    var step: Double = 1
    var disabled: Bool = false
    var size: CGFloat = 92
    var featured: Bool = false
    let onChange: (Double) -> Void

    @State private var dragStartValue: Double? = nil

    private var normalized: Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        return min(max((value - range.lowerBound) / span, 0), 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            if featured {
                Text("\(Int(value.rounded()))\(unit)")
                    .font(.system(size: 30, weight: .heavy).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
            }
            dial
                .frame(width: size, height: size)
                .opacity(disabled ? 0.4 : 1)
                .contentShape(Circle())
                .highPriorityGesture(drag)   // gana al scroll vertical del contenedor
            VStack(spacing: 2) {
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .kerning(1.4)   // tracking(_:) es iOS 16; kerning es iOS 13+
                    .foregroundStyle(Theme.textMuted)
                if !featured {
                    Text("\(Int(value.rounded()))\(unit)")
                        .font(.system(size: 14, weight: .bold).monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
    }

    private var dial: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let radius = s * 0.39
            let ringRadius = s * 0.43
            let startRad = 135.0 * .pi / 180.0
            let endRad = 405.0 * .pi / 180.0
            let sweep = endRad - startRad
            let lineW: CGFloat = featured ? 5.0 : 3.5

            // Arco exterior segmentado (rojo hasta el valor, gris el resto).
            let segments = 34
            for i in 0..<segments {
                let segStart = startRad + (Double(i) / Double(segments)) * sweep
                let segEnd = segStart + (sweep / Double(segments)) * 0.56
                var path = Path()
                path.addArc(center: center, radius: ringRadius,
                            startAngle: .radians(segStart), endAngle: .radians(segEnd), clockwise: false)
                let filled = Double(i) / Double(segments) <= normalized && !disabled
                context.stroke(path, with: .color(filled ? Theme.red : Color(white: 0.18)),
                               style: StrokeStyle(lineWidth: lineW, lineCap: .round))
            }

            // Cuerpo biselado (degradado radial metálico).
            let bodyRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            let bevel = GraphicsContext.Shading.radialGradient(
                Gradient(colors: [Color(white: 0.35), Color(white: 0.16), Color(white: 0.07), Color(white: 0.19), Color(white: 0.03)]),
                center: CGPoint(x: center.x - radius * 0.3, y: center.y - radius * 0.4),
                startRadius: 2, endRadius: radius + 7)
            context.fill(Path(ellipseIn: bodyRect), with: bevel)

            // Cara interior con brillo diagonal.
            let innerRect = bodyRect.insetBy(dx: 8, dy: 8)
            context.fill(Path(ellipseIn: innerRect), with: .linearGradient(
                Gradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.02), Color.black.opacity(0.28), Color.white.opacity(0.06)]),
                startPoint: CGPoint(x: innerRect.minX, y: innerRect.minY),
                endPoint: CGPoint(x: innerRect.maxX, y: innerRect.maxY)))

            // Aguja roja.
            let progressAngle = startRad + normalized * sweep
            let cosA = CGFloat(cos(progressAngle))
            let sinA = CGFloat(sin(progressAngle))
            let innerR = radius * 0.22
            let outerR = radius - 12
            var pointer = Path()
            pointer.move(to: CGPoint(x: center.x + cosA * innerR, y: center.y + sinA * innerR))
            pointer.addLine(to: CGPoint(x: center.x + cosA * outerR, y: center.y + sinA * outerR))
            context.stroke(pointer, with: .color(disabled ? Color(white: 0.35) : Theme.red),
                           style: StrokeStyle(lineWidth: featured ? 4 : 2.6, lineCap: .round))

            // Núcleo.
            let hubR: CGFloat = featured ? 5.5 : 4.2
            context.fill(Path(ellipseIn: CGRect(x: center.x - hubR, y: center.y - hubR, width: hubR * 2, height: hubR * 2)),
                         with: .color(Color(white: 0.07)))
        }
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { g in
                guard !disabled else { return }
                let start = dragStartValue ?? value
                if dragStartValue == nil { dragStartValue = start }
                let span = range.upperBound - range.lowerBound
                let sensitivity = span / 150.0
                var newValue = start + Double(-g.translation.height) * sensitivity
                newValue = (newValue / step).rounded() * step
                newValue = min(max(newValue, range.lowerBound), range.upperBound)
                onChange(newValue)
            }
            .onEnded { _ in dragStartValue = nil }
    }
}
