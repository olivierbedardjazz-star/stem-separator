import SwiftUI

struct StemOutputPanelView: View {
    @ObservedObject var store: SeparationStore
    let palette: AppThemePalette
    let canPerformPrimaryAction: Bool
    let onPrimaryAction: () -> Void
    @State private var preservingPrimaryPulse = false
    private let icons = ["mic", "circle.grid.2x2.fill", "guitars", "pianokeys"]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your stems").font(AppTypography.display(size: 21, weight: .semibold))
                Spacer()
            }
            HStack(spacing: 10) {
                ForEach(Array(StemOutputWriter.names.enumerated()), id: \.offset) { index, name in
                    VStack(spacing: 8) {
                        Image(systemName: icons[index]).font(.system(size: 20, weight: .light)).foregroundStyle(palette.accentPrimary).frame(height: 24)
                        Text(name == "other" ? "🎁 Surprise" : name.capitalized).font(AppTypography.ui(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.035)))
                }
            }
            VStack(spacing: 20) {
                separationActions
                if store.stage != nil || store.message != nil || store.result != nil {
                    status.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .foregroundStyle(palette.textPrimary).padding(24)
    }
    private var separationActions: some View {
        HStack(spacing: 12) {
            if store.isBusy {
                SecondaryActionButton(title: "Cancel", systemImage: nil, palette: palette) { store.cancel() }
                    .disabled(store.stage == .cancelling)
            }
            TemplatePrimaryActionButton(title: "Separate Stems", systemImage: nil, palette: palette) {
                guard canPerformPrimaryAction else { return }
                preservingPrimaryPulse = true
                onPrimaryAction()
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(AppMotion.shellBloomDuration))
                    preservingPrimaryPulse = false
                }
            }
            .disabled(!canPerformPrimaryAction && !preservingPrimaryPulse)
            .allowsHitTesting(canPerformPrimaryAction)
        }
    }
    @ViewBuilder private var status: some View {
        if let stage = store.stage {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(stage.title).font(AppTypography.ui(size: 13, weight: .semibold))
                    Spacer()
                    if let progress = store.progress { Text("\(Int(progress * 100))%").font(AppTypography.ui(size: 12)).monospacedDigit() }
                }
                if let progress = store.progress { ProgressView(value: progress).tint(palette.accentPrimary) }
                else { ProgressView().controlSize(.small) }
            }
            .accessibilityElement(children: .combine)
        } else if let message = store.message {
            Text(message).font(AppTypography.ui(size: 12, weight: .medium)).foregroundStyle(palette.textSecondary).fixedSize(horizontal: false, vertical: true)
        } else if store.result != nil {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Your four stems are ready", systemImage: "checkmark.circle.fill")
                        .font(AppTypography.ui(size: 13, weight: .semibold)).foregroundStyle(palette.accentPrimary)
                }
                Spacer(minLength: 4)
                SecondaryActionButton(title: "Show in Finder", systemImage: nil, palette: palette) { store.reveal() }
            }
        }
    }
}
