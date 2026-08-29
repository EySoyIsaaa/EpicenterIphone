import SwiftUI

/// Entry point of the native (SwiftUI) EpicenterDSP Player.
///
/// This replaces the Capacitor/WebView shell. The native audio, DSP, library and CarPlay
/// services are brought in over the next phases; for now this boots the tab shell so we can
/// confirm the project builds, signs and launches.
@main
struct EpicenterApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)   // the app is dark-first (see Ajustes later)
        }
    }
}
