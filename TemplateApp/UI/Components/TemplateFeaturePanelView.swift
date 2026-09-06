import SwiftUI

struct TemplateFeaturePanelView<Content: View>: View {
    static var fixedHeight: CGFloat { TemplatePanelMetrics.panelHeight }

    @ViewBuilder let content: () -> Content
    let palette: AppThemePalette

    var body: some View {
        content()
            .frame(
            maxWidth: .infinity,
            minHeight: TemplatePanelMetrics.panelHeight,
            maxHeight: TemplatePanelMetrics.panelHeight,
            alignment: .topLeading
        )
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(palette.panelSurface)
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.05), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .mask(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .frame(height: 90)
                }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(palette.borderSubtle, lineWidth: 1)
        )
        .shadow(color: palette.shadowPanelColor, radius: 20, x: 0, y: 14)
    }
}

private enum TemplatePanelMetrics {
    static let panelHeight: CGFloat = 352
}
