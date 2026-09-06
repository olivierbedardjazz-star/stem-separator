import SwiftUI

struct RootView: View {
    @ObservedObject var shellState: TemplateShellState
    @ObservedObject var commandDispatcher: AppCommandDispatcher
    @AppStorage("stem-separator.v1.theme") private var selectedThemeRawValue = AppThemeKey.jazzAtelier.rawValue

    @State private var isThemeMenuOpen = false
    @State private var themeBloomToken: UUID?
    @State private var themeBloomResetWorkItem: DispatchWorkItem?
    @State private var activeLegalDocumentID: AppLegalDocumentID?

    var body: some View {
        GeometryReader { _ in
            ZStack {
                AppShellBackgroundView(palette: selectedTheme.palette)
                    .ignoresSafeArea()

                if let themeBloomToken {
                    ThemeBloomOverlayView(palette: selectedTheme.palette)
                        .id(themeBloomToken)
                        .allowsHitTesting(false)
                }

                if isThemeMenuOpen {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(AppMotion.ease) {
                                isThemeMenuOpen = false
                            }
                        }
                }

                DownloaderShellView(
                    shellState: shellState,
                    canPerformPrimaryAction: commandDispatcher.canPerformPrimaryAction,
                    selectedTheme: selectedTheme,
                    isThemeMenuOpen: $isThemeMenuOpen,
                    onThemeSelected: applyThemeSelection,
                    onRequestLegalDocument: openLegalDocument,
                    onPrimaryAction: commandDispatcher.performPrimaryAction
                )
                .padding(AppWindowMetrics.shellPadding())
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                if let activeLegalDocumentID {
                    AppLegalDocumentModalView(
                        activeDocumentID: activeLegalDocumentID,
                        palette: selectedTheme.palette,
                        onRequestClose: closeLegalDocument
                    )
                }
            }
        }
    }

    private var selectedTheme: AppThemeKey {
        AppThemeCatalog.theme(for: selectedThemeRawValue)
    }

    private func applyThemeSelection(_ theme: AppThemeKey) {
        guard theme != selectedTheme else {
            withAnimation(AppMotion.ease) {
                isThemeMenuOpen = false
            }
            return
        }

        selectedThemeRawValue = theme.rawValue
        withAnimation(AppMotion.ease) {
            isThemeMenuOpen = false
        }
        replayThemeBloom()
    }

    private func replayThemeBloom() {
        themeBloomResetWorkItem?.cancel()

        let workItem = DispatchWorkItem {
            themeBloomToken = nil
            themeBloomResetWorkItem = nil
        }

        themeBloomToken = UUID()
        themeBloomResetWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + AppMotion.shellBloomDuration, execute: workItem)
    }

    private func openLegalDocument(_ documentID: AppLegalDocumentID) {
        activeLegalDocumentID = documentID
    }

    private func closeLegalDocument() {
        activeLegalDocumentID = nil
    }
}
