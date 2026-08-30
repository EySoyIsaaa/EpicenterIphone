import SwiftUI

/// Epicenter DSP — reconstructor de bajos. Modo Car/Audífonos, intensidad y perillas, Auto.
struct DspScreen: View {
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var loc = LocalizationStore.shared

    private var secondaryDisabled: Bool { !audio.epicenterEnabled || audio.headphonesMode }

    var body: some View {
        NavigationView {
            ZStack {
                BrandBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        header
                        modeSwitch
                        Text(modeHint).font(.footnote).foregroundStyle(Theme.textMuted)

                        engineCard
                        secondaryCard

                        if audio.headphonesMode {
                            Text(L("En modo Audífonos el motor se ajusta solo con Intensidad. Sweep, Width y Balance pertenecen al motor de Car Audio.",
                                   "In Headphones mode the engine is tuned with Intensity only. Sweep, Width and Balance belong to the Car Audio engine."))
                                .font(.caption).foregroundStyle(Theme.textMuted)
                        }

                        autoEpicenterCard
                    }
                    .padding([.horizontal, .top])
                    .padding(.bottom, 96)
                }
            }
            .navigationTitle("Epicenter DSP")
        }
        .navigationViewStyle(.stack)
    }

    // MARK: Encabezado + estado

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("EPICENTER DSP 7.0")
                    .font(.system(size: 10, weight: .black)).kerning(1.6)
                    .foregroundStyle(Theme.red)
                Text(L("Reconstructor de bajos", "Bass reconstructor"))
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(audio.epicenterEnabled ? Theme.red : Theme.textMuted)
                .frame(width: 8, height: 8)
                .shadow(color: audio.epicenterEnabled ? Theme.red.opacity(0.9) : .clear, radius: 5)
            Text(audio.epicenterEnabled ? "ACTIVE" : "BYPASS")
                .font(.system(size: 9, weight: .black)).kerning(1.2)
                .foregroundStyle(Theme.textSecondary)
            Toggle("", isOn: Binding(get: { audio.epicenterEnabled }, set: { audio.setEpicenterEnabled($0) }))
                .labelsHidden().tint(Theme.red)
        }
        .padding(.leading, 12).padding(.trailing, 8).padding(.vertical, 6)
        .background(Theme.card, in: Capsule())
        .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
    }

    // MARK: Tarjeta del motor (Intensidad)

    private var engineCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Circle().fill(Theme.red).frame(width: 6, height: 6)
                Text("EPICENTER ENGINE " + (audio.epicenterEnabled ? "ACTIVE" : "STANDBY"))
                    .font(.system(size: 10, weight: .black)).kerning(1.4)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(.black.opacity(0.25), in: Capsule())
            .overlay(Capsule().stroke(Theme.red.opacity(0.3), lineWidth: 1))

            KnobControl(label: L("Intensidad", "Intensity"), value: audio.intensity, range: 0...100, unit: "%",
                        disabled: !audio.epicenterEnabled, size: 156, featured: true) { audio.setIntensity($0) }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(cardGradient, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.red.opacity(0.28), lineWidth: 1))
    }

    private var secondaryCard: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            KnobControl(label: "Sweep", value: audio.sweepFreq, range: 27...63, unit: "Hz",
                        disabled: secondaryDisabled) { audio.setSweep($0) }
            KnobControl(label: "Width", value: audio.width, range: 0...100, unit: "%",
                        disabled: secondaryDisabled) { audio.setWidth($0) }
            KnobControl(label: "Balance", value: audio.balance, range: 0...100, unit: "%",
                        disabled: secondaryDisabled) { audio.setBalance($0) }
            KnobControl(label: L("Volumen", "Volume"), value: audio.volume, range: 0...150, unit: "%",
                        disabled: !audio.epicenterEnabled) { audio.setVolume($0) }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Theme.card.opacity(0.5), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.border, lineWidth: 1))
    }

    private var cardGradient: LinearGradient {
        LinearGradient(colors: [Theme.card, Theme.card.opacity(0.35)], startPoint: .top, endPoint: .bottom)
    }

    // MARK: Modo

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
        .padding(5)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 1))
    }

    private func modeButton(title: String, icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title).font(.system(size: 12, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(active ? Theme.red : .clear, in: RoundedRectangle(cornerRadius: 10))
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
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.red.opacity(0.3), lineWidth: 1))
    }
}
