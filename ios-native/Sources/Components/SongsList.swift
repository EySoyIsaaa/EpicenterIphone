import SwiftUI

/// Reusable list of songs. Tapping a row plays that song within this list (the list
/// becomes the queue). Used by Canciones, Hi-Res, y el detalle de artista/álbum.
struct SongsList: View {
    let tracks: [NativeTrack]
    @ObservedObject private var audio = AudioService.shared

    var body: some View {
        if tracks.isEmpty {
            VStack(spacing: 10) {
                Image(systemName: "music.note").font(.system(size: 34)).foregroundStyle(Theme.textMuted)
                Text("Nada aquí todavía").foregroundStyle(Theme.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(Array(tracks.enumerated()), id: \.element.id) { index, track in
                    Button { audio.play(tracks, startAt: index) } label: {
                        TrackRow(track: track, isCurrent: audio.currentTrackId == track.id)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(Theme.border)
                }
            }
            .listStyle(.plain)
        }
    }
}
