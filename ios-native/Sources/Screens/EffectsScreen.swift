import SwiftUI

/// Efectos espaciales (se abre desde DSP): Reverb y Concert Hall.
struct EffectsScreen: View {
    @ObservedObject private var audio = AudioService.shared

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    effectCard(
                        title: "Reverb",
                        enabled: Binding(get: { audio.reverbEnabled }, set: { audio.setReverbEnabled($0) }),
                        amount: audio.reverbAmount,
                        onAmount: { audio.setReverbAmount($0) }
                    )
                    effectCard(
                        title: "Concert Hall",
                        enabled: Binding(get: { audio.concertHallEnabled }, set: { audio.setConcertHallEnabled($0) }),
                        amount: audio.concertHallAmount,
                        onAmount: { audio.setConcertHallAmount($0) }
                    )
                }
                .padding()
            }
        }
        .navigationTitle("Efectos")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func effectCard(title: String, enabled: Binding<Bool>, amount: Double, onAmount: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: enabled) {
                Text(title).font(.headline).foregroundStyle(Theme.textPrimary)
            }
            .tint(Theme.red)
            LabeledSlider(title: "Cantidad", value: amount, range: 0...100, unit: "%",
                          disabled: !enabled.wrappedValue, onChange: onAmount)
        }
        .padding()
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}
