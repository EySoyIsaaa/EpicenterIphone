import SwiftUI

/// Central place for the brand palette so every screen stays consistent as we port them.
/// Values mirror the web app's CSS variables (--ep-red, backgrounds, text).
enum Theme {
    static let red = Color(red: 1.0, green: 0.06, blue: 0.16)          // --ep-red
    static let background = Color(red: 0.02, green: 0.02, blue: 0.02)  // near-black page bg
    static let card = Color(red: 0.06, green: 0.06, blue: 0.06)        // premium-card
    static let border = Color.white.opacity(0.08)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textMuted = Color.white.opacity(0.4)
}
