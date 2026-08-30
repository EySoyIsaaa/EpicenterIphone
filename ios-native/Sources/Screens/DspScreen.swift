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

                        // Perilla principal (Intensidad).
                        KnobControl(label: "Intensidad", value: audio.intensity, range: 0...100, unit: "%",
                                    disabled: !audio.epicenterEnabled, size: 150, featured: true) { audio.setIntensity($0) }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)

                        // Perillas secundarias.
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                            KnobControl(label: "Sweep", value: audio.sweepFreq, range: 27...63, unit: "Hz",
                                        disabled: secondaryDisabled) { audio.setSweep($0) }
                            KnobControl(label: "Width", value: audio.width, range: 0...100, unit: "%",
                                        disabled: secondaryDisabled) { audio.setWidth($0) }
                            KnobControl(label: "Balance", value: audio.balance, range: 0...100, unit: "%",
                                        disabled: secondaryDisabled) { audio.setBalance($0) }
                            KnobControl(label: "Volumen", value: audio.volume, range: 0...150, unit: "%",
                                        disabled: !audio.epicenterEnabled) { audio.setVolume($0) }
                        }
                        .padding(.top, 4)

                        if audio.headphonesMode {
                            Text("En modo Audífonos el motor se ajusta solo con Intensidad. Sweep, Width y Balance pertenecen al motor de Car Audio.")
                                .font(.caption).foregroundStyle(Theme.textMuted)
                        }

                        autoEpicenterCard
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

    private var autoEpicenterCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(get: { audio.autoEpicenterEnabled }, set: { audio.setAutoEpicenterEnabled($0) })) {
                HStack(spacing: 8) {
                    Image(systemName: "wand.and.stars").foregroundStyle(Theme.red)
                    Text("Ajuste automático").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                }
            }
            .tint(Theme.red)
            Text("Analiza cada canción para reforzar el bajo. Solo actúa con Epicenter activo — no lo enciende por su cuenta. Independiente del Auto-EQ del ecualizador.")
                .font(.caption).foregroundStyle(Theme.textMuted)
        }
        .padding()
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.red.opacity(0.35), lineWidth: 1))
    }
}
