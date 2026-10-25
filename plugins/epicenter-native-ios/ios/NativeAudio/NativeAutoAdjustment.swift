import Foundation

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

    static func epicenter(gains: [Float], headphones: Bool) -> EpicenterSettings? {
        guard accepts(gains) else { return nil }
        func mean(_ indices: ClosedRange<Int>) -> Double {
            indices.reduce(0.0) { $0 + Double(gains[$1]) } / Double(indices.count)
        }
        func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
            min(max(value, low), high)
        }

        // Positive correction means this song needs more energy in that region.
        // Bass-rich masters receive less reconstruction; lean ones receive more.
        let bassNeed = mean(2...9)
        let deepNeed = mean(2...5)
        let upperBassNeed = mean(6...9)
        return EpicenterSettings(
            intensity: clamp((headphones ? 65 : 76) + bassNeed * 5, headphones ? 38 : 45, headphones ? 90 : 100),
            sweep: clamp(45 + (upperBassNeed - deepNeed) * 1.8, 32, 58),
            width: clamp(50 + deepNeed * 3, 32, 68),
            balance: clamp(90 + bassNeed * 2, 78, 100)
        )
    }
}
