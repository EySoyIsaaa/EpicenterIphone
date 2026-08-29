import SwiftUI

/// Guía "Cómo usar" (se abre desde Ajustes). Contenido fiel a la web.
struct HowToUseScreen: View {
    private struct Step: Identifiable {
        let id = UUID()
        let title: String
        let body: String
    }

    private let intro = "Epicenter DSP es un reproductor local con énfasis en el procesador Epicenter para experiencias de audio potentes."

    private let steps: [Step] = [
        Step(title: "1. Importa tu música",
             body: "Toca + en Mi Música para importar archivos de audio desde la app Archivos."),
        Step(title: "2. Inicia la reproducción",
             body: "Selecciona cualquier canción o usa los botones Reproducir y Aleatorio en Canciones, Artistas o Playlists."),
        Step(title: "3. Gestiona la cola",
             body: "Agrega canciones a la cola, reproduce siguiente o reordena para el flujo exacto que deseas."),
        Step(title: "4. Ajusta el ecualizador",
             body: "Abre el ecualizador de 31 bandas desde DSP y vuelve a un sonido neutro cuando quieras."),
        Step(title: "5. Usa Epicenter DSP",
             body: "Activa Epicenter y ajusta Sweep, Width, Intensidad, Balance y Volumen según tu perfil. Elige modo Car Audio o Audífonos."),
        Step(title: "6. Crea playlists",
             body: "Crea playlists en Mi Música y reprodúcelas en orden o en aleatorio al instante."),
    ]

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
                        Text("Las pistas Hi-Res se marcan automáticamente. Marca tus canciones favoritas con el corazón para encontrarlas rápido.")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Cómo usar")
        .navigationBarTitleDisplayMode(.inline)
    }
}
