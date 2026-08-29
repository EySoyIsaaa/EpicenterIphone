import SwiftUI

/// TEMPORARY (Phase 0b): proves the native audio chain works inside the SwiftUI app —
/// import → SQLite library → engine → playback + live state. Replaced by the real player
/// in Phase 1.
struct EngineTestScreen: View {
    @StateObject private var audio = AudioService.shared

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 22) {
                Text("Motor nativo")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)

                Text("Biblioteca: \(audio.libraryCount) canciones")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)

                VStack(spacing: 4) {
                    Text(audio.title)
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                        .lineLimit(1)
                    Text(audio.artist)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                    Text(String(format: "%.0f / %.0f s", audio.currentTime, audio.duration))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.textMuted)
                }

                HStack(spacing: 28) {
                    Button { audio.previous() } label: { Image(systemName: "backward.fill") }
                    Button { audio.togglePlayPause() } label: {
                        Image(systemName: audio.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 54))
                    }
                    Button { audio.next() } label: { Image(systemName: "forward.fill") }
                }
                .font(.title2)
                .foregroundStyle(Theme.red)

                Button("Reproducir biblioteca") { audio.playAll() }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.red)

                Button("Importar canciones") { audio.importTracks() }
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(24)
        }
        .onAppear { audio.refresh() }
    }
}
