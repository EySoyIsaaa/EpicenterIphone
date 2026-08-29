import SwiftUI

/// Shell de 5 pestañas + mini-reproductor.
/// Inicio · Mi Música · Buscar · DSP · Ajustes.
struct RootView: View {
    @ObservedObject private var audio = AudioService.shared
    @State private var selection: Tab = .inicio

    enum Tab { case inicio, musica, buscar, dsp, ajustes }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                PlayerScreen()
                    .tag(Tab.inicio)
                    .tabItem { Label("Inicio", systemImage: "play.circle.fill") }

                LibraryScreen()
                    .tag(Tab.musica)
                    .tabItem { Label("Mi Música", systemImage: "music.note.list") }

                SearchScreen()
                    .tag(Tab.buscar)
                    .tabItem { Label("Buscar", systemImage: "magnifyingglass") }

                DspScreen()
                    .tag(Tab.dsp)
                    .tabItem { Label("DSP", systemImage: "waveform") }

                SettingsScreen()
                    .tag(Tab.ajustes)
                    .tabItem { Label("Ajustes", systemImage: "gearshape.fill") }
            }
            .tint(Theme.red)

            // Mini-reproductor sobre la barra de pestañas (excepto en Inicio, que ya es el reproductor).
            if audio.hasTrack && selection != .inicio {
                MiniPlayer { selection = .inicio }
                    .padding(.bottom, 52)
            }
        }
    }
}

#Preview {
    RootView()
}
