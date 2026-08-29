import SwiftUI

/// Barra de reproducción sobre la barra de pestañas. Al tocarla abre el reproductor (Inicio).
struct MiniPlayer: View {
    @ObservedObject private var audio = AudioService.shared
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AlbumArtwork(path: audio.artworkPath, size: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(audio.title).font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary).lineLimit(1)
                Text(audio.artist).font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary).lineLimit(1)
            }
            Spacer(minLength: 6)
            Button { audio.togglePlayPause() } label: {
                Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3).foregroundStyle(Theme.textPrimary)
            }
            Button { audio.next() } label: {
                Image(systemName: "forward.fill").foregroundStyle(Theme.textPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Theme.border, lineWidth: 0.5))
        .padding(.horizontal, 8)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}
