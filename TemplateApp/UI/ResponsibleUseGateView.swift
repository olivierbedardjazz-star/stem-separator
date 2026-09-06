import AppKit
import SwiftUI

struct ResponsibleUseGateView: View {
    let settingsStore: AppSettingsStore

    private let palette = AppThemeKey.jazzAtelier.palette

    var body: some View {
        ZStack {
            AppShellBackgroundView(palette: palette)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                TemplateBrandColumnView(palette: palette)

                VStack(alignment: .leading, spacing: 14) {
                    Text("Responsible Use")
                        .font(AppTypography.display(size: 26, weight: .bold))
                        .foregroundStyle(palette.textPrimary)

                    Text("Separate audio you own or have permission to process. Stem Separator works locally on your Mac and creates vocals, drums, bass and other stems. Results may contain artifacts.")
                        .font(AppTypography.ui(size: 15, weight: .medium))
                        .foregroundStyle(palette.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("This is a free local evaluation build. Model redistribution rights must be resolved before public release. Acceptance is stored only on this Mac.")
                        .font(AppTypography.ui(size: 13, weight: .semibold))
                        .foregroundStyle(palette.textMuted)
                }
                .padding(24)
                .frame(maxWidth: 560, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(palette.panelSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(palette.borderSubtle, lineWidth: 1)
                )

                HStack(spacing: 12) {
                    SecondaryActionButton(
                        title: "Quit",
                        systemImage: "xmark",
                        palette: palette
                    ) {
                        NSApp.terminate(nil)
                    }

                    PrimaryActionButton(
                        title: "I Accept",
                        systemImage: nil,
                        palette: palette,
                        isDefaultAction: true,
                        defersActionUntilNextRunLoop: false
                    ) {
                        settingsStore.acceptResponsibleUse()
                    }
                }
            }
            .padding(32)
        }
    }
}
