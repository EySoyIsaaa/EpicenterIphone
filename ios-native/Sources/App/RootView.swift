import SwiftUI

/// Shell de 5 pestañas + mini-reproductor.
/// Inicio · Música · Epicenter · EQ · Efectos. (Buscar y Ajustes viven dentro de Música.)
struct RootView: View {
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var theme = ThemeStore.shared
    @State private var selection: Tab = .inicio
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    enum Tab { case inicio, musica, epicenter, eq, efectos }

    private var showMini: Bool { audio.hasTrack && selection != .inicio }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                PlayerScreen()
                    .tag(Tab.inicio)
                    .tabItem { Label("Inicio", systemImage: "play.circle.fill") }

                LibraryScreen()
                    .tag(Tab.musica)
                    .tabItem { Label("Música", systemImage: "music.note.list") }

                DspScreen()
                    .tag(Tab.epicenter)
                    .tabItem { Label("Epicenter", systemImage: "waveform") }

                EqScreen()
                    .tag(Tab.eq)
                    .tabItem { Label("EQ", systemImage: "slider.vertical.3") }

                EffectsScreen()
                    .tag(Tab.efectos)
                    .tabItem { Label("Efectos", systemImage: "wand.and.rays") }
            }
            .tint(Theme.red)

            // Mini-reproductor sobre la barra de pestañas (excepto en Inicio).
            if showMini {
                MiniPlayer { selection = .inicio }
                    .padding(.bottom, 52)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: showMini)
        .fullScreenCover(isPresented: Binding(get: { !hasOnboarded }, set: { hasOnboarded = !$0 })) {
            OnboardingView { hasOnboarded = true }
        }
        .onAppear { if hasOnboarded { ReviewManager.registerUseAndMaybeAsk() } }
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    RootView()
}
