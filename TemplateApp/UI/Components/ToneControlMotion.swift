import SwiftUI

struct ToneControlMotionButtonStyle: ButtonStyle {
    let resetToken: UUID?
    let followsLivePressState: Bool
    let hoverOverride: Bool?

    init(
        resetToken: UUID? = nil,
        followsLivePressState: Bool = true,
        hoverOverride: Bool? = nil
    ) {
        self.resetToken = resetToken
        self.followsLivePressState = followsLivePressState
        self.hoverOverride = hoverOverride
    }

    func makeBody(configuration: Configuration) -> some View {
        ToneControlMotionPrimitive(
            isPressed: configuration.isPressed,
            resetToken: resetToken,
            followsLivePressState: followsLivePressState,
            hoverOverride: hoverOverride
        ) { _, _ in
            configuration.label
        }
    }
}

struct ToneControlMotionPrimitive<Content: View>: View {
    let isPressed: Bool
    let resetToken: UUID?
    let followsLivePressState: Bool
    let hoverOverride: Bool?
    @ViewBuilder let content: (_ isHovering: Bool, _ isEnabled: Bool) -> Content

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    init(
        isPressed: Bool,
        resetToken: UUID? = nil,
        followsLivePressState: Bool = true,
        hoverOverride: Bool? = nil,
        @ViewBuilder content: @escaping (_ isHovering: Bool, _ isEnabled: Bool) -> Content
    ) {
        self.isPressed = isPressed
        self.resetToken = resetToken
        self.followsLivePressState = followsLivePressState
        self.hoverOverride = hoverOverride
        self.content = content
    }

    var body: some View {
        content(resolvedHoverState, isEnabled)
            .offset(y: yOffset)
            .scaleEffect(scale)
            .animation(AppMotion.ease, value: isHovering)
            .animation(AppMotion.ease, value: isPressed)
            .onHover { hovering in
                guard hoverOverride == nil else { return }

                guard isEnabled else {
                    isHovering = false
                    return
                }

                withAnimation(AppMotion.ease) {
                    isHovering = hovering
                }
            }
            .onChange(of: isEnabled) { _, enabled in
                if !enabled {
                    isHovering = false
                }
            }
            .onChange(of: isPressed) { _, pressed in
                if pressed {
                    isHovering = false
                }
            }
            .onChange(of: resetToken) { _, _ in
                isHovering = false
            }
    }

    private var yOffset: CGFloat {
        guard isEnabled else { return 0 }

        if followsLivePressState && isPressed {
            return 1
        }

        return resolvedHoverState ? -1 : 0
    }

    private var scale: CGFloat {
        guard isEnabled else { return 1 }
        return followsLivePressState && isPressed ? 0.995 : 1
    }

    private var resolvedHoverState: Bool {
        hoverOverride ?? isHovering
    }
}
