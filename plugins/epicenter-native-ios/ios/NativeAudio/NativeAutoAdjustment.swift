import Foundation

struct NativeAudioAnalysis: Codable {
    let gains: [Float]
    let bassRelativeDb: Float
    let deepBassRatio: Float
    let bassCentroidHz: Float

    var isValid: Bool {
        NativeAutoAdjustment.accepts(gains) && bassRelativeDb.isFinite
            && deepBassRatio.isFinite && (0...1).contains(deepBassRatio)
            && bassCentroidHz.isFinite && (20...200).contains(bassCentroidHz)
    }
}

/// Derives Epicenter settings from the measured per-song correction, independently
/// of applying that correction to the equalizer. It never enables either processor.
enum NativeAutoAdjustment {
    struct EpicenterSettings {
        let intensity: Double
        let sweep: Double
        let width: Double
        let balance: Double
    }

    static func accepts(_ gains: [Float]) -> Bool {
        gains.count == 31 && gains.allSatisfy { $0.isFinite && abs($0) <= 8 }
    }

    static func epicenter(analysis: NativeAudioAnalysis, headphones: Bool) -> EpicenterSettings? {
        guard analysis.isValid else { return nil }
        func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
            min(max(value, low), high)
        }

        // Use the measured spectrum, NOT the clipped EQ gains. Bass corrections
        // often all hit -6 dB, which used to produce identical settings per song.
        let bass = Double(analysis.bassRelativeDb)
        let deep = Double(analysis.deepBassRatio)
        let centroid = Double(analysis.bassCentroidHz)
        return EpicenterSettings(
            intensity: clamp((headphones ? 78 : 91) - (bass - 5) * (headphones ? 0.9 : 1.2), 35, headphones ? 95 : 100),
            sweep: clamp(centroid * 0.5, 27, 63),
            width: clamp(74 - deep * 42, 30, 74),
            balance: clamp(96 - max(0, bass - 8) * 0.65, 74, 100)
        )
    }
}
