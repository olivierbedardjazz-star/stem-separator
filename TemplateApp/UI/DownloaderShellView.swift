import SwiftUI

struct DownloaderShellView: View {
    static let maximumShellWidth: CGFloat = AppWindowMetrics.maximumShellWidth
    static let sideBySidePanelWidth: CGFloat = AppWindowMetrics.sideBySidePanelWidth
    static let panelSpacing: CGFloat = AppWindowMetrics.panelSpacing

    @ObservedObject var shellState: TemplateShellState
    let canPerformPrimaryAction: Bool
    let selectedTheme: AppThemeKey
    @Binding var isThemeMenuOpen: Bool
    let onThemeSelected: (AppThemeKey) -> Void
    let onRequestLegalDocument: (AppLegalDocumentID) -> Void
    let onPrimaryAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            topShell
            lanePanels
            actionBand
        }
        .frame(maxWidth: Self.maximumShellWidth, maxHeight: .infinity, alignment: .topLeading)
    }

    private var topShell: some View {
        HStack(alignment: .top, spacing: 20) {
            TemplateBrandColumnView(palette: selectedTheme.palette)

            Spacer(minLength: 12)

            AppHeaderBannerView(palette: selectedTheme.palette)

            Spacer(minLength: 12)

            ThemeCornerView(
                selectedTheme: selectedTheme,
                isMenuOpen: $isThemeMenuOpen,
                options: AppThemeCatalog.options,
                palette: selectedTheme.palette,
                onThemeSelected: onThemeSelected
            )
        }
        .zIndex(20)
    }

    private var lanePanels: some View {
        HStack(alignment: .top, spacing: Self.panelSpacing) {
            TemplateFeaturePanelView(content: { AudioInputPanelView(store: shellState, palette: selectedTheme.palette) }, palette: selectedTheme.palette)
                .frame(width: Self.sideBySidePanelWidth, height: 352)
            TemplateFeaturePanelView(content: { StemOutputPanelView(store: shellState, palette: selectedTheme.palette, canPerformPrimaryAction: canPerformPrimaryAction, onPrimaryAction: onPrimaryAction) }, palette: selectedTheme.palette)
                .frame(width: Self.sideBySidePanelWidth, height: 352)
        }
    }

    private var actionBand: some View {
        AppFooterSurfaceView(
            palette: selectedTheme.palette,
            onRequestLegalDocument: onRequestLegalDocument
        )
        .frame(maxWidth: .infinity, alignment: .bottomLeading)
    }

}

#Preview {
    DownloaderShellView(
        shellState: TemplateShellState(),
        canPerformPrimaryAction: true,
        selectedTheme: .jazzAtelier,
        isThemeMenuOpen: .constant(false),
        onThemeSelected: { _ in },
        onRequestLegalDocument: { _ in },
        onPrimaryAction: {}
    )
    .padding(32)
    .background(Color.black)
    .frame(width: AppWindowMetrics.maximumShellWidth, height: 760)
}
