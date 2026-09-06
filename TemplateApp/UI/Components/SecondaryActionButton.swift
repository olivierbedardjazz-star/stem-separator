import SwiftUI
import AppKit

struct SecondaryActionButton: View {
    let title: String
    let systemImage: String?
    let palette: AppThemePalette
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var isShowingPointingCursor = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 12, weight: .semibold))
                }

                Text(title)
                    .font(AppTypography.ui(size: 13, weight: .semibold))
            }
            .foregroundStyle(palette.textPrimary.opacity(isEnabled ? 1 : 0.58))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Color.white.opacity(isEnabled ? 0.04 : 0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(palette.textPrimary.opacity(isEnabled ? 0.14 : 0.08), lineWidth: 1)
            )
            .opacity(isEnabled ? 1 : 0.8)
        }
        .buttonStyle(ToneControlMotionButtonStyle())
        .onHover { hovering in
            updatePointingCursor(isHovering: hovering && isEnabled)
        }
        .onChange(of: isEnabled) { _, enabled in
            if !enabled {
                updatePointingCursor(isHovering: false)
            }
        }
    }

    private func updatePointingCursor(isHovering: Bool) {
        if isHovering {
            guard !isShowingPointingCursor else { return }
            NSCursor.pointingHand.push()
            isShowingPointingCursor = true
            return
        }

        guard isShowingPointingCursor else { return }
        NSCursor.pop()
        isShowingPointingCursor = false
    }
}
