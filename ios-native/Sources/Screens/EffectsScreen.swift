import SwiftUI

/// Efectos espaciales (se abre desde DSP): Reverb y Concert Hall.
struct EffectsScreen: View {
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var loc = LocalizationStore.shared

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        Text(L("Reverb y sala de concierto en paralelo. La señal seca se conserva a ganancia unitaria.",
                               "Reverb and concert hall in parallel. The dry signal stays at unity gain."))
                            .font(.footnote).foregroundStyle(Theme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        effectCard(
                            title: "Reverb",
                            description: L("Ambiente Medium Room de Apple en una ruta paralela: conserva completa la señal seca y añade profundidad definida.",
                                           "Apple's Medium Room ambience on a parallel path: keeps the dry signal intact and adds defined depth."),
                            enabled: Binding(get: { audio.reverbEnabled }, set: { audio.setReverbEnabled($0) }),
                            amount: audio.reverbAmount,
                            onAmount: { audio.setReverbAmount($0) }
                        )
                        effectCard(
                            title: "Concert Hall",
                            description: L("Large Hall independiente y más amplio: una cola clara que no vuelve a procesar el Reverb.",
                                           "An independent, wider Large Hall: a clear tail that doesn't re-process the Reverb."),
                            enabled: Binding(get: { audio.concertHallEnabled }, set: { audio.setConcertHallEnabled($0) }),
                            amount: audio.concertHallAmount,
                            onAmount: { audio.setConcertHallAmount($0) }
                        )
                    }
                    .padding([.horizontal, .top])
                    .padding(.bottom, 96)
                }
            }
            .navigationTitle(L("Efectos", "Effects"))
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
            KnobControl(label: L("Cantidad", "Amount"), value: amount, range: 0...100, unit: "%",
                        disabled: !enabled.wrappedValue, size: 112, featured: true, onChange: onAmount)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
    }
}
