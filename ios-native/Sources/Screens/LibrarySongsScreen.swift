import SwiftUI

/// Fase 2: la biblioteca (lista de canciones). Toca una para reproducirla.
/// Las divisiones (Artistas/Álbumes/Hi-Res/Playlists) se agregan después.
struct LibrarySongsScreen: View {
    @StateObject private var audio = AudioService.shared
    @State private var tracks: [NativeTrack] = []

    var body: some View {
        NavigationView {
            ZStack {
                Theme.background.ignoresSafeArea()
                if tracks.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                            TrackRow(track: track, isCurrent: audio.currentTrackId == track.id)
                                .contentShape(Rectangle())
                                .onTapGesture { audio.play(tracks, startAt: index) }
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(Theme.border)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Mi Música")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { audio.importTracks() } label: {
                        Image(systemName: "plus.circle.fill").foregroundStyle(Theme.red)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear(perform: reload)
    }

    private func reload() { tracks = audio.loadLibrary() }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "music.note.list")
                .font(.system(size: 46))
                .foregroundStyle(Theme.textMuted)
            Text("Tu biblioteca está vacía")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            Button("Importar canciones") { audio.importTracks() }
                .buttonStyle(.borderedProminent)
                .tint(Theme.red)
        }
    }
}

private struct TrackRow: View {
    let track: NativeTrack
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Theme.card)
                    .frame(width: 46, height: 46)
                Image(systemName: isCurrent ? "waveform" : "music.note")
                    .foregroundStyle(isCurrent ? Theme.red : Theme.textMuted)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isCurrent ? Theme.red : Theme.textPrimary)
                    .lineLimit(1)
                Text(track.artist ?? "Artista desconocido")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if let tag = qualityTag {
                Text(tag.label)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(tag.color.opacity(0.16))
                    .foregroundStyle(tag.color)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }

    private var qualityTag: (label: String, color: Color)? {
        switch track.qualityClass {
        case "studio", "hi-res": return ("HI-RES", Theme.red)
        case "cd", "lossless":   return ("LOSSLESS", .cyan)
        default:                 return nil
        }
    }
}
