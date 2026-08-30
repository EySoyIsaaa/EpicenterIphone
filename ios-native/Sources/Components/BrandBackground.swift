import SwiftUI

/// Fondo de marca: base + resplandor rojo superior. Se usa en todas las pantallas
/// para dar consistencia (antes solo estaba en el reproductor).
struct BrandBackground: View {
    var body: some View {
        ZStack {
            Theme.background
            RadialGradient(colors: [Theme.red.opacity(0.16), .clear],
                           center: .top, startRadius: 0, endRadius: 460)
        }
        .ignoresSafeArea()
    }
}
