import SwiftUI
import UIKit

/// Paleta de marca. Los colores se adaptan automáticamente a claro/oscuro (el modo lo controla
/// `ThemeStore` vía `preferredColorScheme`). El rojo de marca es igual en ambos modos.
enum Theme {
    static let red = Color(red: 1.0, green: 0.06, blue: 0.16)          // --ep-red

    static let background = dynamic(
        light: UIColor(red: 0.97, green: 0.97, blue: 0.98, alpha: 1),
        dark: UIColor(red: 0.02, green: 0.02, blue: 0.02, alpha: 1))
    static let card = dynamic(
        light: UIColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1),
        dark: UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 1))
    static let border = dynamic(
        light: UIColor.black.withAlphaComponent(0.10),
        dark: UIColor.white.withAlphaComponent(0.08))
    static let textPrimary = dynamic(
        light: UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1),
        dark: UIColor.white)
    static let textSecondary = dynamic(
        light: UIColor.black.withAlphaComponent(0.6),
        dark: UIColor.white.withAlphaComponent(0.6))
    static let textMuted = dynamic(
        light: UIColor.black.withAlphaComponent(0.4),
        dark: UIColor.white.withAlphaComponent(0.4))

    private static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traits in traits.userInterfaceStyle == .dark ? dark : light })
    }
}

/// Modo de apariencia elegido por el usuario (Sistema / Claro / Oscuro), persistido.
final class ThemeStore: ObservableObject {
    static let shared = ThemeStore()

    enum Mode: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: String { rawValue }
        var label: String { self == .system ? L("Sistema", "System") : self == .light ? L("Claro", "Light") : L("Oscuro", "Dark") }
    }

    @Published var mode: Mode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: "appTheme") }
    }

    private init() {
        mode = Mode(rawValue: UserDefaults.standard.string(forKey: "appTheme") ?? "dark") ?? .dark
    }

    var colorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
