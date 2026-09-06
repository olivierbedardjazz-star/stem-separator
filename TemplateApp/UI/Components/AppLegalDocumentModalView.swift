import SwiftUI

struct AppLegalDocumentModalView: View {
    let activeDocumentID: AppLegalDocumentID
    let palette: AppThemePalette
    let onRequestClose: () -> Void

    private var activeDocument: AppLegalDocument? {
        AppLegalDocumentCatalog.document(for: activeDocumentID)
    }

    var body: some View {
        if let activeDocument {
            ZStack {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture(perform: onRequestClose)

                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Stem Separator Legal")
                                .font(AppTypography.ui(size: 12, weight: .semibold))
                                .tracking(1.4)
                                .foregroundStyle(palette.textSecondary.opacity(0.76))
                                .textCase(.uppercase)

                            Text(activeDocument.title)
                                .font(AppTypography.display(size: 30, weight: .semibold))
                                .foregroundStyle(palette.textPrimary)
                        }

                        Spacer(minLength: 12)

                        SecondaryActionButton(
                            title: "Close",
                            systemImage: nil,
                            palette: palette,
                            action: onRequestClose
                        )
                        .keyboardShortcut(.cancelAction)
                    }

                    ScrollView(showsIndicators: true) {
                        Text(activeDocument.body)
                            .font(AppTypography.ui(size: 13))
                            .lineSpacing(5)
                            .foregroundStyle(palette.textPrimary.opacity(0.88))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .padding(24)
                .frame(width: 760, height: 560, alignment: .topLeading)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(palette.panelStrong.opacity(0.96))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(palette.textPrimary.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 28, x: 0, y: 18)
            }
            .transition(.opacity)
        }
    }
}
