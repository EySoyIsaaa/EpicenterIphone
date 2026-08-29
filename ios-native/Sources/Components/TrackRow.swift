import SwiftUI

/// Reusable song row (biblioteca, artista, álbum, cola…).
struct TrackRow: View {
    let track: NativeTrack
    var isCurrent: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Theme.card)
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
