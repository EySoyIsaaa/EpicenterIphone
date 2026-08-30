import SwiftUI

/// Bienvenida de primera vez (3 pasos), fiel al onboarding del web.
struct OnboardingView: View {
    let onDone: () -> Void
    @State private var step = 0

    private struct Page { let icon: String; let title: String; let body: String }

    private var pages: [Page] {
        [
            Page(icon: "square.and.arrow.down.fill",
                 title: L("Agrega tu música", "Add your music"),
                 body: L("Importa archivos de audio desde Archivos para comenzar.",
                         "Import audio files from Files to get started.")),
            Page(icon: "slider.vertical.3",
                 title: L("Ajusta tu sonido", "Shape your sound"),
                 body: L("Usa el ecualizador de 31 bandas y el procesador Epicenter para moldear bajos y claridad.",
                         "Use the 31-band equalizer and the Epicenter processor to shape bass and clarity.")),
            Page(icon: "music.note.list",
                 title: L("Disfruta sin interrupciones", "Enjoy without interruptions"),
                 body: L("Crea playlists, arma la cola y reproduce sin anuncios.",
                         "Create playlists, build the queue and play with no ads.")),
        ]
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(L("Saltar", "Skip")) { onDone() }
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

                Button(step == pages.count - 1 ? L("Listo", "Done") : L("Siguiente", "Next")) {
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
