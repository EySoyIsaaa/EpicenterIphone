import SwiftUI

/// Fase 4: Epicenter DSP — switch de modo Car/Audífonos, intensidad y perillas, accesos a EQ y Efectos.
struct DspScreen: View {
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var loc = LocalizationStore.shared

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
                        KnobControl(label: L("Intensidad", "Intensity"), value: audio.intensity, range: 0...100, unit: "%",
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
                            KnobControl(label: L("Volumen", "Volume"), value: audio.volume, range: 0...150, unit: "%",
                                        disabled: !audio.epicenterEnabled) { audio.setVolume($0) }
                        }
                        .padding(.top, 4)

                        if audio.headphonesMode {
                            Text(L("En modo Audífonos el motor se ajusta solo con Intensidad. Sweep, Width y Balance pertenecen al motor de Car Audio.",
                                   "In Headphones mode the engine is tuned with Intensity only. Sweep, Width and Balance belong to the Car Audio engine."))
                                .font(.caption).foregroundStyle(Theme.textMuted)
                        }

                        autoEpicenterCard
                            .padding(.top, 4)
                    }
                    .padding([.horizontal, .top])
                    .padding(.bottom, 96)   // espacio para la barra + mini-reproductor
                }
            }
            .navigationTitle("Epicenter DSP")
        }
        .navigationViewStyle(.stack)
    }

    private var modeHint: String {
        audio.headphonesMode
            ? L("Estás usando el tuning perfecto para audífonos y bocinas portátiles: graves profundos y limpios que sí se escuchan en drivers pequeños.",
                "You're using the perfect tuning for headphones and portable speakers: deep, clean bass that actually plays on small drivers.")
            : L("Estás usando el tuning perfecto para equipos de car audio: máxima presión de subgraves, pensado para sistemas con subwoofer.",
                "You're using the perfect tuning for car audio: maximum sub-bass pressure, made for systems with a subwoofer.")
    }

    private var modeSwitch: some View {
        HStack(spacing: 6) {
            modeButton(title: "Car Audio", icon: "car.fill", active: !audio.headphonesMode) { audio.setHeadphonesMode(false) }
            modeButton(title: L("Audífonos", "Headphones"), icon: "headphones", active: audio.headphonesMode) { audio.setHeadphonesMode(true) }
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
                    Text(L("Ajuste automático", "Auto adjust")).font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.textPrimary)
                }
            }
            .tint(Theme.red)
            Text(L("Analiza cada canción para reforzar el bajo. Solo actúa con Epicenter activo — no lo enciende por su cuenta. Independiente del Auto-EQ del ecualizador.",
                   "Analyzes each song to reinforce the bass. Only acts when Epicenter is on — it won't turn it on by itself. Independent from the equalizer's Auto-EQ."))
                .font(.caption).foregroundStyle(Theme.textMuted)
        }
        .padding()
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.red.opacity(0.35), lineWidth: 1))
    }
}
