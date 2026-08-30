import SwiftUI
import UIKit

/// Reproductor (pestaña Inicio): carátula con glow, info de calidad (bit/kHz/kbps + Hi-Res),
/// barra de tiempo, transporte y controles (favorito, playlist, cola).
struct PlayerScreen: View {
    @ObservedObject private var audio = AudioService.shared
    @ObservedObject private var favorites = LibraryStore.shared
    @ObservedObject private var loc = LocalizationStore.shared
    @State private var seeking = false
    @State private var seekValue: Double = 0
    @State private var showingQueue = false
    @State private var addTarget: TrackIdSelection?
    @State private var trackInfo: NativeTrack?

    private var isCurrentFavorite: Bool {
        audio.currentTrackId.map { favorites.isFavorite($0) } ?? false
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if audio.hasTrack {
                RadialGradient(colors: [Theme.red.opacity(0.18), .clear],
                               center: .top, startRadius: 0, endRadius: 420)
                    .ignoresSafeArea()
            }

            if !audio.hasTrack {
                emptyState
            } else {
                content
            }
        }
        .sheet(isPresented: $showingQueue) { QueueScreen() }
        .sheet(item: $addTarget) { selection in AddToPlaylistSheet(trackIds: selection.ids) }
        .onChange(of: audio.currentTrackId) { id in
            trackInfo = id.flatMap { audio.track(id: $0) }
            seeking = false
            seekValue = audio.currentTime
        }
        .onAppear {
            trackInfo = audio.currentTrackId.flatMap { audio.track(id: $0) }
            seekValue = audio.currentTime
        }
    }

    private var artSize: CGFloat { min(UIScreen.main.bounds.width - 60, 370) }

    private var content: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 6)
            Text(L("REPRODUCIENDO", "NOW PLAYING"))
                .font(.system(size: 11, weight: .black)).kerning(2.5)
                .foregroundStyle(Theme.red)

            Spacer(minLength: 22)
            AlbumArtwork(path: audio.artworkPath, size: artSize)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.border, lineWidth: 1))
                .shadow(color: .black.opacity(0.6), radius: 28, y: 16)

            Spacer(minLength: 24)
            VStack(spacing: 10) {
                Text(audio.title).font(.title.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.center).lineLimit(2)
                Text(audio.artist.isEmpty ? L("Artista desconocido", "Unknown artist") : audio.artist)
                    .font(.title3)
                    .foregroundStyle(Theme.textSecondary).lineLimit(1)
                if let track = trackInfo {
                    QualityChips(track: track).padding(.top, 4)
                }
            }

            Spacer(minLength: 24)
            seekBar

            Spacer(minLength: 20)
            transport

            Spacer(minLength: 18)
            secondaryControls
            Spacer(minLength: 8)
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 28)
        .padding(.bottom, 10)
    }

    private var transport: some View {
        HStack(spacing: 32) {
            Button { audio.cycleRepeat() } label: {
                Image(systemName: audio.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 21))
                    .foregroundStyle(audio.repeatMode == .off ? Theme.textMuted : Theme.red)
            }
            Button { audio.previous() } label: {
                Image(systemName: "backward.fill").font(.system(size: 30))
            }
            Button { audio.togglePlayPause() } label: {
                Image(systemName: audio.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 86))
            }
            Button { audio.next() } label: {
                Image(systemName: "forward.fill").font(.system(size: 30))
            }
            Button { audio.shuffleLibrary() } label: {
                Image(systemName: "shuffle").font(.system(size: 21)).foregroundStyle(Theme.textMuted)
            }
        }
        .foregroundStyle(Theme.textPrimary)
    }

    private var secondaryControls: some View {
        HStack(spacing: 50) {
            Button {
                if let id = audio.currentTrackId {
                    favorites.toggleFavorite(id)
                    audio.updateLikeCommandState()
                }
            } label: {
                Image(systemName: isCurrentFavorite ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundStyle(isCurrentFavorite ? Theme.red : Theme.textMuted)
                    .scaleEffect(isCurrentFavorite ? 1.12 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isCurrentFavorite)
            }
            Button {
                if let id = audio.currentTrackId { addTarget = TrackIdSelection(ids: [id]) }
            } label: {
                Image(systemName: "plus.circle").font(.title2).foregroundStyle(Theme.textMuted)
            }
            Button { showingQueue = true } label: {
                Image(systemName: "list.bullet").font(.title2).foregroundStyle(Theme.textMuted)
            }
        }
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
        // El tiempo avanza solo cuando NO estás arrastrando (arregla el congelamiento tras seek).
        .onChange(of: audio.currentTime) { newValue in
            if !seeking { seekValue = newValue }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.circle").font(.system(size: 54)).foregroundStyle(Theme.textMuted)
            Text(L("Nada sonando", "Nothing playing")).font(.headline).foregroundStyle(Theme.textPrimary)
            Text(L("Elige una canción en Música", "Pick a song in Music")).font(.footnote).foregroundStyle(Theme.textSecondary)
        }
    }

    private func fmt(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
