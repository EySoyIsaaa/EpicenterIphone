import SwiftUI

/// Guía "Cómo usar" (se abre desde Ajustes). Contenido fiel a la web.
struct HowToUseScreen: View {
    private struct Step: Identifiable {
        let id = UUID()
        let title: String
        let body: String
    }

    @ObservedObject private var loc = LocalizationStore.shared

    private var intro: String {
        L("Epicenter DSP es un reproductor local con énfasis en el procesador Epicenter para experiencias de audio potentes.",
          "Epicenter DSP is a local player focused on the Epicenter processor for powerful audio experiences.")
    }

    private var steps: [Step] {
        [
            Step(title: L("1. Importa tu música", "1. Import your music"),
                 body: L("Toca + en Música para importar archivos de audio desde la app Archivos.",
                         "Tap + in Music to import audio files from the Files app.")),
            Step(title: L("2. Inicia la reproducción", "2. Start playback"),
                 body: L("Selecciona cualquier canción o usa los botones Reproducir y Aleatorio en Canciones, Artistas o Playlists.",
                         "Pick any song or use the Play and Shuffle buttons in Songs, Artists or Playlists.")),
            Step(title: L("3. Gestiona la cola", "3. Manage the queue"),
                 body: L("Agrega canciones a la cola, reproduce siguiente o reordena para el flujo exacto que deseas.",
                         "Add songs to the queue, play next or reorder for the exact flow you want.")),
            Step(title: L("4. Ajusta el ecualizador", "4. Adjust the equalizer"),
                 body: L("Abre el ecualizador de 31 bandas y vuelve a un sonido neutro cuando quieras.",
                         "Open the 31-band equalizer and go back to a neutral sound whenever you like.")),
            Step(title: L("5. Usa Epicenter DSP", "5. Use Epicenter DSP"),
                 body: L("Activa Epicenter y ajusta Sweep, Width, Intensidad, Balance y Volumen según tu perfil. Elige modo Car Audio o Audífonos.",
                         "Turn on Epicenter and adjust Sweep, Width, Intensity, Balance and Volume to taste. Choose Car Audio or Headphones mode.")),
            Step(title: L("6. Crea playlists", "6. Create playlists"),
                 body: L("Crea playlists en Música y reprodúcelas en orden o en aleatorio al instante.",
                         "Create playlists in Music and play them in order or shuffled instantly.")),
        ]
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(intro)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)

                    ForEach(steps) { step in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(step.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Text(step.body)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tips")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(L("Las pistas Hi-Res se marcan automáticamente. Marca tus canciones favoritas con el corazón para encontrarlas rápido.",
                               "Hi-Res tracks are tagged automatically. Mark your favorite songs with the heart to find them fast."))
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(L("Cómo usar", "How to use"))
        .navigationBarTitleDisplayMode(.inline)
    }
}
