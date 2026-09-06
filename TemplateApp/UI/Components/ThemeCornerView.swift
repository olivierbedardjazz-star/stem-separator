import SwiftUI
import AppKit

struct ThemeCornerView: View {
    let selectedTheme: AppThemeKey
    @Binding var isMenuOpen: Bool
    let options: [AppThemeOption]
    let palette: AppThemePalette
    let onThemeSelected: (AppThemeKey) -> Void
    @State private var isTriggerHovering = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            cornerShell

            ExitPresenceContainer(
                item: isMenuOpen ? ThemeMenuPresence.open : nil,
                exitDuration: AppMotion.popupExitDuration
            ) { _, isExiting in
                ThemeMenuView(
                    options: options,
                    selectedTheme: selectedTheme,
                    isExiting: isExiting,
                    onThemeSelected: onThemeSelected
                )
                .offset(y: ThemeCornerMetrics.cornerHeight + ThemeCornerMetrics.menuGap)
                .zIndex(180)
            }
        }
        .frame(
            width: ThemeCornerMetrics.cornerWidth,
            height: ThemeCornerMetrics.cornerHeight,
            alignment: .topLeading
        )
        .zIndex(140)
    }

    private var cornerShell: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("THEME")
                .font(AppTypography.ui(size: 9.92, weight: .regular))
                .foregroundStyle(palette.textPrimary.opacity(0.9))
                .tracking(1.6)
                .padding(.horizontal, 2)

            Button {
                withAnimation(AppMotion.ease) {
                    isMenuOpen.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    ThemeNameView(
                        theme: selectedTheme,
                        label: AppThemeCatalog.option(for: selectedTheme).label,
                        mode: .selectedTrigger
                    )
                    .id(selectedTheme)
                    .lineLimit(1)

                    Spacer(minLength: 12)

                    Text("▾")
                        .font(AppTypography.ui(size: 12, weight: .regular))
                        .foregroundStyle(palette.textPrimary.opacity(0.85))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(isTriggerHovering ? 0.34 : (isMenuOpen ? 0.34 : 0.25)))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(triggerBorderColor, lineWidth: 1)
                )
                .shadow(
                    color: triggerPrimaryGlowColor,
                    radius: triggerPrimaryGlowRadius,
                    x: 0,
                    y: 7
                )
                .shadow(
                    color: triggerTertiaryGlowColor,
                    radius: triggerTertiaryGlowRadius,
                    x: 0,
                    y: 0
                )
            }
            .buttonStyle(ThemeTriggerButtonStyle(palette: palette))
            .modifier(PointingHandCursorModifier())
            .padding(.top, 6)
            .onHover { hovering in
                withAnimation(AppMotion.ease) {
                    isTriggerHovering = hovering
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 22)
        .frame(
            width: ThemeCornerMetrics.cornerWidth,
            height: ThemeCornerMetrics.cornerHeight,
            alignment: .topLeading
        )
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.26))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.04), Color.white.opacity(0.015)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.04), lineWidth: 1)
                .blur(radius: 0.5)
        }
    }
}

private enum ThemeMenuPresence: Equatable {
    case open
}

private struct ThemeMenuView: View {
    let options: [AppThemeOption]
    let selectedTheme: AppThemeKey
    let isExiting: Bool
    let onThemeSelected: (AppThemeKey) -> Void
    @State private var hasEntered = false

    var body: some View {
        VStack(spacing: 2) {
            ForEach(options) { option in
                Button {
                    onThemeSelected(option.key)
                } label: {
                    HStack(spacing: 0) {
                        ThemeNameView(
                            theme: option.key,
                            label: option.label,
                            mode: option.key == selectedTheme ? .activeMenuOption : .menuOption
                        )

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
                .buttonStyle(ThemeOptionButtonStyle())
                .modifier(PointingHandCursorModifier())
            }
        }
        .padding(10)
        .frame(width: ThemeCornerMetrics.cornerWidth, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(hex: "#06080C")?.opacity(0.96) ?? Color.black.opacity(0.96))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.03), Color.white.opacity(0.01)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.04), lineWidth: 1)
                        .blur(radius: 0.5)
                }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.36), radius: 16, x: 0, y: 16)
        .compositingGroup()
        .fixedSize(horizontal: false, vertical: true)
        .opacity(menuOpacity)
        .scaleEffect(menuScale, anchor: .topTrailing)
        .offset(y: menuOffsetY)
        .onAppear {
            hasEntered = false
            DispatchQueue.main.async {
                withAnimation(AppMotion.exit) {
                    hasEntered = true
                }
            }
        }
    }

    private var menuOpacity: Double {
        if isExiting {
            return 0
        }

        return hasEntered ? 1 : 0
    }

    private var menuScale: CGFloat {
        if isExiting {
            return 0.985
        }

        return hasEntered ? 1 : 0.992
    }

    private var menuOffsetY: CGFloat {
        if isExiting {
            return -4
        }

        return hasEntered ? 0 : -2
    }
}

private struct PointingHandCursorModifier: ViewModifier {
    @State private var isShowingCursor = false

    func body(content: Content) -> some View {
        content.onHover { hovering in
            if hovering {
                guard !isShowingCursor else { return }
                NSCursor.pointingHand.push()
                isShowingCursor = true
                return
            }

            guard isShowingCursor else { return }
            NSCursor.pop()
            isShowingCursor = false
        }
    }
}

private struct ThemeTriggerButtonStyle: ButtonStyle {
    let palette: AppThemePalette

    func makeBody(configuration: Configuration) -> some View {
        ToneControlMotionPrimitive(isPressed: configuration.isPressed) { isHovering, isEnabled in
            configuration.label
                .opacity(isEnabled ? 1 : 0.75)
                .shadow(
                    color: isEnabled && isHovering ? palette.accentPrimary.opacity(0.14) : .clear,
                    radius: 10,
                    x: 0,
                    y: 7
                )
        }
    }
}

private struct ThemeOptionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        ToneControlMotionPrimitive(isPressed: configuration.isPressed) { _, isEnabled in
            configuration.label
                .contentShape(Rectangle())
                .opacity(isEnabled ? 1 : 0.72)
        }
    }
}

private struct ThemeNameView: View {
    enum Mode {
        case selectedTrigger
        case menuOption
        case activeMenuOption
    }

    let theme: AppThemeKey
    let label: String
    let mode: Mode

    @State private var isHovering = false
    @State private var hasFlashed = false

    var body: some View {
        Text(label)
            .font(AppTypography.display(size: 15.2, weight: .medium))
            .tracking(0.46)
            .foregroundStyle(style.foreground)
            .scaleEffect(scale)
            .brightness(brightness)
            .shadow(color: style.shadowA.color, radius: style.shadowA.radius, x: 0, y: 0)
            .shadow(color: style.shadowB.color, radius: style.shadowB.radius, x: 0, y: 0)
            .shadow(color: style.shadowC.color, radius: style.shadowC.radius, x: 0, y: 0)
            .animation(AppMotion.ease, value: isHovering)
            .animation(.timingCurve(0.2, 0.65, 0.22, 1, duration: 0.36), value: hasFlashed)
            .onHover { hovering in
                guard mode != .selectedTrigger else { return }
                withAnimation(AppMotion.ease) {
                    isHovering = hovering
                }
            }
            .onAppear {
                guard mode == .selectedTrigger else { return }
                hasFlashed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
                    hasFlashed = false
                }
            }
    }

    private var scale: CGFloat {
        switch mode {
        case .selectedTrigger:
            return hasFlashed ? 1.08 : 1
        case .menuOption, .activeMenuOption:
            return isHovering ? 1.055 : 1
        }
    }

    private var brightness: Double {
        switch mode {
        case .selectedTrigger:
            return hasFlashed ? 0.2 : 0
        case .menuOption, .activeMenuOption:
            return isHovering ? 0.08 : 0
        }
    }

    private var style: ThemeNameStyle {
        switch theme {
        case .jazzAtelier:
            return ThemeNameStyle(
                foreground: Color(hex: "#ffb14a") ?? .orange,
                shadowA: .init(color: Color.orange.opacity(isHovering ? 0.64 : 0.52), radius: isHovering ? 16 : 12),
                shadowB: .init(color: Color.blue.opacity(isHovering ? 0.34 : 0.24), radius: isHovering ? 28 : 22),
                shadowC: .clear
            )
        case .cosmicComposer:
            return ThemeNameStyle(
                foreground: Color(hex: "#cba6ff") ?? .purple,
                shadowA: .init(color: Color(red: 167/255, green: 139/255, blue: 250/255).opacity(isHovering ? 0.64 : 0.52), radius: isHovering ? 16 : 12),
                shadowB: .init(color: Color(red: 147/255, green: 51/255, blue: 234/255).opacity(isHovering ? 0.42 : 0.30), radius: isHovering ? 28 : 22),
                shadowC: .clear
            )
        case .tapeLab:
            return ThemeNameStyle(
                foreground: Color(hex: "#f6df9a") ?? .yellow,
                shadowA: .init(color: Color(red: 246/255, green: 223/255, blue: 154/255).opacity(isHovering ? 0.64 : 0.50), radius: isHovering ? 16 : 12),
                shadowB: .init(color: Color(red: 234/255, green: 179/255, blue: 8/255).opacity(isHovering ? 0.34 : 0.24), radius: isHovering ? 28 : 22),
                shadowC: .clear
            )
        case .pinkNocturne:
            return ThemeNameStyle(
                foreground: Color(hex: "#ff8fd7") ?? .pink,
                shadowA: .init(color: Color(red: 255/255, green: 79/255, blue: 179/255).opacity(isHovering ? 0.72 : 0.58), radius: isHovering ? 18 : 14),
                shadowB: .init(color: Color(red: 255/255, green: 135/255, blue: 216/255).opacity(isHovering ? 0.50 : 0.38), radius: isHovering ? 32 : 26),
                shadowC: .init(color: Color(red: 255/255, green: 106/255, blue: 213/255).opacity(isHovering ? 0.30 : 0), radius: isHovering ? 42 : 0)
            )
        case .midnightPractice:
            return ThemeNameStyle(
                foreground: Color(hex: "#8ec6ff") ?? .blue,
                shadowA: .init(color: Color(red: 59/255, green: 130/255, blue: 246/255).opacity(isHovering ? 0.54 : 0.42), radius: isHovering ? 16 : 12),
                shadowB: .init(color: Color(red: 20/255, green: 184/255, blue: 166/255).opacity(isHovering ? 0.34 : 0.24), radius: isHovering ? 28 : 22),
                shadowC: .clear
            )
        case .rockIt:
            return ThemeNameStyle(
                foreground: Color(hex: "#ff8b72") ?? .red,
                shadowA: .init(color: Color(red: 239/255, green: 68/255, blue: 68/255).opacity(isHovering ? 0.60 : 0.46), radius: isHovering ? 16 : 12),
                shadowB: .init(color: Color(red: 249/255, green: 115/255, blue: 22/255).opacity(isHovering ? 0.40 : 0.28), radius: isHovering ? 28 : 22),
                shadowC: .clear
            )
        case .soulWithoutBorder:
            return ThemeNameStyle(
                foreground: Color(hex: "#ffb4d7") ?? .pink,
                shadowA: .init(color: Color(red: 244/255, green: 114/255, blue: 182/255).opacity(isHovering ? 0.54 : 0.40), radius: isHovering ? 16 : 12),
                shadowB: .init(color: Color(red: 45/255, green: 212/255, blue: 191/255).opacity(isHovering ? 0.34 : 0.24), radius: isHovering ? 24 : 20),
                shadowC: .init(color: Color(red: 245/255, green: 158/255, blue: 11/255).opacity(isHovering ? 0.26 : 0.18), radius: isHovering ? 34 : 28)
            )
        case .obsidianPulse:
            return ThemeNameStyle(
                foreground: Color(hex: "#cab8ff") ?? .purple,
                shadowA: .init(color: Color(red: 139/255, green: 92/255, blue: 246/255).opacity(isHovering ? 0.62 : 0.48), radius: isHovering ? 16 : 12),
                shadowB: .init(color: Color(red: 34/255, green: 211/255, blue: 238/255).opacity(isHovering ? 0.28 : 0.18), radius: isHovering ? 28 : 22),
                shadowC: .clear
            )
        }
    }
}

private extension ThemeCornerView {
    var triggerBorderColor: Color {
        if isMenuOpen {
            return palette.textPrimary.opacity(0.34)
        }

        if isTriggerHovering {
            return palette.accentTertiary.opacity(0.42)
        }

        return palette.textPrimary.opacity(0.18)
    }

    var triggerPrimaryGlowColor: Color {
        if isTriggerHovering {
            return palette.accentPrimary.opacity(0.2)
        }

        return .clear
    }

    var triggerPrimaryGlowRadius: CGFloat {
        isTriggerHovering ? 22 : 0
    }

    var triggerTertiaryGlowColor: Color {
        if isTriggerHovering {
            return palette.accentTertiary.opacity(0.18)
        }

        return .clear
    }

    var triggerTertiaryGlowRadius: CGFloat {
        isTriggerHovering ? 18 : 0
    }
}

private struct ThemeNameShadow {
    let color: Color
    let radius: CGFloat

    static let clear = ThemeNameShadow(color: .clear, radius: 0)
}

private struct ThemeNameStyle {
    let foreground: Color
    let shadowA: ThemeNameShadow
    let shadowB: ThemeNameShadow
    let shadowC: ThemeNameShadow
}

private enum ThemeCornerMetrics {
    static let cornerWidth: CGFloat = 220
    static let cornerHeight: CGFloat = 106
    static let menuGap: CGFloat = 8
}

#Preview {
    ThemeCornerView(
        selectedTheme: .jazzAtelier,
        isMenuOpen: .constant(true),
        options: AppThemeCatalog.options,
        palette: AppThemeKey.jazzAtelier.palette,
        onThemeSelected: { _ in }
    )
    .padding()
    .background(Color.black)
}
