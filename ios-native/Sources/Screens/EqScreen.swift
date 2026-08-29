import SwiftUI

/// Ecualizador de 31 bandas (se abre desde DSP).
struct EqScreen: View {
    @ObservedObject private var audio = AudioService.shared

    private static let freqs: [Double] = [
        20, 25, 31.5, 40, 50, 63, 80, 100, 125, 160, 200, 250, 315, 400, 500, 630,
        800, 1000, 1250, 1600, 2000, 2500, 3150, 4000, 5000, 6300, 8000, 10000, 12500, 16000, 20000,
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Toggle(isOn: Binding(get: { audio.eqEnabled }, set: { audio.setEqEnabled($0) })) {
                    Text("Ecualizador activo").font(.subheadline).foregroundStyle(Theme.textPrimary)
                }
                .tint(Theme.red)
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .bottom, spacing: 16) {
                        ForEach(0..<31, id: \.self) { i in
                            bandColumn(i)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .opacity(audio.eqEnabled ? 1 : 0.45)
                .disabled(!audio.eqEnabled)

                Button("Restablecer") { audio.resetEq() }
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.vertical)
        }
        .navigationTitle("Ecualizador")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func bandColumn(_ i: Int) -> some View {
        VStack(spacing: 6) {
            Text(String(format: "%+d", Int(audio.eqBands[i].rounded())))
                .font(.system(size: 9, weight: .medium).monospacedDigit())
                .foregroundStyle(Theme.textMuted)
            Slider(value: Binding(get: { audio.eqBands[i] }, set: { audio.setEqBand(i, $0) }), in: -8...8)
                .tint(Theme.red)
                .frame(width: 150)
                .rotationEffect(.degrees(-90))
                .frame(width: 30, height: 150)
            Text(freqLabel(EqScreen.freqs[i]))
                .font(.system(size: 9))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize()
        }
    }

    private func freqLabel(_ f: Double) -> String {
        f < 1000 ? "\(Int(f))" : String(format: "%gk", (f / 1000))
    }
}
