import SwiftUI
import AppKit

struct AudioInputPanelView: View {
    @ObservedObject var store: SeparationStore
    let palette: AppThemePalette
    @State private var targeted = false
    @State private var isShowingRemoveCursor = false
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Your audio", systemImage: "waveform")
                    .font(AppTypography.display(size: 21, weight: .semibold))
                Spacer()
            }
            VStack(spacing: 12) {
                Image(systemName: store.selection == nil ? "arrow.down.document" : "waveform.circle.fill")
                    .font(.system(size: 36, weight: .light)).foregroundStyle(palette.accentPrimary)
                Text(store.isInspecting ? "Reading audio…" : store.selection?.url.lastPathComponent ?? "Drop your audio here")
                    .font(AppTypography.ui(size: 16, weight: .semibold)).lineLimit(2).multilineTextAlignment(.center)
                Text(store.selection?.description ?? "WAV, AIFF, MP3 or M4A · up to 20 minutes")
                    .font(AppTypography.ui(size: 12)).foregroundStyle(palette.textSecondary)
                SecondaryActionButton(title: store.selection == nil ? "Choose Audio" : "Replace Audio", systemImage: "folder", palette: palette) { store.chooseAudio() }
                    .disabled(!store.canSelect)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 18).fill(palette.accentPrimary.opacity(targeted ? 0.10 : 0.025)))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(palette.accentPrimary.opacity(targeted ? 0.8 : 0.23), style: StrokeStyle(lineWidth: 1, dash: [5, 5])))
            .overlay(alignment: .topTrailing) {
                if store.selection != nil || store.isInspecting {
                    Button {
                        updateRemoveCursor(isHovering: false)
                        store.clearAudio()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(palette.textSecondary)
                            .frame(width: 30, height: 30)
                            .background(Circle().fill(palette.textPrimary.opacity(0.06)))
                            .contentShape(Circle())
                    }
                    .buttonStyle(ToneControlMotionButtonStyle(hoverOverride: isShowingRemoveCursor))
                    .accessibilityLabel("Remove selected audio")
                    .help("Clear this selection. Your original file is kept.")
                    .disabled(!store.canSelect)
                    .onHover { hovering in
                        updateRemoveCursor(isHovering: hovering && store.canSelect)
                    }
                    .onChange(of: store.canSelect) { _, enabled in
                        if !enabled { updateRemoveCursor(isHovering: false) }
                    }
                    .onDisappear { updateRemoveCursor(isHovering: false) }
                    .padding(10)
                }
            }
            .contentShape(Rectangle())
            .dropDestination(for: URL.self) { urls, _ in
                guard store.canSelect else { return false }
                store.accept(urls); return true
            } isTargeted: { targeted = $0 && store.canSelect }
        }
        .foregroundStyle(palette.textPrimary).padding(24)
    }

    private func updateRemoveCursor(isHovering: Bool) {
        if isHovering {
            guard !isShowingRemoveCursor else { return }
            NSCursor.pointingHand.push()
            withAnimation(AppMotion.ease) {
                isShowingRemoveCursor = true
            }
        } else {
            guard isShowingRemoveCursor else { return }
            NSCursor.pop()
            withAnimation(AppMotion.ease) {
                isShowingRemoveCursor = false
            }
        }
    }
}
