import SwiftUI

/// The 5-tab shell that matches the app's bottom navigation:
/// Inicio · Mi Música · Buscar · DSP · Ajustes.
/// Each tab is a placeholder for now; real screens are filled in per phase.
struct RootView: View {
    var body: some View {
        TabView {
            EngineTestScreen()   // Fase 0b: prueba del motor nativo (temporal, será el reproductor)
                .tabItem { Label("Inicio", systemImage: "play.circle.fill") }

            LibrarySongsScreen()
                .tabItem { Label("Mi Música", systemImage: "music.note.list") }

            PlaceholderScreen(title: "Buscar", systemImage: "magnifyingglass")
                .tabItem { Label("Buscar", systemImage: "magnifyingglass") }

            PlaceholderScreen(title: "DSP", systemImage: "waveform")
                .tabItem { Label("DSP", systemImage: "waveform") }

            PlaceholderScreen(title: "Ajustes", systemImage: "gearshape.fill")
                .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
        }
        .tint(Theme.red)
    }
}

private struct PlaceholderScreen: View {
    let title: String
    let systemImage: String

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Theme.red)
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Pantalla nativa — próximamente")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

#Preview {
    RootView()
}
