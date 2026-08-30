import SwiftUI

/// Efectos espaciales: Reverb y Concert Hall (rutas paralelas, señal seca a ganancia unitaria).
struct EffectsScreen: View {
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var loc = LocalizationStore.shared

    var body: some View {
        NavigationView {
            ZStack {
                BrandBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("SPATIAL FX")
                                    .font(.system(size: 10, weight: .black)).kerning(1.6)
                                    .foregroundStyle(Theme.red)
                                Text(L("Reverb y sala de concierto", "Reverb and concert hall"))
                                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                        }

                        effectCard(
                            title: "Reverb",
                            icon: "dot.radiowaves.left.and.right",
                            description: L("Ambiente Medium Room de Apple en una ruta paralela: conserva completa la señal seca y añade profundidad definida.",
                                           "Apple's Medium Room ambience on a parallel path: keeps the dry signal intact and adds defined depth."),
                            enabled: Binding(get: { audio.reverbEnabled }, set: { audio.setReverbEnabled($0) }),
                            amount: audio.reverbAmount,
                            onAmount: { audio.setReverbAmount($0) }
                        )
                        effectCard(
                            title: "Concert Hall",
                            icon: "building.columns.fill",
                            description: L("Large Hall independiente y más amplio: una cola clara que no vuelve a procesar el Reverb.",
                                           "An independent, wider Large Hall: a clear tail that doesn't re-process the Reverb."),
                            enabled: Binding(get: { audio.concertHallEnabled }, set: { audio.setConcertHallEnabled($0) }),
                            amount: audio.concertHallAmount,
                            onAmount: { audio.setConcertHallAmount($0) }
                        )

                        Text(L("La señal seca permanece a ganancia unitaria; un limitador de picos protege la salida.",
                               "The dry signal stays at unity gain; a peak limiter protects the output."))
                            .font(.footnote).foregroundStyle(Theme.textMuted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                    }
                    .padding([.horizontal, .top])
                    .padding(.bottom, 96)
                }
            }
            .navigationTitle(L("Efectos", "Effects"))
        }
        .navigationViewStyle(.stack)
    }

    private func effectCard(title: String, icon: String, description: String, enabled: Binding<Bool>, amount: Double, onAmount: @escaping (Double) -> Void) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(enabled.wrappedValue ? Theme.red.opacity(0.18) : Theme.card)
                        .frame(width: 44, height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(enabled.wrappedValue ? Theme.red.opacity(0.5) : Theme.border, lineWidth: 1))
                    Image(systemName: icon).foregroundStyle(enabled.wrappedValue ? Theme.red : Theme.textSecondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline).foregroundStyle(Theme.textPrimary)
                    Text(enabled.wrappedValue ? "ON" : "OFF")
                        .font(.system(size: 9, weight: .black)).kerning(1.2)
                        .foregroundStyle(enabled.wrappedValue ? Theme.red : Theme.textMuted)
                }
                Spacer()
                Toggle("", isOn: enabled).labelsHidden().tint(Theme.red)
            }

            Text(description)
                .font(.system(size: 12)).foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            KnobControl(label: L("Cantidad", "Amount"), value: amount, range: 0...100, unit: "%",
                        disabled: !enabled.wrappedValue, size: 112, featured: true, onChange: onAmount)
                .frame(maxWidth: .infinity)
        }
        .padding()
        .background(LinearGradient(colors: [Theme.card, Theme.card.opacity(0.4)], startPoint: .top, endPoint: .bottom),
                    in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(enabled.wrappedValue ? Theme.red.opacity(0.3) : Theme.border, lineWidth: 1))
    }
}
