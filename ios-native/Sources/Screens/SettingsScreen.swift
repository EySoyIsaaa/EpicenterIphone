import SwiftUI

/// Ajustes: apariencia, idioma, guía, calificar, legal y "Acerca de".
struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeStore.shared
    @ObservedObject private var loc = LocalizationStore.shared
    @ObservedObject private var audio = AudioService.shared
    private let privacyURL = URL(string: "https://epicenterdsp.com/privacy/")!
    private let termsURL = URL(string: "https://epicenterdsp.com/terms/")!

    private var features: [String] {
        [
            L("Ecualizador de 31 bandas", "31-band equalizer"),
            L("Procesador Epicenter DSP", "Epicenter DSP processor"),
            L("Soporte Hi-Res Audio", "Hi-Res Audio support"),
            L("Controles en notificación", "Notification controls"),
        ]
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                List {
                    Section {
                        Picker(L("Tema", "Theme"), selection: $theme.mode) {
                            ForEach(ThemeStore.Mode.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text(L("Apariencia", "Appearance")).foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(Theme.card)

                    Section {
                        ForEach(LocalizationStore.Lang.allCases) { lang in
                            Button { loc.language = lang } label: {
                                HStack {
                                    Text("\(lang.flag)  \(lang.label)").foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    if loc.language == lang {
                                        Image(systemName: "checkmark").foregroundStyle(Theme.red)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text(L("Idioma", "Language")).foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(Theme.card)

                    Section {
                        Toggle(isOn: Binding(get: { audio.crossfadeEnabled }, set: { audio.setCrossfadeEnabled($0) })) {
                            Text("Crossfade").foregroundStyle(Theme.textPrimary)
                        }
                        .tint(Theme.red)
                        if audio.crossfadeEnabled {
                            Picker(L("Duración", "Duration"),
                                   selection: Binding(get: { audio.crossfadeSeconds }, set: { audio.setCrossfadeSeconds($0) })) {
                                ForEach([3.0, 5.0, 7.0, 10.0], id: \.self) { s in Text("\(Int(s))s").tag(s) }
                            }
                            .pickerStyle(.segmented)
                        }
                    } header: {
                        Text(L("Reproducción", "Playback")).foregroundStyle(Theme.textMuted)
                    } footer: {
                        Text(L("Mezcla suave entre canciones (fundido del volumen).",
                               "Smooth blend between songs (volume fade).")).foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(Theme.card)

                    Section {
                        NavigationLink(destination: HowToUseScreen()) {
                            rowContent(L("Cómo usar", "How to use"), "book.fill")
                        }
                        Button { ReviewManager.requestReview() } label: {
                            rowContent(L("Calificar la app", "Rate the app"), "star.fill")
                        }
                    } header: {
                        Text(L("Guía", "Guide")).foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(Theme.card)

                    Section {
                        Link(destination: privacyURL) { externalRow(L("Política de privacidad", "Privacy Policy"), "hand.raised.fill") }
                        Link(destination: termsURL) { externalRow(L("Términos y condiciones", "Terms & Conditions"), "doc.text.fill") }
                    } header: {
                        Text("Legal").foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(Theme.card)

                    Section {
                        HStack {
                            Text("EpicenterDSP").foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(appVersion).foregroundStyle(Theme.textMuted)
                        }
                        Text(L("Reproductor de música con procesador Epicenter DSP que reconstruye las frecuencias bajas perdidas en la compresión de audio.",
                               "Music player with the Epicenter DSP processor that rebuilds low frequencies lost in audio compression."))
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                        ForEach(features, id: \.self) { feature in
                            HStack(spacing: 10) {
                                Circle().fill(Theme.red).frame(width: 6, height: 6)
                                Text(feature).font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                            }
                        }
                    } header: {
                        Text(L("Acerca de", "About")).foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(Theme.card)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackgroundHiddenCompat()
            }
            .navigationTitle(L("Ajustes", "Settings"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(L("Cerrar", "Close")) { dismiss() }.foregroundStyle(Theme.red)
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func rowContent(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.red).frame(width: 24)
            Text(title).foregroundStyle(Theme.textPrimary)
        }
    }

    private func externalRow(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.red).frame(width: 24)
            Text(title).foregroundStyle(Theme.textPrimary)
            Spacer()
            Image(systemName: "arrow.up.right").font(.footnote).foregroundStyle(Theme.textMuted)
        }
    }
}
