import SwiftUI

struct ThemeBloomOverlayView: View {
    let palette: AppThemePalette

    @State private var animate = false

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    palette.accentPrimary.opacity(0.22),
                    palette.accentTertiary.opacity(0.16),
                    palette.accentTertiary.opacity(0.06),
                    .clear
                ],
                center: UnitPoint(x: 0.84, y: 0.12),
                startRadius: 0,
                endRadius: 360
            )
            .scaleEffect(animate ? 1.24 : 0.72)
            .opacity(animate ? 0 : 0.86)
            .blur(radius: 2)

            RadialGradient(
                colors: [
                    palette.accentPrimary.opacity(0.18),
                    palette.accentTertiary.opacity(0.12),
                    palette.accentPrimary.opacity(0.03),
                    .clear
                ],
                center: UnitPoint(x: 0.78, y: 0.14),
                startRadius: 0,
                endRadius: 420
            )
            .scaleEffect(animate ? 1.14 : 0.88)
            .opacity(animate ? 0 : 0.42)
            .blur(radius: 18)

            LinearGradient(
                colors: [Color.white.opacity(0.06), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(animate ? 0 : 0.46)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(AppMotion.bloom) {
                animate = true
            }
        }
    }
}

#Preview {
    ThemeBloomOverlayView(palette: AppThemeKey.obsidianPulse.palette)
        .background(Color.black)
}
