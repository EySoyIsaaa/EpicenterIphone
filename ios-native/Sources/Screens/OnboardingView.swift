import SwiftUI

/// Bienvenida de primera vez (3 pasos), fiel al onboarding del web.
struct OnboardingView: View {
    let onDone: () -> Void
    @State private var step = 0

    private struct Page { let icon: String; let title: String; let body: String }

    private let pages = [
        Page(icon: "square.and.arrow.down.fill",
             title: "Agrega tu música",
             body: "Importa archivos de audio desde Archivos para comenzar."),
        Page(icon: "slider.vertical.3",
             title: "Ajusta tu sonido",
             body: "Usa el ecualizador de 31 bandas y el procesador Epicenter para moldear bajos y claridad."),
        Page(icon: "music.note.list",
             title: "Disfruta sin interrupciones",
             body: "Crea playlists, arma la cola y reproduce sin anuncios."),
    ]

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Saltar") { onDone() }
                        .foregroundStyle(Theme.textMuted)
                        .padding()
                }

                TabView(selection: $step) {
                    ForEach(pages.indices, id: \.self) { i in
                        pageView(pages[i]).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))

                Button(step == pages.count - 1 ? "Listo" : "Siguiente") {
                    if step == pages.count - 1 { onDone() }
                    else { withAnimation { step += 1 } }
                }
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Theme.red, in: Capsule())
                .foregroundStyle(.white)
                .padding(.horizontal, 30)
                .padding(.bottom, 28)
            }
        }
    }

    private func pageView(_ p: Page) -> some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(Theme.red.opacity(0.14)).frame(width: 140, height: 140)
                Image(systemName: p.icon).font(.system(size: 56)).foregroundStyle(Theme.red)
            }
            Text(p.title)
                .font(.title.bold())
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)
            Text(p.body)
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
        .padding()
    }
}
