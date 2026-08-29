import SwiftUI

/// Fase 1: reproductor completo (pestaña Inicio). Carátula, seek, transporte, repeat, shuffle.
struct PlayerScreen: View {
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var favorites = LibraryStore.shared
    @State private var seeking = false
    @State private var seekValue: Double = 0
    @State private var showingQueue = false
    @State private var addTarget: TrackIdSelection?

    private var isCurrentFavorite: Bool {
        audio.currentTrackId.map { favorites.isFavorite($0) } ?? false
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if !audio.hasTrack {
                emptyState
            } else {
                VStack(spacing: 22) {
                    Spacer(minLength: 8)
                    AlbumArtwork(path: audio.artworkPath, size: 300)
                        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)

                    VStack(spacing: 6) {
                        Text(audio.title).font(.title3.weight(.bold))
                            .foregroundStyle(Theme.textPrimary).lineLimit(1)
                        Text(audio.artist.isEmpty ? "Artista desconocido" : audio.artist)
                            .foregroundStyle(Theme.textSecondary).lineLimit(1)
                    }

                    seekBar

                    HStack(spacing: 34) {
                        Button { audio.cycleRepeat() } label: {
                            Image(systemName: audio.repeatMode == .one ? "repeat.1" : "repeat")
                                .foregroundStyle(audio.repeatMode == .off ? Theme.textMuted : Theme.red)
                        }
                        Button { audio.previous() } label: { Image(systemName: "backward.fill").font(.title) }
                        Button { audio.togglePlayPause() } label: {
                            Image(systemName: audio.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 66))
                        }
                        Button { audio.next() } label: { Image(systemName: "forward.fill").font(.title) }
                        Button { audio.shuffleLibrary() } label: {
                            Image(systemName: "shuffle").foregroundStyle(Theme.textMuted)
                        }
                    }
                    .foregroundStyle(Theme.textPrimary)

                    secondaryControls
                    Spacer()
                }
                .padding(24)
            }
        }
        .sheet(isPresented: $showingQueue) { QueueScreen() }
        .sheet(item: $addTarget) { selection in AddToPlaylistSheet(trackIds: selection.ids) }
    }

    private var secondaryControls: some View {
        HStack(spacing: 44) {
            Button {
                if let id = audio.currentTrackId {
                    favorites.toggleFavorite(id)
                    audio.updateLikeCommandState()
                }
            } label: {
                Image(systemName: isCurrentFavorite ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(isCurrentFavorite ? Theme.red : Theme.textMuted)
            }
            Button {
                if let id = audio.currentTrackId { addTarget = TrackIdSelection(ids: [id]) }
            } label: {
                Image(systemName: "plus.circle").font(.title3).foregroundStyle(Theme.textMuted)
            }
            Button { showingQueue = true } label: {
                Image(systemName: "list.bullet").font(.title3).foregroundStyle(Theme.textMuted)
            }
        }
        .padding(.top, 4)
    }

    private var seekBar: some View {
        VStack(spacing: 4) {
            Slider(
                value: $seekValue,
                in: 0...max(audio.duration, 1),
                onEditingChanged: { editing in
                    if editing {
                        seeking = true
                    } else {
                        audio.seek(to: seekValue)
                        seeking = false
                    }
                }
            )
            .tint(Theme.red)
            HStack {
                Text(fmt(seekValue))
                Spacer()
                Text(fmt(audio.duration))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(Theme.textMuted)
        }
        // El tiempo avanza solo cuando NO estás arrastrando; al soltar, currentTime
        // retoma y `seekValue` vuelve a seguirlo (arregla el congelamiento tras seek).
        .onChange(of: audio.currentTime) { newValue in
            if !seeking { seekValue = newValue }
        }
        .onChange(of: audio.currentTrackId) { _ in
            seeking = false
            seekValue = audio.currentTime
        }
        .onAppear { seekValue = audio.currentTime }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.circle").font(.system(size: 54)).foregroundStyle(Theme.textMuted)
            Text("Nada sonando").font(.headline).foregroundStyle(Theme.textPrimary)
            Text("Elige una canción en Mi Música").font(.footnote).foregroundStyle(Theme.textSecondary)
        }
    }

    private func fmt(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
