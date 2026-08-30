import SwiftUI

/// Reusable song row (biblioteca, artista, álbum, cola…).
struct TrackRow: View {
    let track: NativeTrack
    var isCurrent: Bool = false
    @ObservedObject private var favorites = LibraryStore.shared
    @ObservedObject private var loc = LocalizationStore.shared

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                AlbumArtwork(path: track.albumArtUri, size: 46)
                if isCurrent {
                    RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.45))
                    Image(systemName: "waveform").foregroundStyle(Theme.red)
                }
            }
            .frame(width: 46, height: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(isCurrent ? Theme.red : Theme.textPrimary)
                    .lineLimit(1)
                Text(track.artist ?? L("Artista desconocido", "Unknown artist"))
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            if favorites.isFavorite(track.id) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.red)
            }
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
