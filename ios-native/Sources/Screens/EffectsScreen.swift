import SwiftUI

/// Efectos espaciales (se abre desde DSP): Reverb y Concert Hall.
struct EffectsScreen: View {
    @ObservedObject private var audio = AudioService.shared

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        Text("Reverb y sala de concierto en paralelo. La señal seca se conserva a ganancia unitaria.")
                            .font(.footnote).foregroundStyle(Theme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        effectCard(
                            title: "Reverb",
                            description: "Ambiente Medium Room de Apple en una ruta paralela: conserva completa la señal seca y añade profundidad definida.",
                            enabled: Binding(get: { audio.reverbEnabled }, set: { audio.setReverbEnabled($0) }),
                            amount: audio.reverbAmount,
                            onAmount: { audio.setReverbAmount($0) }
                        )
                        effectCard(
                            title: "Concert Hall",
                            description: "Large Hall independiente y más amplio: una cola clara que no vuelve a procesar el Reverb.",
                            enabled: Binding(get: { audio.concertHallEnabled }, set: { audio.setConcertHallEnabled($0) }),
                            amount: audio.concertHallAmount,
                            onAmount: { audio.setConcertHallAmount($0) }
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Efectos")
        }
        .navigationViewStyle(.stack)
    }

    private func effectCard(title: String, description: String, enabled: Binding<Bool>, amount: Double, onAmount: @escaping (Double) -> Void) -> some View {
        VStack(spacing: 14) {
            Toggle(isOn: enabled) {
                Text(title).font(.headline).foregroundStyle(Theme.textPrimary)
            }
            .tint(Theme.red)
            Text(description)
                .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            KnobControl(label: "Cantidad", value: amount, range: 0...100, unit: "%",
                        disabled: !enabled.wrappedValue, size: 112, featured: true, onChange: onAmount)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}
