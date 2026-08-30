import StoreKit
import UIKit

/// Aviso para calificar en la App Store (equivalente al ReviewPrompt del web).
/// Apple limita a ~3 solicitudes al año; pedimos en usos clave y con un botón en Ajustes.
enum ReviewManager {
    private static let launchKey = "reviewLaunchCount"

    /// Cuenta el uso y pide reseña en el 3er y 8º arranque (Apple decide si la muestra).
    static func registerUseAndMaybeAsk() {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: launchKey) + 1
        defaults.set(count, forKey: launchKey)
        if count == 3 || count == 8 { requestReview() }
    }

    /// Solicita la hoja de reseña del sistema (usado también por el botón de Ajustes).
    static func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
