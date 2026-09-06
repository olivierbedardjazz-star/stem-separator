import SwiftUI

struct AppFooterSurfaceView: View {
    let palette: AppThemePalette
    let onRequestLegalDocument: (AppLegalDocumentID) -> Void

    var body: some View {
        HStack(spacing: 18) {
            legalLinks
            socialLinks
        }
        .padding(.top, 6)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var legalLinks: some View {
        HStack(spacing: 18) {
            ForEach(AppLegalDocumentCatalog.documents) { document in
                AppFooterTextLinkButton(
                    title: document.label,
                    palette: palette
                ) {
                    onRequestLegalDocument(document.id)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Legal documents")
    }

    private var socialLinks: some View {
        HStack(spacing: 18) {
            ForEach(AppFooterSocialLinksView.links) { link in
                AppFooterTextLinkButton(
                    title: link.label,
                    palette: palette
                ) {
                    AppFooterSocialLinksView.open(link)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Social media links")
    }
}
