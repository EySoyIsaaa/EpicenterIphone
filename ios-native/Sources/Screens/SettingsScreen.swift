import SwiftUI

/// Ajustes: guía de uso, enlaces legales externos (privacidad/términos) y "Acerca de".
struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var theme = ThemeStore.shared
    private let privacyURL = URL(string: "https://epicenterdsp.com/privacy/")!
    private let termsURL = URL(string: "https://epicenterdsp.com/terms/")!

    private let features = [
        "Ecualizador de 31 bandas",
        "Procesador Epicenter DSP",
        "Soporte Hi-Res Audio",
        "Controles en notificación",
    ]

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
                        Picker("Tema", selection: $theme.mode) {
                            ForEach(ThemeStore.Mode.allCases) { Text($0.label).tag($0) }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("Apariencia").foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(Theme.card)

                    Section {
                        NavigationLink(destination: HowToUseScreen()) {
                            rowContent("Cómo usar", "book.fill")
                        }
                        Button { ReviewManager.requestReview() } label: {
                            rowContent("Calificar la app", "star.fill")
                        }
                    } header: {
                        Text("Guía").foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(Theme.card)

                    Section {
                        Link(destination: privacyURL) { externalRow("Política de privacidad", "hand.raised.fill") }
                        Link(destination: termsURL) { externalRow("Términos y condiciones", "doc.text.fill") }
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
                        Text("Reproductor de música con procesador Epicenter DSP que reconstruye las frecuencias bajas perdidas en la compresión de audio.")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                        ForEach(features, id: \.self) { feature in
                            HStack(spacing: 10) {
                                Circle().fill(Theme.red).frame(width: 6, height: 6)
                                Text(feature).font(.system(size: 14)).foregroundStyle(Theme.textSecondary)
                            }
                        }
                    } header: {
                        Text("Acerca de").foregroundStyle(Theme.textMuted)
                    }
                    .listRowBackground(Theme.card)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackgroundHiddenCompat()
            }
            .navigationTitle("Ajustes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }.foregroundStyle(Theme.red)
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
