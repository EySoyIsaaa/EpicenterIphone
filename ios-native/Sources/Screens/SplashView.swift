import SwiftUI
import UIKit

/// Apertura "Bass Impact" — réplica nativa del SplashScreen del web:
/// anillos que pulsan, bloom rojo, logo con entrada tipo resorte, barrido, espectro y footer.
/// Dura ~3.6 s (con salida) y se puede saltar con un toque.
struct SplashView: View {
    let onFinish: () -> Void

    @State private var leaving = false
    @State private var logoIn = false
    @State private var sweepScale: CGFloat = 0
    @State private var sweepOpacity: Double = 0
    @State private var footerIn = false

    private var stage: CGFloat { min(UIScreen.main.bounds.width * 0.62, 280) }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                ZStack {
                    PulseRing(delay: 0.20, stage: stage)
                    PulseRing(delay: 0.43, stage: stage)
                    PulseRing(delay: 0.66, stage: stage)
                    Bloom(stage: stage)

                    Image("EpicenterLogo")
                        .resizable().scaledToFit()
                        .frame(width: stage * 0.68)
                        .scaleEffect(logoIn ? 1 : 0.62)
                        .opacity(logoIn ? 1 : 0)
                        .blur(radius: logoIn ? 0 : 10)
                        .shadow(color: Theme.red.opacity(0.35), radius: 22, y: 12)

                    Capsule()
                        .fill(LinearGradient(colors: [.clear, Theme.red, .clear], startPoint: .leading, endPoint: .trailing))
                        .frame(width: stage * 0.88, height: 2)
                        .scaleEffect(x: sweepScale, y: 1, anchor: .center)
                        .opacity(sweepOpacity)
                        .offset(y: stage * 0.30)
                }
                .frame(width: stage, height: stage)

                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<28, id: \.self) { i in SpectrumBar(index: i) }
                }
                .frame(height: 34)
            }

            VStack {
                Spacer()
                footer.padding(.bottom, 46)
            }
        }
        .opacity(leaving ? 0 : 1)
        .scaleEffect(leaving ? 1.08 : 1)
        .blur(radius: leaving ? 12 : 0)
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.62)) { logoIn = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.45)) { sweepScale = 1.02; sweepOpacity = 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    withAnimation(.easeIn(duration: 0.85)) { sweepOpacity = 0 }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.7)) { footerIn = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.08) { finish() }
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Text("v\(version)")
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 12).padding(.vertical, 3)
                .foregroundStyle(.white)
                .background(Theme.red.opacity(0.08), in: Capsule())
                .overlay(Capsule().stroke(Theme.red.opacity(0.4), lineWidth: 1))
            Text("BASS RECONSTRUCTION TECHNOLOGY")
                .font(.system(size: 10, weight: .bold)).kerning(2.8)
                .foregroundStyle(.white.opacity(0.42))
        }
        .opacity(footerIn ? 1 : 0)
        .offset(y: footerIn ? 0 : 14)
    }

    private func finish() {
        guard !leaving else { return }
        withAnimation(.easeIn(duration: 0.52)) { leaving = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.52) { onFinish() }
    }
}

/// Anillo tipo radar: aparece pequeño, se expande y se desvanece.
private struct PulseRing: View {
    let delay: Double
    let stage: CGFloat
    @State private var scale: CGFloat = 0.12
    @State private var opacity: Double = 0

    var body: some View {
        Circle()
            .strokeBorder(Theme.red.opacity(0.8), lineWidth: 2)
            .frame(width: stage * 0.42, height: stage * 0.42)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 1.9)) { scale = 2.9 }
                    withAnimation(.easeOut(duration: 0.25)) { opacity = 0.9 }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation(.easeIn(duration: 1.65)) { opacity = 0 }
                    }
                }
            }
    }
}

/// Resplandor rojo que entra y luego pulsa suavemente.
private struct Bloom: View {
    let stage: CGFloat
    @State private var appear = false
    @State private var pulse = false

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [Theme.red.opacity(0.42), .clear], center: .center, startRadius: 0, endRadius: stage * 0.39))
            .frame(width: stage * 0.78, height: stage * 0.78)
            .blur(radius: 14)
            .scaleEffect(appear ? (pulse ? 1.08 : 1.0) : 0.4)
            .opacity(appear ? 1 : 0)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeInOut(duration: 1.1)) { appear = true }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { pulse = true }
                }
            }
    }
}

/// Barra del espectro: sube a su pico y oscila.
private struct SpectrumBar: View {
    let index: Int
    @State private var up = false

    private var peak: CGFloat { 0.36 + CGFloat((index * 37) % 52) / 100.0 }

    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: [Theme.red, Theme.red.opacity(0.35)], startPoint: .top, endPoint: .bottom))
            .frame(width: 3, height: max(3, 34 * (up ? peak : 0.08)))
            .opacity(up ? 1 : 0)
            .onAppear {
                let delay = 0.95 + Double(index % 7) * 0.04
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) { up = true }
                }
            }
    }
}
