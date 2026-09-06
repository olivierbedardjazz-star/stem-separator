import SwiftUI

struct AppShellBackgroundView: View {
    let palette: AppThemePalette

    var body: some View {
        ZStack {
            palette.background

            LinearGradient(
                colors: [palette.shellGradientStart, palette.shellGradientEnd],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [palette.shellGlowLeft, .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 420
            )
            .blendMode(.screen)

            RadialGradient(
                colors: [palette.shellGlowRight, .clear],
                center: UnitPoint(x: 0.92, y: 0.08),
                startRadius: 0,
                endRadius: 380
            )
            .blendMode(.screen)
        }
    }
}

#Preview {
    AppShellBackgroundView(palette: AppThemeKey.cosmicComposer.palette)
}
