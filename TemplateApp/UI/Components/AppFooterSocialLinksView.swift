import SwiftUI
import AppKit

private enum SocialLinkLayoutMetrics {
    static let headerBannerWidth: CGFloat = 410
    static let headerBannerHeight: CGFloat = 133
}

struct FooterSocialLink: Identifiable {
    let id: String
    let label: String
    let url: URL
}

struct AppFooterSocialLinksView: View {
    let palette: AppThemePalette

    static let links: [FooterSocialLink] = [
        FooterSocialLink(
            id: "youtube",
            label: "YouTube",
            url: URL(string: "https://www.youtube.com/@my.musicalbrain")!
        ),
        FooterSocialLink(
            id: "facebook",
            label: "Facebook",
            url: URL(string: "https://www.facebook.com/profile.php?id=61590718633766&sk=directory_basic_info")!
        ),
        FooterSocialLink(
            id: "instagram",
            label: "Instagram",
            url: URL(string: "https://www.instagram.com/my.musicalbrain/")!
        )
    ]

    var body: some View {
        HStack(spacing: 18) {
            ForEach(Self.links) { link in
                AppFooterTextLinkButton(
                    title: link.label,
                    palette: palette
                ) {
                    Self.open(link)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Social media links")
    }

    static func open(_ link: FooterSocialLink) {
        NSWorkspace.shared.open(link.url)
    }
}

struct AppHeaderBannerView: View {
    let palette: AppThemePalette

    private var destinationURL: URL {
        URL(string: "https://tone-transcribe.vercel.app")!
    }

    @State private var isHovering = false
    @State private var isShowingPointingCursor = false

    var body: some View {
        Button {
            NSWorkspace.shared.open(destinationURL)
        } label: {
            Image("YouTubeBanner")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: SocialLinkLayoutMetrics.headerBannerWidth,
                    height: SocialLinkLayoutMetrics.headerBannerHeight,
                    alignment: .center
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(palette.textPrimary.opacity(isHovering ? 0.16 : 0.1), lineWidth: 1)
                )
                .shadow(
                    color: palette.accentSecondary.opacity(isHovering ? 0.14 : 0.08),
                    radius: isHovering ? 16 : 10,
                    x: 0,
                    y: isHovering ? 6 : 4
                )
                .opacity(isHovering ? 1 : 0.96)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityLabel("My Musical Brain YouTube banner")
        .onHover { hovering in
            withAnimation(AppMotion.ease) {
                isHovering = hovering
            }
            updatePointingCursor(isHovering: hovering)
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

struct AppFooterTextLinkButton: View {
    let title: String
    let palette: AppThemePalette
    let action: () -> Void

    @State private var isHovering = false
    @State private var isShowingPointingCursor = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.ui(size: 13))
                .tracking(0.52)
                .lineSpacing(2)
                .foregroundStyle(palette.textPrimary.opacity(isHovering ? 0.86 : 0.62))
                .shadow(color: Color.white.opacity(isHovering ? 0.18 : 0.08), radius: isHovering ? 6 : 0)
                .shadow(color: palette.accentTertiary.opacity(isHovering ? 0.18 : 0.08), radius: isHovering ? 18 : 10)
                .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(AppMotion.ease) {
                isHovering = hovering
            }
            updatePointingCursor(isHovering: hovering)
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
