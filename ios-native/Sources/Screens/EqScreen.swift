import SwiftUI

/// Ecualizador de 31 bandas (pestaña EQ). Curva de respuesta + faders verticales,
/// igual que el visualizador del web, con Auto-EQ independiente.
struct EqScreen: View {
    @ObservedObject private var audio = AudioService.shared

    private static let range: ClosedRange<Double> = -8...8
    private static let freqs: [Double] = [
        20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630,
        800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000, 20000,
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 14) {
                    Toggle(isOn: Binding(get: { audio.eqEnabled }, set: { audio.setEqEnabled($0) })) {
                        Text("Ecualizador activo").font(.subheadline).foregroundStyle(Theme.textPrimary)
                    }
                    .tint(Theme.red)
                    .padding(.horizontal)

                    // Curva de respuesta (como el web).
                    VStack(spacing: 6) {
                        HStack {
                            Text("RESPUESTA").font(.system(size: 10, weight: .black)).kerning(1.5)
                            Spacer()
                            Text(audio.eqEnabled ? "Live" : "Bypass").font(.system(size: 10, weight: .black)).kerning(1.5)
                        }
                        .foregroundStyle(Theme.textMuted)
                        EQCurve(gains: audio.eqBands, range: EqScreen.range, enabled: audio.eqEnabled)
                            .frame(height: 96)
                    }
                    .padding(12)
                    .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)

                    autoEqBanner.padding(.horizontal)

                    HStack {
                        Text("+8 dB"); Spacer(); Text("0"); Spacer(); Text("-8 dB")
                    }
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal)

                    // Faders verticales (scroll horizontal).
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 14) {
                            ForEach(0..<31, id: \.self) { i in
                                VerticalFader(
                                    label: freqLabel(EqScreen.freqs[i]),
                                    value: audio.eqBands[i],
                                    range: EqScreen.range,
                                    enabled: audio.eqEnabled
                                ) { audio.setEqBand(i, $0) }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                    }
                    .opacity(audio.eqEnabled ? 1 : 0.5)

                    Button("Restablecer") { audio.resetEq() }
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.bottom, 6)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Ecualizador")
        }
        .navigationViewStyle(.stack)
    }

    private var autoEqBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars").foregroundStyle(Theme.red)
                Text("Ajuste automático del ecualizador")
                    .font(.system(size: 13, weight: .bold)).foregroundStyle(Theme.textPrimary)
                Spacer()
                Toggle("", isOn: Binding(get: { audio.autoEqEnabled }, set: { audio.setAutoEqEnabled($0) }))
                    .labelsHidden()
                    .tint(Theme.red)
            }
            Text("Analiza cada canción y ajusta el ecualizador automáticamente. Solo suena cuando el ecualizador está activo — no lo enciende por su cuenta.")
                .font(.system(size: 11)).foregroundStyle(Theme.textSecondary)
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.red.opacity(0.35), lineWidth: 1))
    }

    private func freqLabel(_ f: Double) -> String {
        f < 1000 ? "\(Int(f))" : String(format: "%gk", (f / 1000))
    }
}

/// Curva de respuesta del EQ (polilínea de las 31 ganancias).
struct EQCurve: View {
    let gains: [Double]
    let range: ClosedRange<Double>
    let enabled: Bool

    var body: some View {
        Canvas { ctx, size in
            guard gains.count > 1 else { return }
            let maxAbs = max(abs(range.lowerBound), abs(range.upperBound))
            let w = size.width, h = size.height
            let stroke = enabled ? Theme.red : Color(white: 0.35)

            func point(_ i: Int) -> CGPoint {
                let x = w * CGFloat(i) / CGFloat(gains.count - 1)
                let norm = maxAbs > 0 ? CGFloat(gains[i] / maxAbs) : 0
                let y = h / 2 - norm * (h / 2 - 8)
                return CGPoint(x: x, y: min(max(y, 4), h - 4))
            }

            // Línea de 0 dB.
            var midline = Path()
            midline.move(to: CGPoint(x: 0, y: h / 2))
            midline.addLine(to: CGPoint(x: w, y: h / 2))
            ctx.stroke(midline, with: .color(Theme.border), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))

            var path = Path()
            for i in gains.indices {
                let p = point(i)
                if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
            ctx.stroke(path, with: .color(stroke), style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))

            for i in gains.indices {
                let p = point(i)
                let r: CGFloat = 2.0
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: 2 * r, height: 2 * r)), with: .color(stroke))
            }
        }
    }
}

/// Fader vertical estilizado (arrastre o toque para posicionar), como el del web.
struct VerticalFader: View {
    let label: String
    let value: Double
    let range: ClosedRange<Double>
    var enabled: Bool
    let onChange: (Double) -> Void

    private let height: CGFloat = 210

    private var normalized: CGFloat {
        let span = range.upperBound - range.lowerBound
        return span > 0 ? CGFloat((value - range.lowerBound) / span) : 0.5
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [Color(white: 0.10), Color(white: 0.03)], startPoint: .top, endPoint: .bottom))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(white: 0.20), lineWidth: 1))
                // Fill desde el centro sería ideal; para simplicidad, barra desde abajo.
                RoundedRectangle(cornerRadius: 6)
                    .fill(Theme.red.opacity(enabled ? 0.9 : 0.22))
                    .frame(height: max(6, height * normalized))
                    .padding(.horizontal, 6)
                // Perilla del fader.
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [Color(white: 0.42), Color(white: 0.08)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 30, height: 12)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color(white: 0.33), lineWidth: 1))
                    .offset(y: -(height * normalized) + 6)
                    .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
            }
            .frame(width: 36, height: height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        guard enabled else { return }
                        let frac = 1 - min(max(g.location.y / height, 0), 1)
                        let span = range.upperBound - range.lowerBound
                        let raw = range.lowerBound + Double(frac) * span
                        let stepped = (raw / 0.5).rounded() * 0.5
                        onChange(min(max(stepped, range.lowerBound), range.upperBound))
                    }
            )

            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(enabled ? Theme.textSecondary : Theme.textMuted)
            Text((value > 0 ? "+" : "") + String(format: "%.1f", value))
                .font(.system(size: 10).monospacedDigit())
                .foregroundStyle(enabled ? Theme.red : Theme.textMuted)
        }
    }
}
