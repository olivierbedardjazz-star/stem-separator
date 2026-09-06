import AppKit
import SwiftUI

enum AppMotion {
    static let shellBloomDuration: Double = 0.75
    static let controlPulseDuration: Double = 0.75
    static let popupExitDuration: Double = 0.18
    static let statusSpinnerDuration: Double = 0.9
    static let fast = 0.18
    static let base = 0.22
    static let ease = Animation.timingCurve(0.18, 0.82, 0.22, 1, duration: base)
    static let bloom = Animation.timingCurve(0.18, 0.82, 0.22, 1, duration: controlPulseDuration)
    static let exit = Animation.timingCurve(0.18, 0.82, 0.22, 1, duration: popupExitDuration)
}

enum AppTypography {
    private static let uiCandidates = ["Sora", "Avenir Next", "Segoe UI"]
    private static let displayCandidates = ["Space Grotesk", "Sora", "Avenir Next", "Segoe UI"]

    static func ui(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        resolvedFont(candidates: uiCandidates, size: size, weight: weight)
    }

    static func display(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        resolvedFont(candidates: displayCandidates, size: size, weight: weight)
    }

    private static func resolvedFont(candidates: [String], size: CGFloat, weight: Font.Weight) -> Font {
        for candidate in candidates where NSFont(name: candidate, size: size) != nil {
            return .custom(candidate, size: size).weight(weight)
        }

        return .system(size: size, weight: weight, design: .default)
    }
}

enum AppWindowMetrics {
    static let panelSpacing: CGFloat = 16
    static let sideBySidePanelWidth: CGFloat = 540
    static let maximumShellWidth: CGFloat = (sideBySidePanelWidth * 2) + panelSpacing

    static let minimumWindowWidth: CGFloat = 1156
    static let minimumWindowHeight: CGFloat = 760
    static let defaultWindowWidth: CGFloat = 1156
    static let defaultWindowHeight: CGFloat = 790

    static let regularHorizontalPadding: CGFloat = 30
    static let regularTopPadding: CGFloat = 28
    static let regularBottomPadding: CGFloat = 30

    static let sideBySideContentWidth: CGFloat = (sideBySidePanelWidth * 2) + panelSpacing

    static func shellPadding() -> EdgeInsets {
        return EdgeInsets(
            top: regularTopPadding,
            leading: regularHorizontalPadding,
            bottom: regularBottomPadding,
            trailing: regularHorizontalPadding
        )
    }
}

enum AppThemeKey: String, CaseIterable, Identifiable {
    case jazzAtelier = "jazz-atelier"
    case cosmicComposer = "cosmic-composer"
    case tapeLab = "tape-lab"
    case pinkNocturne = "pink-nocturne"
    case midnightPractice = "midnight-practice"
    case rockIt = "rock-it"
    case soulWithoutBorder = "soul-without-border"
    case obsidianPulse = "obsidian-pulse"

    var id: String { rawValue }
}

struct AppThemeOption: Identifiable, Equatable {
    let key: AppThemeKey
    let label: String

    var id: String { key.rawValue }
}

struct AppThemePalette {
    let background: Color
    let panel: Color
    let panelStrong: Color
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let accentPrimary: Color
    let accentSecondary: Color
    let accentTertiary: Color
    let shellGradientStart: Color
    let shellGradientEnd: Color
    let shellGlowLeft: Color
    let shellGlowRight: Color
    let brandPanelStart: Color
    let brandPanelEnd: Color
    let brandLogoSurface: Color
    let brandLogoBorder: Color
    let brandLogoShadow: Color

    var panelSurface: Color { panel.opacity(0.82) }
    var surfaceElevated: Color { Color.white.opacity(0.04) }
    var surfaceElevatedStrong: Color { Color.white.opacity(0.07) }
    var borderSubtle: Color { textPrimary.opacity(0.1) }
    var borderSoft: Color { textPrimary.opacity(0.08) }
    var ringColor: Color { accentPrimary.opacity(0.48) }
    var shadowPanelColor: Color { Color.black.opacity(0.22) }
}

enum AppThemeCatalog {
    static let options: [AppThemeOption] = [
        AppThemeOption(key: .jazzAtelier, label: "Jazz Virtuoso"),
        AppThemeOption(key: .cosmicComposer, label: "Cosmic Composer"),
        AppThemeOption(key: .tapeLab, label: "Tape Vintage"),
        AppThemeOption(key: .pinkNocturne, label: "Stroboscopic Romance"),
        AppThemeOption(key: .midnightPractice, label: "Midnight Practice"),
        AppThemeOption(key: .rockIt, label: "Rock It"),
        AppThemeOption(key: .soulWithoutBorder, label: "Soul Without Border"),
        AppThemeOption(key: .obsidianPulse, label: "Dark Mode")
    ]

    static func option(for key: AppThemeKey) -> AppThemeOption {
        options.first(where: { $0.key == key }) ?? options[0]
    }

    static func theme(for rawValue: String) -> AppThemeKey {
        AppThemeKey(rawValue: rawValue) ?? .jazzAtelier
    }
}

extension AppThemeKey {
    var palette: AppThemePalette {
        switch self {
        case .jazzAtelier:
            return AppThemePalette(
                background: Color(hex: "#151515") ?? .black,
                panel: Color(hex: "#202124") ?? .black,
                panelStrong: Color(hex: "#26272b") ?? .black,
                textPrimary: Color(hex: "#f3ede3") ?? .white,
                textSecondary: Color(hex: "#d5ccbf") ?? .white,
                textMuted: Color(hex: "#b8b1a6") ?? .gray,
                accentPrimary: Color(hex: "#f59e0b") ?? .orange,
                accentSecondary: Color(hex: "#60a5fa") ?? .blue,
                accentTertiary: Color(hex: "#f97316") ?? .orange,
                shellGradientStart: Color(hex: "#121212") ?? .black,
                shellGradientEnd: Color(hex: "#191815") ?? .black,
                shellGlowLeft: Color(hex: "#f59e0b")?.opacity(0.2) ?? .orange.opacity(0.2),
                shellGlowRight: Color(hex: "#60a5fa")?.opacity(0.16) ?? .blue.opacity(0.16),
                brandPanelStart: Color(hex: "#202124")?.opacity(0.92) ?? .black.opacity(0.92),
                brandPanelEnd: Color(hex: "#121212")?.opacity(0.88) ?? .black.opacity(0.88),
                brandLogoSurface: Color.white.opacity(0.05),
                brandLogoBorder: Color(hex: "#f59e0b")?.opacity(0.22) ?? .orange.opacity(0.22),
                brandLogoShadow: Color(hex: "#60a5fa")?.opacity(0.18) ?? .blue.opacity(0.18)
            )
        case .cosmicComposer:
            return AppThemePalette(
                background: Color(hex: "#151515") ?? .black,
                panel: Color(hex: "#202124") ?? .black,
                panelStrong: Color(hex: "#26272b") ?? .black,
                textPrimary: Color(hex: "#f3ede3") ?? .white,
                textSecondary: Color(hex: "#d5ccbf") ?? .white,
                textMuted: Color(hex: "#b8b1a6") ?? .gray,
                accentPrimary: Color(hex: "#8b5cf6") ?? .purple,
                accentSecondary: Color(hex: "#22d3ee") ?? .cyan,
                accentTertiary: Color(hex: "#38bdf8") ?? .blue,
                shellGradientStart: Color(hex: "#101321") ?? .black,
                shellGradientEnd: Color(hex: "#141722") ?? .black,
                shellGlowLeft: Color(hex: "#38bdf8")?.opacity(0.18) ?? .blue.opacity(0.18),
                shellGlowRight: Color(hex: "#8b5cf6")?.opacity(0.18) ?? .purple.opacity(0.18),
                brandPanelStart: Color(hex: "#202124")?.opacity(0.92) ?? .black.opacity(0.92),
                brandPanelEnd: Color(hex: "#121212")?.opacity(0.88) ?? .black.opacity(0.88),
                brandLogoSurface: Color.white.opacity(0.05),
                brandLogoBorder: Color(hex: "#8b5cf6")?.opacity(0.24) ?? .purple.opacity(0.24),
                brandLogoShadow: Color(hex: "#22d3ee")?.opacity(0.2) ?? .cyan.opacity(0.2)
            )
        case .tapeLab:
            return AppThemePalette(
                background: Color(hex: "#151515") ?? .black,
                panel: Color(hex: "#202124") ?? .black,
                panelStrong: Color(hex: "#26272b") ?? .black,
                textPrimary: Color(hex: "#f3ede3") ?? .white,
                textSecondary: Color(hex: "#d5ccbf") ?? .white,
                textMuted: Color(hex: "#b8b1a6") ?? .gray,
                accentPrimary: Color(hex: "#eab308") ?? .yellow,
                accentSecondary: Color(hex: "#d97706") ?? .orange,
                accentTertiary: Color(hex: "#facc15") ?? .yellow,
                shellGradientStart: Color(hex: "#18140e") ?? .black,
                shellGradientEnd: Color(hex: "#1e1810") ?? .black,
                shellGlowLeft: Color(hex: "#eab308")?.opacity(0.18) ?? .yellow.opacity(0.18),
                shellGlowRight: Color(hex: "#d97706")?.opacity(0.14) ?? .orange.opacity(0.14),
                brandPanelStart: Color(hex: "#202124")?.opacity(0.92) ?? .black.opacity(0.92),
                brandPanelEnd: Color(hex: "#121212")?.opacity(0.88) ?? .black.opacity(0.88),
                brandLogoSurface: Color.white.opacity(0.05),
                brandLogoBorder: Color(hex: "#eab308")?.opacity(0.24) ?? .yellow.opacity(0.24),
                brandLogoShadow: Color(hex: "#d97706")?.opacity(0.18) ?? .orange.opacity(0.18)
            )
        case .pinkNocturne:
            return AppThemePalette(
                background: Color(hex: "#151515") ?? .black,
                panel: Color(hex: "#202124") ?? .black,
                panelStrong: Color(hex: "#26272b") ?? .black,
                textPrimary: Color(hex: "#f3ede3") ?? .white,
                textSecondary: Color(hex: "#d5ccbf") ?? .white,
                textMuted: Color(hex: "#b8b1a6") ?? .gray,
                accentPrimary: Color(hex: "#ff4fb3") ?? .pink,
                accentSecondary: Color(hex: "#ff87d8") ?? .pink,
                accentTertiary: Color(hex: "#ff6ad5") ?? .pink,
                shellGradientStart: Color(hex: "#1f0f1a") ?? .black,
                shellGradientEnd: Color(hex: "#210f1b") ?? .black,
                shellGlowLeft: Color(hex: "#ff4fb3")?.opacity(0.24) ?? .pink.opacity(0.24),
                shellGlowRight: Color(hex: "#ff87d8")?.opacity(0.22) ?? .pink.opacity(0.22),
                brandPanelStart: Color(hex: "#202124")?.opacity(0.92) ?? .black.opacity(0.92),
                brandPanelEnd: Color(hex: "#121212")?.opacity(0.88) ?? .black.opacity(0.88),
                brandLogoSurface: Color.white.opacity(0.05),
                brandLogoBorder: Color(hex: "#ff4fb3")?.opacity(0.3) ?? .pink.opacity(0.3),
                brandLogoShadow: Color(hex: "#ff87d8")?.opacity(0.24) ?? .pink.opacity(0.24)
            )
        case .midnightPractice:
            return AppThemePalette(
                background: Color(hex: "#151515") ?? .black,
                panel: Color(hex: "#202124") ?? .black,
                panelStrong: Color(hex: "#26272b") ?? .black,
                textPrimary: Color(hex: "#f3ede3") ?? .white,
                textSecondary: Color(hex: "#d5ccbf") ?? .white,
                textMuted: Color(hex: "#b8b1a6") ?? .gray,
                accentPrimary: Color(hex: "#60a5fa") ?? .blue,
                accentSecondary: Color(hex: "#22c55e") ?? .green,
                accentTertiary: Color(hex: "#0ea5e9") ?? .cyan,
                shellGradientStart: Color(hex: "#0e141a") ?? .black,
                shellGradientEnd: Color(hex: "#10171c") ?? .black,
                shellGlowLeft: Color(hex: "#0ea5e9")?.opacity(0.14) ?? .cyan.opacity(0.14),
                shellGlowRight: Color(hex: "#22c55e")?.opacity(0.13) ?? .green.opacity(0.13),
                brandPanelStart: Color(hex: "#202124")?.opacity(0.92) ?? .black.opacity(0.92),
                brandPanelEnd: Color(hex: "#121212")?.opacity(0.88) ?? .black.opacity(0.88),
                brandLogoSurface: Color.white.opacity(0.05),
                brandLogoBorder: Color(hex: "#60a5fa")?.opacity(0.24) ?? .blue.opacity(0.24),
                brandLogoShadow: Color(hex: "#22c55e")?.opacity(0.17) ?? .green.opacity(0.17)
            )
        case .rockIt:
            return AppThemePalette(
                background: Color(hex: "#0b0b0c") ?? .black,
                panel: Color(hex: "#141416") ?? .black,
                panelStrong: Color(hex: "#1a1b1f") ?? .black,
                textPrimary: Color(hex: "#f5efe8") ?? .white,
                textSecondary: Color(hex: "#d9cdc0") ?? .white,
                textMuted: Color(hex: "#ab9f95") ?? .gray,
                accentPrimary: Color(hex: "#ef4444") ?? .red,
                accentSecondary: Color(hex: "#f97316") ?? .orange,
                accentTertiary: Color(hex: "#facc15") ?? .yellow,
                shellGradientStart: Color(hex: "#050506") ?? .black,
                shellGradientEnd: Color(hex: "#101012") ?? .black,
                shellGlowLeft: Color(hex: "#ef4444")?.opacity(0.18) ?? .red.opacity(0.18),
                shellGlowRight: Color(hex: "#f97316")?.opacity(0.12) ?? .orange.opacity(0.12),
                brandPanelStart: Color(hex: "#141416")?.opacity(0.94) ?? .black.opacity(0.94),
                brandPanelEnd: Color(hex: "#050506")?.opacity(0.9) ?? .black.opacity(0.9),
                brandLogoSurface: Color.white.opacity(0.035),
                brandLogoBorder: Color(hex: "#ef4444")?.opacity(0.22) ?? .red.opacity(0.22),
                brandLogoShadow: Color(hex: "#f97316")?.opacity(0.16) ?? .orange.opacity(0.16)
            )
        case .soulWithoutBorder:
            return AppThemePalette(
                background: Color(hex: "#121116") ?? .black,
                panel: Color(hex: "#1c1a22") ?? .black,
                panelStrong: Color(hex: "#25212d") ?? .black,
                textPrimary: Color(hex: "#f5eee8") ?? .white,
                textSecondary: Color(hex: "#d9d0c9") ?? .white,
                textMuted: Color(hex: "#b6aba6") ?? .gray,
                accentPrimary: Color(hex: "#f472b6") ?? .pink,
                accentSecondary: Color(hex: "#2dd4bf") ?? .teal,
                accentTertiary: Color(hex: "#f59e0b") ?? .orange,
                shellGradientStart: Color(hex: "#141018") ?? .black,
                shellGradientEnd: Color(hex: "#18171d") ?? .black,
                shellGlowLeft: Color(hex: "#f472b6")?.opacity(0.18) ?? .pink.opacity(0.18),
                shellGlowRight: Color(hex: "#2dd4bf")?.opacity(0.16) ?? .teal.opacity(0.16),
                brandPanelStart: Color(hex: "#221a26")?.opacity(0.94) ?? .black.opacity(0.94),
                brandPanelEnd: Color(hex: "#131218")?.opacity(0.9) ?? .black.opacity(0.9),
                brandLogoSurface: Color.white.opacity(0.045),
                brandLogoBorder: Color(hex: "#f472b6")?.opacity(0.22) ?? .pink.opacity(0.22),
                brandLogoShadow: Color(hex: "#2dd4bf")?.opacity(0.18) ?? .teal.opacity(0.18)
            )
        case .obsidianPulse:
            return AppThemePalette(
                background: Color(hex: "#05070a") ?? .black,
                panel: Color(hex: "#0c1016") ?? .black,
                panelStrong: Color(hex: "#121823") ?? .black,
                textPrimary: Color(hex: "#f3efe8") ?? .white,
                textSecondary: Color(hex: "#d4cdc2") ?? .white,
                textMuted: Color(hex: "#9e978d") ?? .gray,
                accentPrimary: Color(hex: "#8b5cf6") ?? .purple,
                accentSecondary: Color(hex: "#22d3ee") ?? .cyan,
                accentTertiary: Color(hex: "#fb923c") ?? .orange,
                shellGradientStart: Color(hex: "#040608") ?? .black,
                shellGradientEnd: Color(hex: "#090d12") ?? .black,
                shellGlowLeft: Color(hex: "#8b5cf6")?.opacity(0.1) ?? .purple.opacity(0.1),
                shellGlowRight: Color(hex: "#22d3ee")?.opacity(0.08) ?? .cyan.opacity(0.08),
                brandPanelStart: Color(hex: "#0c1016")?.opacity(0.96) ?? .black.opacity(0.96),
                brandPanelEnd: Color(hex: "#05070a")?.opacity(0.94) ?? .black.opacity(0.94),
                brandLogoSurface: Color.white.opacity(0.03),
                brandLogoBorder: Color(hex: "#8b5cf6")?.opacity(0.2) ?? .purple.opacity(0.2),
                brandLogoShadow: Color(hex: "#22d3ee")?.opacity(0.14) ?? .cyan.opacity(0.14)
            )
        }
    }
}

extension Color {
    init?(hex: String) {
        let sanitized = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard sanitized.count == 6 else { return nil }

        var rgb: UInt64 = 0
        guard Scanner(string: sanitized).scanHexInt64(&rgb) else { return nil }

        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255.0,
            green: Double((rgb >> 8) & 0xFF) / 255.0,
            blue: Double(rgb & 0xFF) / 255.0
        )
    }
}
