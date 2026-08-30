import SwiftUI
import UIKit

/// Info de calidad derivada de la pista (bit depth, kHz, kbps, Hi-Res).
extension NativeTrack {
    var effectiveBitDepth: Int? { originalBitDepth ?? bitDepth }
    var effectiveSampleRate: Int? { originalSampleRate ?? sampleRate }
    var effectiveBitrate: Int? { originalBitrate ?? bitrate }

    var isHiRes: Bool {
        if qualityClass == "hi-res" || qualityClass == "studio" { return true }
        if let bd = effectiveBitDepth, bd >= 24 { return true }
        if let sr = effectiveSampleRate, sr > 48000 { return true }
        return false
    }

    /// Chips como en la web: "24 BIT", "44.1 kHz", "320 kbps".
    var qualityChips: [String] {
        var chips: [String] = []
        if let bd = effectiveBitDepth, bd > 0 { chips.append("\(bd) BIT") }
        if let sr = effectiveSampleRate, sr > 0 {
            let khz = (Double(sr) / 100).rounded() / 10   // 44100 -> 44.1
            chips.append(khz == khz.rounded() ? "\(Int(khz)) kHz" : "\(khz) kHz")
        }
        if let br = effectiveBitrate, br > 0 {
            chips.append("\(Int((Double(br) / 1000).rounded())) kbps")
        }
        return chips
    }
}

/// Info de calidad para el reproductor: insignia Hi-Res grande (arriba) + chips bit/kHz/kbps.
/// Cuando la pista es Hi-Res, los chips llevan contorno y texto dorados.
struct QualityChips: View {
    let track: NativeTrack
    static let gold = Color(red: 0.85, green: 0.68, blue: 0.36)

    var body: some View {
        let hi = track.isHiRes
        return VStack(spacing: 10) {
            if hi { HiResBadge(height: 42) }
            HStack(spacing: 7) {
                ForEach(track.qualityChips, id: \.self) { chip in
                    Text(chip)
                        .font(.system(size: 11, weight: .bold))
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .background(Theme.card, in: Capsule())
                        .overlay(Capsule().stroke(hi ? QualityChips.gold : Theme.border, lineWidth: 1))
                        .foregroundStyle(hi ? QualityChips.gold : Theme.textSecondary)
                }
            }
        }
    }
}

/// Insignia oficial "Hi-Res AUDIO" (asset "HiResLogo") sobre fondo transparente.
/// Si el asset falta, dibuja una insignia dorada nativa equivalente.
struct HiResBadge: View {
    var height: CGFloat = 22

    var body: some View {
        if let logo = UIImage(named: "HiResLogo") {
            Image(uiImage: logo)
                .resizable()
                .scaledToFit()
                .frame(height: height)
        } else {
            nativeBadge
        }
    }

    private var nativeBadge: some View {
        HStack(spacing: 3) {
            Text("Hi-Res")
                .font(.system(size: 11, weight: .black, design: .serif))
                .italic()
            Text("AUDIO")
                .font(.system(size: 7, weight: .black))
                .padding(.top, 2)
        }
        .padding(.horizontal, 7).padding(.vertical, 3)
        .background(
            LinearGradient(colors: [Color(red: 0.87, green: 0.78, blue: 0.49),
                                    Color(red: 0.71, green: 0.50, blue: 0.17)],
                           startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 5)
        )
        .foregroundStyle(Color(red: 0.15, green: 0.09, blue: 0.03))
    }
}
