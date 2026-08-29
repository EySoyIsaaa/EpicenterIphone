import SwiftUI

/// Fase 4: Epicenter DSP — switch de modo Car/Audífonos, intensidad y perillas, accesos a EQ y Efectos.
struct DspScreen: View {
    @ObservedObject private var audio = AudioService.shared

    private var secondaryDisabled: Bool { !audio.epicenterEnabled || audio.headphonesMode }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Toggle(isOn: Binding(get: { audio.epicenterEnabled }, set: { audio.setEpicenterEnabled($0) })) {
                            Text("Epicenter").font(.headline).foregroundStyle(Theme.textPrimary)
                        }
                        .tint(Theme.red)

                        modeSwitch
                        Text(modeHint)
                            .font(.footnote)
                            .foregroundStyle(Theme.textMuted)

                        LabeledSlider(title: "Intensidad", value: audio.intensity, range: 0...100, unit: "%",
                                      disabled: !audio.epicenterEnabled) { audio.setIntensity($0) }
                        LabeledSlider(title: "Sweep", value: audio.sweepFreq, range: 27...63, unit: " Hz",
                                      disabled: secondaryDisabled) { audio.setSweep($0) }
                        LabeledSlider(title: "Width", value: audio.width, range: 0...100, unit: "%",
                                      disabled: secondaryDisabled) { audio.setWidth($0) }
                        LabeledSlider(title: "Balance", value: audio.balance, range: 0...100, unit: "%",
                                      disabled: secondaryDisabled) { audio.setBalance($0) }
                        LabeledSlider(title: "Volumen", value: audio.volume, range: 0...150, unit: "%",
                                      disabled: !audio.epicenterEnabled) { audio.setVolume($0) }

                        if audio.headphonesMode {
                            Text("En modo Audífonos el motor se ajusta solo con Intensidad. Sweep, Width y Balance pertenecen al motor de Car Audio.")
                                .font(.caption).foregroundStyle(Theme.textMuted)
                        }

                        HStack(spacing: 12) {
                            NavigationLink(destination: EqScreen()) { card("Ecualizador", "slider.horizontal.3") }
                            NavigationLink(destination: EffectsScreen()) { card("Efectos", "waveform.path.ecg") }
                        }
                        .padding(.top, 4)
                    }
                    .padding()
                }
            }
            .navigationTitle("Epicenter DSP")
        }
        .navigationViewStyle(.stack)
    }

    private var modeHint: String {
        audio.headphonesMode
            ? "Estás usando el tuning perfecto para audífonos y bocinas portátiles: graves profundos y limpios que sí se escuchan en drivers pequeños."
            : "Estás usando el tuning perfecto para equipos de car audio: máxima presión de subgraves, pensado para sistemas con subwoofer."
    }

    private var modeSwitch: some View {
        HStack(spacing: 6) {
            modeButton(title: "Car Audio", icon: "car.fill", active: !audio.headphonesMode) { audio.setHeadphonesMode(false) }
            modeButton(title: "Audífonos", icon: "headphones", active: audio.headphonesMode) { audio.setHeadphonesMode(true) }
        }
        .padding(4)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }

    private func modeButton(title: String, icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title).font(.system(size: 12, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(active ? Theme.red : .clear, in: RoundedRectangle(cornerRadius: 11))
            .foregroundStyle(active ? .white : Theme.textSecondary)
        }
    }

    private func card(_ title: String, _ icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(Theme.red)
            Text(title).font(.system(size: 15, weight: .bold)).foregroundStyle(Theme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
    }
}
