import Combine
import Foundation

/// Idioma de la app (Español / English), persistido y conmutable en caliente.
/// Las vistas que muestran texto observan este store para re-renderizar al cambiar idioma.
final class LocalizationStore: ObservableObject {
    static let shared = LocalizationStore()

    enum Lang: String, CaseIterable, Identifiable {
        case es, en
        var id: String { rawValue }
        var label: String { self == .es ? "Español" : "English" }
        var flag: String { self == .es ? "🇪🇸" : "🇺🇸" }
    }

    @Published var language: Lang {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"), let lang = Lang(rawValue: saved) {
            language = lang
        } else {
            let preferred = Locale.preferredLanguages.first ?? "es"
            language = preferred.hasPrefix("en") ? .en : .es
        }
    }
}

/// Traducción en línea: `L("texto en español", "text in english")`.
/// Devuelve el string según el idioma actual. Para que reaccione al cambio, la vista
/// que lo usa debe observar `LocalizationStore.shared`.
func L(_ es: String, _ en: String) -> String {
    LocalizationStore.shared.language == .en ? en : es
}
