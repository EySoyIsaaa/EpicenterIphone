import SwiftUI

/// Ajustes: enlaces externos (privacidad/términos) y versión.
/// (Idioma y tema se agregan en una pasada posterior.)
struct SettingsScreen: View {
    // TODO: reemplazar por las URLs reales de tu sitio.
    private let privacyURL = URL(string: "https://epicenterdsp.app/privacidad")!
    private let termsURL = URL(string: "https://epicenterdsp.app/terminos")!

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
                        Link(destination: privacyURL) { row("Política de privacidad", "hand.raised.fill") }
                        Link(destination: termsURL) { row("Términos y condiciones", "doc.text.fill") }
                    } header: {
                        Text("Legal").foregroundStyle(Theme.textMuted)
                    }

                    Section {
                        HStack {
                            Text("Versión").foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Text(appVersion).foregroundStyle(Theme.textMuted)
                        }
                    }
                    .listRowBackground(Theme.card)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackgroundHidden()
            }
            .navigationTitle("Ajustes")
        }
        .navigationViewStyle(.stack)
    }

    private func row(_ title: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Theme.red).frame(width: 24)
            Text(title).foregroundStyle(Theme.textPrimary)
            Spacer()
            Image(systemName: "arrow.up.right").font(.footnote).foregroundStyle(Theme.textMuted)
        }
    }
}

private extension View {
    /// Oculta el fondo del List solo en iOS 16+ (en iOS 15 no hace nada).
    @ViewBuilder func scrollContentBackgroundHidden() -> some View {
        if #available(iOS 16.0, *) { self.scrollContentBackground(.hidden) } else { self }
    }
}
