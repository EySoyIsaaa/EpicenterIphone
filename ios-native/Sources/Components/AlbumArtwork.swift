import SwiftUI
import UIKit

/// Carátula desde un path de archivo (o placeholder si no hay).
struct AlbumArtwork: View {
    let path: String?
    var size: CGFloat = 60

    var body: some View {
        Group {
            if let image = loadImage() {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                ZStack {
                    Theme.card
                    Image(systemName: "music.note")
                        .font(.system(size: size * 0.35))
                        .foregroundStyle(Theme.textMuted)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size > 100 ? 18 : 8))
    }

    private func loadImage() -> UIImage? {
        guard let path, !path.isEmpty else { return nil }
        let file = path.hasPrefix("file://") ? (URL(string: path)?.path ?? path) : path
        return UIImage(contentsOfFile: file)
    }
}
