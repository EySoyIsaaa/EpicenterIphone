import SwiftUI

/// Shell de 5 pestañas + mini-reproductor.
/// Inicio · Música · Epicenter · EQ · Efectos. (Buscar y Ajustes viven dentro de Música.)
struct RootView: View {
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var theme = ThemeStore.shared
    @ObservedObject private var loc = LocalizationStore.shared
    @State private var selection: Tab = .inicio
    @State private var showSplash = true
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    enum Tab { case inicio, musica, epicenter, eq, efectos }

    private var showMini: Bool { audio.hasTrack && selection != .inicio }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                PlayerScreen()
                    .tag(Tab.inicio)
                    .tabItem { Label(L("Inicio", "Home"), systemImage: "play.circle.fill") }

                LibraryScreen()
                    .tag(Tab.musica)
                    .tabItem { Label(L("Música", "Music"), systemImage: "music.note.list") }

                DspScreen()
                    .tag(Tab.epicenter)
                    .tabItem { Label("Epicenter", systemImage: "waveform") }

                EqScreen()
                    .tag(Tab.eq)
                    .tabItem { Label("EQ", systemImage: "slider.vertical.3") }

                EffectsScreen()
                    .tag(Tab.efectos)
                    .tabItem { Label(L("Efectos", "Effects"), systemImage: "wand.and.rays") }
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
        .overlay {
            if showSplash {
                SplashView { showSplash = false }
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .fullScreenCover(isPresented: Binding(get: { !hasOnboarded && !showSplash }, set: { hasOnboarded = !$0 })) {
            OnboardingView { hasOnboarded = true }
        }
        .onAppear { if hasOnboarded { ReviewManager.registerUseAndMaybeAsk() } }
        .preferredColorScheme(theme.colorScheme)
    }
}

#Preview {
    RootView()
}
