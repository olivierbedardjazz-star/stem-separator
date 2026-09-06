import AppKit
import SwiftUI

private enum TransientControlPulseSlot: CaseIterable {
    case a
    case b

    var alternate: TransientControlPulseSlot {
        switch self {
        case .a:
            return .b
        case .b:
            return .a
        }
    }
}

private struct PrimaryActionPulse: Equatable {
    let id: UUID
    let slot: TransientControlPulseSlot
}

private enum PrimaryActionPulseSegments {
    static let totalDuration = AppMotion.controlPulseDuration

    static let surfacePhaseOne = totalDuration * 0.24
    static let surfacePhaseTwo = totalDuration * 0.40
    static let surfacePhaseThree = totalDuration * 0.36

    static let haloPhaseOne = totalDuration * 0.26
    static let haloPhaseTwo = totalDuration * 0.40
    static let haloPhaseThree = totalDuration * 0.34

    static let ringPhaseOne = totalDuration * 0.28
    static let ringPhaseTwo = totalDuration * 0.40
    static let ringPhaseThree = totalDuration * 0.32
}

struct PrimaryActionRenderState: Equatable {
    let isHovering: Bool
    let pulseProgress: Double?

    init(
        isHovering: Bool = false,
        pulseProgress: Double? = nil
    ) {
        self.isHovering = isHovering
        self.pulseProgress = pulseProgress
    }
}

private struct PrimaryActionPulseSnapshot {
    let surfaceScale: CGFloat
    let surfaceSaturation: Double
    let surfaceBrightness: Double
    let ringOpacity: Double
    let ringScale: CGFloat
    let ringBorderOpacity: Double
    let ringGlowOpacity: Double
    let ringGlowRadius: CGFloat
    let haloOpacity: Double
    let haloScale: CGFloat
}

private enum PrimaryActionPulseSnapshotResolver {
    static func snapshot(progress: Double) -> PrimaryActionPulseSnapshot {
        let clampedProgress = min(max(progress, 0), 1)
        let easedSurface = phasedValue(
            progress: clampedProgress,
            phaseOneDuration: PrimaryActionPulseSegments.surfacePhaseOne,
            phaseTwoDuration: PrimaryActionPulseSegments.surfacePhaseTwo,
            phaseThreeDuration: PrimaryActionPulseSegments.surfacePhaseThree,
            values: [1, 1.02, 1.012, 1]
        )
        let easedSurfaceSaturation = phasedValue(
            progress: clampedProgress,
            phaseOneDuration: PrimaryActionPulseSegments.surfacePhaseOne,
            phaseTwoDuration: PrimaryActionPulseSegments.surfacePhaseTwo,
            phaseThreeDuration: PrimaryActionPulseSegments.surfacePhaseThree,
            values: [1, 1.04, 1.018, 1]
        )
        let easedSurfaceBrightness = phasedValue(
            progress: clampedProgress,
            phaseOneDuration: PrimaryActionPulseSegments.surfacePhaseOne,
            phaseTwoDuration: PrimaryActionPulseSegments.surfacePhaseTwo,
            phaseThreeDuration: PrimaryActionPulseSegments.surfacePhaseThree,
            values: [0, 0.065, 0.032, 0]
        )

        let ringOpacity = phasedValue(
            progress: clampedProgress,
            phaseOneDuration: PrimaryActionPulseSegments.ringPhaseOne,
            phaseTwoDuration: PrimaryActionPulseSegments.ringPhaseTwo,
            phaseThreeDuration: PrimaryActionPulseSegments.ringPhaseThree,
            values: [0, 0.6, 0.18, 0]
        )
        let ringScale = phasedValue(
            progress: clampedProgress,
            phaseOneDuration: PrimaryActionPulseSegments.ringPhaseOne,
            phaseTwoDuration: PrimaryActionPulseSegments.ringPhaseTwo,
            phaseThreeDuration: PrimaryActionPulseSegments.ringPhaseThree,
            values: [0.78, 1.04, 1.14, 1.2]
        )
        let ringBorderOpacity = phasedValue(
            progress: clampedProgress,
            phaseOneDuration: PrimaryActionPulseSegments.ringPhaseOne,
            phaseTwoDuration: PrimaryActionPulseSegments.ringPhaseTwo,
            phaseThreeDuration: PrimaryActionPulseSegments.ringPhaseThree,
            values: [0, 0.44, 0.16, 0]
        )
        let ringGlowOpacity = phasedValue(
            progress: clampedProgress,
            phaseOneDuration: PrimaryActionPulseSegments.ringPhaseOne,
            phaseTwoDuration: PrimaryActionPulseSegments.ringPhaseTwo,
            phaseThreeDuration: PrimaryActionPulseSegments.ringPhaseThree,
            values: [0, 0.16, 0.08, 0]
        )
        let ringGlowRadius = phasedValue(
            progress: clampedProgress,
            phaseOneDuration: PrimaryActionPulseSegments.ringPhaseOne,
            phaseTwoDuration: PrimaryActionPulseSegments.ringPhaseTwo,
            phaseThreeDuration: PrimaryActionPulseSegments.ringPhaseThree,
            values: [0, 22, 16, 0]
        )

        let haloOpacity = phasedValue(
            progress: clampedProgress,
            phaseOneDuration: PrimaryActionPulseSegments.haloPhaseOne,
            phaseTwoDuration: PrimaryActionPulseSegments.haloPhaseTwo,
            phaseThreeDuration: PrimaryActionPulseSegments.haloPhaseThree,
            values: [0, 0.72, 0.28, 0]
        )
        let haloScale = phasedValue(
            progress: clampedProgress,
            phaseOneDuration: PrimaryActionPulseSegments.haloPhaseOne,
            phaseTwoDuration: PrimaryActionPulseSegments.haloPhaseTwo,
            phaseThreeDuration: PrimaryActionPulseSegments.haloPhaseThree,
            values: [0.92, 1.15, 1.12, 1.22]
        )

        return PrimaryActionPulseSnapshot(
            surfaceScale: easedSurface,
            surfaceSaturation: easedSurfaceSaturation,
            surfaceBrightness: easedSurfaceBrightness,
            ringOpacity: ringOpacity,
            ringScale: ringScale,
            ringBorderOpacity: ringBorderOpacity,
            ringGlowOpacity: ringGlowOpacity,
            ringGlowRadius: ringGlowRadius,
            haloOpacity: haloOpacity,
            haloScale: haloScale
        )
    }

    private static func phasedValue(
        progress: Double,
        phaseOneDuration: Double,
        phaseTwoDuration: Double,
        phaseThreeDuration: Double,
        values: [Double]
    ) -> Double {
        let totalDuration = phaseOneDuration + phaseTwoDuration + phaseThreeDuration
        let elapsed = totalDuration * progress

        if elapsed <= phaseOneDuration {
            return interpolate(
                from: values[0],
                to: values[1],
                progress: cubicBezierProgress(elapsed / phaseOneDuration)
            )
        }

        if elapsed <= phaseOneDuration + phaseTwoDuration {
            return interpolate(
                from: values[1],
                to: values[2],
                progress: cubicBezierProgress((elapsed - phaseOneDuration) / phaseTwoDuration)
            )
        }

        return interpolate(
            from: values[2],
            to: values[3],
            progress: cubicBezierProgress((elapsed - phaseOneDuration - phaseTwoDuration) / phaseThreeDuration)
        )
    }

    private static func interpolate(from: Double, to: Double, progress: Double) -> Double {
        from + ((to - from) * progress)
    }

    private static func cubicBezierProgress(_ t: Double) -> Double {
        let clampedT = min(max(t, 0), 1)

        let x1 = 0.18
        let y1 = 0.82
        let x2 = 0.22
        let y2 = 1.0

        func sampleCurve(_ a1: Double, _ a2: Double, _ t: Double) -> Double {
            let invT = 1 - t
            return (3 * invT * invT * t * a1) + (3 * invT * t * t * a2) + (t * t * t)
        }

        func sampleDerivative(_ a1: Double, _ a2: Double, _ t: Double) -> Double {
            let invT = 1 - t
            return (3 * invT * invT * a1) + (6 * invT * t * (a2 - a1)) + (3 * t * t * (1 - a2))
        }

        var solvedT = clampedT
        for _ in 0..<8 {
            let x = sampleCurve(x1, x2, solvedT) - clampedT
            let derivative = sampleDerivative(x1, x2, solvedT)
            if abs(x) < 0.000_001 || abs(derivative) < 0.000_001 {
                break
            }
            solvedT -= x / derivative
            solvedT = min(max(solvedT, 0), 1)
        }

        return sampleCurve(y1, y2, solvedT)
    }
}

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String?
    let palette: AppThemePalette
    let isDefaultAction: Bool
    let defersActionUntilNextRunLoop: Bool
    let renderState: PrimaryActionRenderState?
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false
    @State private var isShowingDisabledCursor = false
    @State private var nextPulseSlot: TransientControlPulseSlot = .a
    @State private var activePulse: PrimaryActionPulse?
    @State private var interactionResetToken: UUID?
    @State private var clearPulseWorkItem: DispatchWorkItem?

    init(
        title: String,
        systemImage: String?,
        palette: AppThemePalette,
        isDefaultAction: Bool,
        defersActionUntilNextRunLoop: Bool,
        renderState: PrimaryActionRenderState? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.palette = palette
        self.isDefaultAction = isDefaultAction
        self.defersActionUntilNextRunLoop = defersActionUntilNextRunLoop
        self.renderState = renderState
        self.action = action
    }

    var body: some View {
        button
    }

    private var button: some View {
        Button {
            resetInteractionState()
            triggerPulseIfNeeded()

            if defersActionUntilNextRunLoop {
                DispatchQueue.main.async {
                    action()
                }
            } else {
                action()
            }
        } label: {
            PrimaryActionSurfacePulseView(trigger: activePulse?.id, progressOverride: renderState?.pulseProgress) {
                HStack(spacing: 10) {
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 13, weight: .bold))
                    }

                    Text(title)
                        .font(AppTypography.ui(size: 15, weight: .bold))
                        .tracking(0.4)
                }
                .foregroundStyle(Color(red: 1, green: 250 / 255, blue: 241 / 255).opacity(isEnabled ? 0.98 : 0.72))
                .shadow(color: .white.opacity(isEnabled ? 0.9 : 0.44), radius: 3, x: 0, y: 0)
                .shadow(color: palette.accentTertiary.opacity(isEnabled ? 0.32 : 0.14), radius: 20, x: 0, y: 0)
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(buttonFill)
                .overlay(borderOverlay)
                .overlay(pulseOverlay)
                .shadow(color: palette.accentPrimary.opacity(isEnabled ? 0.28 : 0.12), radius: 32, x: 0, y: 12)
                .shadow(color: palette.accentTertiary.opacity(isEnabled ? 0.28 : 0.12), radius: 12, x: 0, y: 0)
                .shadow(color: .white.opacity(isEnabled ? 0.08 : 0.04), radius: 0, x: 0, y: -1)
                .opacity(isEnabled ? 1 : 0.76)
            }
        }
        .buttonStyle(
            ToneControlMotionButtonStyle(
                resetToken: interactionResetToken,
                followsLivePressState: false,
                hoverOverride: renderState?.isHovering
            )
        )
        .modifier(PointingHandCursorModifier(isEnabled: isEnabled, resetToken: interactionResetToken))
        .onHover { hovering in
            guard isEnabled else {
                isHovering = false
                updateDisabledCursor(isHovering: hovering)
                return
            }

            updateDisabledCursor(isHovering: false)
            withAnimation(AppMotion.ease) {
                isHovering = hovering
            }
        }
        .onChange(of: isEnabled) { _, enabled in
            if !enabled {
                isHovering = false
                clearPulseWorkItem?.cancel()
                clearPulseWorkItem = nil
                activePulse = nil
            } else {
                updateDisabledCursor(isHovering: false)
            }
        }
        .onDisappear {
            clearPulseWorkItem?.cancel()
            clearPulseWorkItem = nil
        }
        .modifier(DefaultActionShortcutModifier(isEnabled: isDefaultAction))
    }

    private var buttonFill: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        palette.accentPrimary.opacity(isEnabled ? 1 : 0.75),
                        palette.accentTertiary.opacity(isEnabled ? 1 : 0.75)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(palette.accentPrimary.opacity(isEnabled ? 0.34 : 0.18), lineWidth: 1)
    }

    private var pulseOverlay: some View {
        ZStack {
            if let pulseProgress = renderState?.pulseProgress {
                PrimaryActionPulseOverlay(palette: palette, trigger: nil, progressOverride: pulseProgress)
                    .allowsHitTesting(false)
                    .transition(.identity)
            } else if let activePulse {
                PrimaryActionPulseOverlay(palette: palette, trigger: activePulse.id, progressOverride: nil)
                    .id(activePulse.slot)
                    .allowsHitTesting(false)
                    .transition(.identity)
            }
        }
    }

    private func triggerPulseIfNeeded() {
        guard isEnabled else { return }

        clearPulseWorkItem?.cancel()

        let slot = nextPulseSlot
        nextPulseSlot = slot.alternate

        let pulse = PrimaryActionPulse(id: UUID(), slot: slot)
        activePulse = pulse

        let workItem = DispatchWorkItem {
            guard activePulse?.id == pulse.id else { return }
            activePulse = nil
            clearPulseWorkItem = nil
        }

        clearPulseWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + AppMotion.controlPulseDuration, execute: workItem)
    }

    private func resetInteractionState() {
        withAnimation(AppMotion.ease) {
            isHovering = false
        }
        updateDisabledCursor(isHovering: false)
        interactionResetToken = UUID()
    }

    private func updateDisabledCursor(isHovering: Bool) {
        if isHovering {
            guard !isShowingDisabledCursor else { return }
            NSCursor.operationNotAllowed.push()
            isShowingDisabledCursor = true
            return
        }

        guard isShowingDisabledCursor else { return }
        NSCursor.pop()
        isShowingDisabledCursor = false
    }
}

private struct PrimaryActionSurfacePulseView<Content: View>: View {
    let trigger: UUID?
    let progressOverride: Double?
    @ViewBuilder let content: () -> Content

    @State private var scale: CGFloat = 1
    @State private var saturation: Double = 1
    @State private var brightness: Double = 0
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        content()
            .scaleEffect(scale)
            .saturation(saturation)
            .brightness(brightness)
            .onAppear(perform: startOrApplySnapshot)
            .onChange(of: trigger) { _, newValue in
                guard newValue != nil || progressOverride != nil else { return }
                startOrApplySnapshot()
            }
            .onChange(of: progressOverride) { _, _ in
                startOrApplySnapshot()
            }
            .onDisappear {
                animationTask?.cancel()
                animationTask = nil
            }
    }

    @MainActor
    private func startOrApplySnapshot() {
        if let progressOverride {
            animationTask?.cancel()
            animationTask = nil
            applySnapshot(PrimaryActionPulseSnapshotResolver.snapshot(progress: progressOverride))
            return
        }

        startAnimation()
    }

    @MainActor
    private func startAnimation() {
        animationTask?.cancel()
        scale = 1
        saturation = 1
        brightness = 0

        animationTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }

            withAnimation(.timingCurve(0.18, 0.82, 0.22, 1, duration: PrimaryActionPulseSegments.surfacePhaseOne)) {
                scale = 1.02
                saturation = 1.04
                brightness = 0.065
            }

            try? await Task.sleep(nanoseconds: UInt64(PrimaryActionPulseSegments.surfacePhaseOne * 1_000_000_000))
            guard !Task.isCancelled else { return }

            withAnimation(.timingCurve(0.18, 0.82, 0.22, 1, duration: PrimaryActionPulseSegments.surfacePhaseTwo)) {
                scale = 1.012
                saturation = 1.018
                brightness = 0.032
            }

            try? await Task.sleep(nanoseconds: UInt64(PrimaryActionPulseSegments.surfacePhaseTwo * 1_000_000_000))
            guard !Task.isCancelled else { return }

            withAnimation(.timingCurve(0.18, 0.82, 0.22, 1, duration: PrimaryActionPulseSegments.surfacePhaseThree)) {
                scale = 1
                saturation = 1
                brightness = 0
            }
        }
    }

    @MainActor
    private func applySnapshot(_ snapshot: PrimaryActionPulseSnapshot) {
        scale = snapshot.surfaceScale
        saturation = snapshot.surfaceSaturation
        brightness = snapshot.surfaceBrightness
    }
}

private struct PointingHandCursorModifier: ViewModifier {
    let isEnabled: Bool
    let resetToken: UUID?
    @State private var isShowingCursor = false

    func body(content: Content) -> some View {
        content
            .onHover { hovering in
                let shouldShowCursor = hovering && isEnabled

                if shouldShowCursor {
                    guard !isShowingCursor else { return }
                    NSCursor.pointingHand.push()
                    isShowingCursor = true
                    return
                }

                guard isShowingCursor else { return }
                NSCursor.pop()
                isShowingCursor = false
            }
            .onChange(of: isEnabled) { _, enabled in
                if enabled || !isShowingCursor {
                    return
                }

                NSCursor.pop()
                isShowingCursor = false
            }
            .onChange(of: resetToken) { _, _ in
                guard isShowingCursor else { return }
                NSCursor.pop()
                isShowingCursor = false
            }
    }
}

struct PrimaryDownloadButton: View {
    let palette: AppThemePalette
    let renderState: PrimaryActionRenderState?
    let action: () -> Void

    init(
        palette: AppThemePalette,
        renderState: PrimaryActionRenderState? = nil,
        action: @escaping () -> Void
    ) {
        self.palette = palette
        self.renderState = renderState
        self.action = action
    }

    var body: some View {
        PrimaryActionButton(
            title: "Download",
            systemImage: "arrow.down",
            palette: palette,
            isDefaultAction: false,
            defersActionUntilNextRunLoop: true,
            renderState: renderState,
            action: action
        )
    }
}

struct TemplatePrimaryActionButton: View {
    let title: String
    let systemImage: String?
    let palette: AppThemePalette
    let renderState: PrimaryActionRenderState?
    let action: () -> Void

    init(
        title: String = "Start",
        systemImage: String? = nil,
        palette: AppThemePalette,
        renderState: PrimaryActionRenderState? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.palette = palette
        self.renderState = renderState
        self.action = action
    }

    var body: some View {
        PrimaryActionButton(
            title: title,
            systemImage: systemImage,
            palette: palette,
            isDefaultAction: false,
            defersActionUntilNextRunLoop: true,
            renderState: renderState,
            action: action
        )
    }
}

private struct DefaultActionShortcutModifier: ViewModifier {
    let isEnabled: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEnabled {
            content.keyboardShortcut(.defaultAction)
        } else {
            content
        }
    }
}

private struct PrimaryActionPulseOverlay: View {
    let palette: AppThemePalette
    let trigger: UUID?
    let progressOverride: Double?

    var body: some View {
        ZStack {
            PrimaryActionRingPulseLayer(palette: palette, trigger: trigger, progressOverride: progressOverride)
            PrimaryActionHaloPulseLayer(palette: palette, trigger: trigger, progressOverride: progressOverride)
        }
    }
}

private struct PrimaryActionRingPulseLayer: View {
    let palette: AppThemePalette
    let trigger: UUID?
    let progressOverride: Double?

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.78
    @State private var borderOpacity: Double = 0
    @State private var tertiaryGlowOpacity: Double = 0
    @State private var tertiaryGlowRadius: CGFloat = 0
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(palette.accentPrimary.opacity(borderOpacity), lineWidth: 1)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                palette.accentTertiary.opacity(0.06)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .padding(-6)
            .scaleEffect(scale)
            .opacity(opacity)
            .shadow(color: palette.accentTertiary.opacity(tertiaryGlowOpacity), radius: tertiaryGlowRadius, x: 0, y: 0)
            .onAppear(perform: startOrApplySnapshot)
            .onChange(of: trigger) { _, _ in
                startOrApplySnapshot()
            }
            .onChange(of: progressOverride) { _, _ in
                startOrApplySnapshot()
            }
            .onDisappear {
                animationTask?.cancel()
                animationTask = nil
            }
    }

    @MainActor
    private func startOrApplySnapshot() {
        if let progressOverride {
            animationTask?.cancel()
            animationTask = nil
            applySnapshot(PrimaryActionPulseSnapshotResolver.snapshot(progress: progressOverride))
            return
        }

        startAnimation()
    }

    @MainActor
    private func startAnimation() {
        animationTask?.cancel()
        opacity = 0
        scale = 0.78
        borderOpacity = 0
        tertiaryGlowOpacity = 0
        tertiaryGlowRadius = 0

        animationTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }

            withAnimation(.timingCurve(0.18, 0.82, 0.22, 1, duration: PrimaryActionPulseSegments.ringPhaseOne)) {
                opacity = 0.6
                scale = 1.04
                borderOpacity = 0.44
                tertiaryGlowOpacity = 0.16
                tertiaryGlowRadius = 22
            }

            try? await Task.sleep(nanoseconds: UInt64(PrimaryActionPulseSegments.ringPhaseOne * 1_000_000_000))
            guard !Task.isCancelled else { return }

            withAnimation(.timingCurve(0.18, 0.82, 0.22, 1, duration: PrimaryActionPulseSegments.ringPhaseTwo)) {
                opacity = 0.18
                scale = 1.14
                borderOpacity = 0.16
                tertiaryGlowOpacity = 0.08
                tertiaryGlowRadius = 16
            }

            try? await Task.sleep(nanoseconds: UInt64(PrimaryActionPulseSegments.ringPhaseTwo * 1_000_000_000))
            guard !Task.isCancelled else { return }

            withAnimation(.timingCurve(0.18, 0.82, 0.22, 1, duration: PrimaryActionPulseSegments.ringPhaseThree)) {
                opacity = 0
                scale = 1.2
                borderOpacity = 0
                tertiaryGlowOpacity = 0
                tertiaryGlowRadius = 0
            }
        }
    }

    @MainActor
    private func applySnapshot(_ snapshot: PrimaryActionPulseSnapshot) {
        opacity = snapshot.ringOpacity
        scale = snapshot.ringScale
        borderOpacity = snapshot.ringBorderOpacity
        tertiaryGlowOpacity = snapshot.ringGlowOpacity
        tertiaryGlowRadius = snapshot.ringGlowRadius
    }
}

private struct PrimaryActionHaloPulseLayer: View {
    let palette: AppThemePalette
    let trigger: UUID?
    let progressOverride: Double?

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.92
    @State private var animationTask: Task<Void, Never>?

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(
                RadialGradient(
                    colors: [
                        palette.accentPrimary.opacity(0.42),
                        palette.accentTertiary.opacity(0.32),
                        palette.accentTertiary.opacity(0.08),
                        .clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 140
                )
            )
            .padding(-9)
            .blur(radius: 12)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear(perform: startOrApplySnapshot)
            .onChange(of: trigger) { _, _ in
                startOrApplySnapshot()
            }
            .onChange(of: progressOverride) { _, _ in
                startOrApplySnapshot()
            }
            .onDisappear {
                animationTask?.cancel()
                animationTask = nil
            }
    }

    @MainActor
    private func startOrApplySnapshot() {
        if let progressOverride {
            animationTask?.cancel()
            animationTask = nil
            applySnapshot(PrimaryActionPulseSnapshotResolver.snapshot(progress: progressOverride))
            return
        }

        startAnimation()
    }

    @MainActor
    private func startAnimation() {
        animationTask?.cancel()
        opacity = 0
        scale = 0.92

        animationTask = Task { @MainActor in
            await Task.yield()
            guard !Task.isCancelled else { return }

            withAnimation(.timingCurve(0.18, 0.82, 0.22, 1, duration: PrimaryActionPulseSegments.haloPhaseOne)) {
                opacity = 0.72
                scale = 1.15
            }

            try? await Task.sleep(nanoseconds: UInt64(PrimaryActionPulseSegments.haloPhaseOne * 1_000_000_000))
            guard !Task.isCancelled else { return }

            withAnimation(.timingCurve(0.18, 0.82, 0.22, 1, duration: PrimaryActionPulseSegments.haloPhaseTwo)) {
                opacity = 0.28
                scale = 1.12
            }

            try? await Task.sleep(nanoseconds: UInt64(PrimaryActionPulseSegments.haloPhaseTwo * 1_000_000_000))
            guard !Task.isCancelled else { return }

            withAnimation(.timingCurve(0.18, 0.82, 0.22, 1, duration: PrimaryActionPulseSegments.haloPhaseThree)) {
                opacity = 0
                scale = 1.22
            }
        }
    }

    @MainActor
    private func applySnapshot(_ snapshot: PrimaryActionPulseSnapshot) {
        opacity = snapshot.haloOpacity
        scale = snapshot.haloScale
    }
}

#Preview {
    VStack(spacing: 20) {
        PrimaryDownloadButton(palette: AppThemeKey.jazzAtelier.palette) {}
        TemplatePrimaryActionButton(palette: AppThemeKey.jazzAtelier.palette) {}
        PrimaryActionButton(
            title: "OK",
            systemImage: nil,
            palette: AppThemeKey.jazzAtelier.palette,
            isDefaultAction: false,
            defersActionUntilNextRunLoop: false
        ) {}
    }
    .padding()
    .background(Color.black)
}
