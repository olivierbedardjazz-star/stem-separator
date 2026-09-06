import SwiftUI

struct BrandColumnView: View {
    let palette: AppThemePalette
    let titleTopLine: String
    let titleBottomLine: String

    init(
        palette: AppThemePalette,
        titleTopLine: String = "Tone",
        titleBottomLine: String = "Downloader"
    ) {
        self.palette = palette
        self.titleTopLine = titleTopLine
        self.titleBottomLine = titleBottomLine
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [palette.brandPanelStart, palette.brandPanelEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(palette.brandLogoBorder, lineWidth: 1)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(palette.brandLogoSurface)
                    )
                    .shadow(color: palette.brandLogoShadow, radius: 19, x: 0, y: 10)

                BrandLogoMarkView()
                    .padding(14)
            }
            .frame(width: 148, height: 148)

            VStack(spacing: 2) {
                Text(titleTopLine)
                    .font(AppTypography.display(size: 18, weight: .bold))
                Text(titleBottomLine)
                    .font(AppTypography.display(size: 18, weight: .bold))
            }
            .foregroundStyle(palette.accentPrimary)
            .tracking(1.7)
            .multilineTextAlignment(.center)
            .lineSpacing(1)
        }
        .frame(width: 180)
    }
}

struct TemplateBrandColumnView: View {
    let palette: AppThemePalette

    var body: some View {
        BrandColumnView(
            palette: palette,
            titleTopLine: "Stem",
            titleBottomLine: "Separator"
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        BrandColumnView(palette: AppThemeKey.jazzAtelier.palette)
        TemplateBrandColumnView(palette: AppThemeKey.jazzAtelier.palette)
    }
    .padding()
    .background(Color.black)
}
