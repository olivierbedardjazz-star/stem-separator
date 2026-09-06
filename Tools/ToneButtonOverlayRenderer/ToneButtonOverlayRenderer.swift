import AppKit
import AVFoundation
import Foundation
import SwiftUI

private struct OverlaySceneEnvelope: Decodable {
    let scene: OverlayScene?
    let config: OverlayConfig?
}

private struct OverlayConfig: Decodable {
    let text: String?
    let systemImage: String?
    let theme: String?
    let cursorStartX: Double?
    let cursorStartY: Double?
    let cursorEndX: Double?
    let cursorEndY: Double?
    let moveStart: Double?
    let moveDuration: Double?
    let clickTime: Double?
    let clickDuration: Double?
    let hoverDuration: Double?
    let holdDuration: Double?
    let pulseSlot: String?
}

private struct OverlayScene: Decodable {
    let buttonText: String
    let systemImage: String?
    let theme: String?
    let cursor: OverlayCursorConfig
    let events: [OverlayEvent]
}

private struct OverlayCursorConfig: Decodable {
    let startX: Double
    let startY: Double
    let endX: Double
    let endY: Double
}

private struct OverlayEvent: Decodable {
    let start: Double
    let action: String
    let duration: Double?
    let pulseSlot: String?
}

private struct OverlayRuntimeConfiguration {
    let scenePath: String
    let outputPath: String
    let width: CGFloat
    let height: CGFloat
    let scale: CGFloat
    let fps: Int32
}

private struct OverlayFrameState {
    let buttonText: String
    let systemImage: String?
    let theme: AppThemeKey
    let cursorPosition: CGPoint
    let cursorVisible: Bool
    let buttonRenderState: PrimaryActionRenderState
}

private enum OverlayRendererError: Error, CustomStringConvertible {
    case missingArgument(String)
    case unsupportedSceneFormat(String)
    case assetWriter(String)
    case frameCaptureFailed

    var description: String {
        switch self {
        case .missingArgument(let flag):
            return "Missing required flag: \(flag)"
        case .unsupportedSceneFormat(let path):
            return "Unsupported scene file at \(path)"
        case .assetWriter(let message):
            return message
        case .frameCaptureFailed:
            return "Failed to capture frame from native SwiftUI renderer."
        }
    }
}

@main
enum ToneButtonOverlayRendererMain {
    static func main() throws {
        _ = NSApplication.shared
        let configuration = try parseConfiguration(arguments: Array(CommandLine.arguments.dropFirst()))
        let scene = try loadScene(from: configuration.scenePath)

        let renderer = NativeOverlayMovieRenderer(configuration: configuration, scene: scene)
        try renderer.render()
    }
}

private func parseConfiguration(arguments: [String]) throws -> OverlayRuntimeConfiguration {
    func value(for flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }

    guard let scenePath = value(for: "--scene") else {
        throw OverlayRendererError.missingArgument("--scene")
    }

    guard let outputPath = value(for: "--output") else {
        throw OverlayRendererError.missingArgument("--output")
    }

    let width = CGFloat(Double(value(for: "--width") ?? "563") ?? 563)
    let height = CGFloat(Double(value(for: "--height") ?? "1000") ?? 1000)
    let scale = CGFloat(Double(value(for: "--scale") ?? "2") ?? 2)
    let fps = Int32(value(for: "--fps") ?? "30") ?? 30

    return OverlayRuntimeConfiguration(
        scenePath: scenePath,
        outputPath: outputPath,
        width: width,
        height: height,
        scale: scale,
        fps: fps
    )
}

private func loadScene(from path: String) throws -> OverlayScene {
    let url = URL(fileURLWithPath: path)
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()

    if let scene = try? decoder.decode(OverlaySceneEnvelope.self, from: data).scene {
        return scene
    }

    if let config = try? decoder.decode(OverlayConfig.self, from: data) {
        return OverlayScene(
            buttonText: config.text ?? "Import audio",
            systemImage: config.systemImage,
            theme: config.theme,
            cursor: OverlayCursorConfig(
                startX: config.cursorStartX ?? 0.22,
                startY: config.cursorStartY ?? 0.78,
                endX: config.cursorEndX ?? 0.5,
                endY: config.cursorEndY ?? 0.5
            ),
            events: [
                OverlayEvent(start: config.moveStart ?? 0.15, action: "moveCursor", duration: config.moveDuration ?? 0.95, pulseSlot: nil),
                OverlayEvent(start: (config.clickTime ?? 1.26) - (config.hoverDuration ?? 0.18), action: "hoverButton", duration: config.hoverDuration ?? 0.18, pulseSlot: nil),
                OverlayEvent(start: config.clickTime ?? 1.26, action: "clickButton", duration: config.clickDuration ?? 0.14, pulseSlot: config.pulseSlot ?? "a"),
                OverlayEvent(start: (config.clickTime ?? 1.26) + (config.clickDuration ?? 0.14), action: "holdAfterClick", duration: config.holdDuration ?? 1.15, pulseSlot: nil)
            ]
        )
    }

    throw OverlayRendererError.unsupportedSceneFormat(path)
}

private final class NativeOverlayMovieRenderer {
    private let configuration: OverlayRuntimeConfiguration
    private let scene: OverlayScene
    private let totalDuration: Double

    init(configuration: OverlayRuntimeConfiguration, scene: OverlayScene) {
        self.configuration = configuration
        self.scene = scene
        self.totalDuration = scene.events.reduce(0) { current, event in
            max(current, event.start + (event.duration ?? 0))
        } + 0.7
    }

    func render() throws {
        let outputURL = URL(fileURLWithPath: configuration.outputPath)
        try? FileManager.default.removeItem(at: outputURL)
        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
        let outputSize = CGSize(width: configuration.width * configuration.scale, height: configuration.height * configuration.scale)

        let outputSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.proRes4444,
            AVVideoWidthKey: Int(outputSize.width),
            AVVideoHeightKey: Int(outputSize.height)
        ]

        let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: outputSettings)
        writerInput.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
                kCVPixelBufferWidthKey as String: Int(outputSize.width),
                kCVPixelBufferHeightKey as String: Int(outputSize.height),
                kCVPixelBufferCGImageCompatibilityKey as String: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
            ]
        )

        guard writer.canAdd(writerInput) else {
            throw OverlayRendererError.assetWriter("Cannot add video input to AVAssetWriter.")
        }

        writer.add(writerInput)

        guard writer.startWriting() else {
            throw OverlayRendererError.assetWriter(writer.error?.localizedDescription ?? "Failed to start writing movie.")
        }

        writer.startSession(atSourceTime: .zero)

        let frameCount = Int(ceil(totalDuration * Double(configuration.fps)))
        let frameDuration = 1.0 / Double(configuration.fps)
        let renderWidth = configuration.width
        let renderHeight = configuration.height
        let renderScale = configuration.scale

        for frameIndex in 0..<frameCount {
            let presentationTime = CMTime(value: CMTimeValue(frameIndex), timescale: configuration.fps)
            let currentTime = min(Double(frameIndex) * frameDuration, totalDuration)
            let state = frameState(at: currentTime)
            let image = try MainActor.assumeIsolated {
                try makeFrameImage(
                    width: renderWidth,
                    height: renderHeight,
                    scale: renderScale,
                    state: state
                )
            }

            while !writerInput.isReadyForMoreMediaData {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.002))
            }

            guard let pixelBuffer = makePixelBuffer(from: image, size: outputSize, pool: adaptor.pixelBufferPool) else {
                throw OverlayRendererError.assetWriter("Failed to create movie pixel buffer.")
            }

            if !adaptor.append(pixelBuffer, withPresentationTime: presentationTime) {
                throw OverlayRendererError.assetWriter(writer.error?.localizedDescription ?? "Failed to append frame to movie.")
            }
        }

        writerInput.markAsFinished()

        let completionSemaphore = DispatchSemaphore(value: 0)
        writer.finishWriting {
            completionSemaphore.signal()
        }
        completionSemaphore.wait()

        if let error = writer.error {
            throw OverlayRendererError.assetWriter(error.localizedDescription)
        }
    }

    private func frameState(at time: Double) -> OverlayFrameState {
        let paletteTheme = AppThemeCatalog.theme(for: scene.theme ?? AppThemeKey.jazzAtelier.rawValue)
        let startX = configuration.width * scene.cursor.startX
        let startY = configuration.height * scene.cursor.startY
        let endX = configuration.width * scene.cursor.endX
        let endY = configuration.height * scene.cursor.endY

        var cursorX = startX
        var cursorY = startY
        var cursorVisible = true
        var isHovering = false
        var pulseProgress: Double?

        for event in scene.events {
            let eventEnd = event.start + (event.duration ?? 0)

            switch event.action {
            case "moveCursor":
                guard time > event.start else { continue }
                let progress = min(max((time - event.start) / (event.duration ?? 0.0001), 0), 1)
                let eased = easeOutCubic(progress)
                cursorX = interpolate(from: startX, to: endX, progress: eased)
                cursorY = interpolate(from: startY, to: endY, progress: eased)
            case "hoverButton":
                if time >= event.start && time <= eventEnd {
                    isHovering = true
                }
            case "clickButton":
                if time >= event.start && time <= event.start + AppMotion.controlPulseDuration {
                    pulseProgress = (time - event.start) / AppMotion.controlPulseDuration
                }
                if time > eventEnd {
                    cursorVisible = false
                }
            case "holdAfterClick":
                if time >= event.start {
                    cursorVisible = false
                }
            default:
                continue
            }
        }

        return OverlayFrameState(
            buttonText: scene.buttonText,
            systemImage: scene.systemImage,
            theme: paletteTheme,
            cursorPosition: CGPoint(x: cursorX, y: cursorY),
            cursorVisible: cursorVisible,
            buttonRenderState: PrimaryActionRenderState(isHovering: isHovering, pulseProgress: pulseProgress)
        )
    }

}

@MainActor
private func makeFrameImage(
    width: CGFloat,
    height: CGFloat,
    scale: CGFloat,
    state: OverlayFrameState
) throws -> CGImage {
        let hostingView = NSHostingView(
            rootView: OverlayRenderStageView(
                width: width,
                height: height,
                state: state
            )
        )

        hostingView.frame = NSRect(x: 0, y: 0, width: width, height: height)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layoutSubtreeIfNeeded()
        hostingView.displayIfNeeded()

        let bitmapWidth = Int(width * scale)
        let bitmapHeight = Int(height * scale)
        let bounds = hostingView.bounds

        let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: bitmapWidth,
            pixelsHigh: bitmapHeight,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )

        guard let bitmap else {
            throw OverlayRendererError.frameCaptureFailed
        }

        bitmap.size = NSSize(width: width, height: height)
        NSGraphicsContext.saveGraphicsState()
        if let context = NSGraphicsContext(bitmapImageRep: bitmap) {
            NSGraphicsContext.current = context
            context.cgContext.scaleBy(x: scale, y: scale)
            hostingView.cacheDisplay(in: bounds, to: bitmap)
        }
        NSGraphicsContext.restoreGraphicsState()

        guard let image = bitmap.cgImage else {
            throw OverlayRendererError.frameCaptureFailed
        }

        return image
}

private func makePixelBuffer(from image: CGImage, size: CGSize, pool: CVPixelBufferPool?) -> CVPixelBuffer? {
    var pixelBuffer: CVPixelBuffer?
    let attributes: [CFString: Any] = [
        kCVPixelBufferCGImageCompatibilityKey: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        kCVPixelBufferWidthKey: Int(size.width),
        kCVPixelBufferHeightKey: Int(size.height),
        kCVPixelBufferPixelFormatTypeKey: Int(kCVPixelFormatType_32BGRA)
    ]

    let status: CVReturn
    if let pool {
        status = CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer)
    } else {
        status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32BGRA, attributes as CFDictionary, &pixelBuffer)
    }

    guard status == kCVReturnSuccess, let pixelBuffer else {
        return nil
    }

    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

    guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
        return nil
    }

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: baseAddress,
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
    ) else {
        return nil
    }

    context.clear(CGRect(origin: .zero, size: size))
    context.draw(image, in: CGRect(origin: .zero, size: size))
    return pixelBuffer
}

private func interpolate(from: CGFloat, to: CGFloat, progress: Double) -> CGFloat {
    from + ((to - from) * progress)
}

private func easeOutCubic(_ progress: Double) -> Double {
    let p = min(max(progress, 0), 1)
    return 1 - pow(1 - p, 3)
}

private struct OverlayRenderStageView: View {
    let width: CGFloat
    let height: CGFloat
    let state: OverlayFrameState

    private let buttonScale: CGFloat = 2
    private let cursorWidth: CGFloat = 32
    private let cursorHeight: CGFloat = 40

    private var cursorHotspotX: CGFloat {
        cursorWidth * (3 / 30)
    }

    private var cursorHotspotY: CGFloat {
        cursorHeight * (2 / 38)
    }

    private var cursorPositionForHotspot: CGPoint {
        CGPoint(
            x: state.cursorPosition.x + ((cursorWidth * 0.5) - cursorHotspotX),
            y: state.cursorPosition.y + ((cursorHeight * 0.5) - cursorHotspotY)
        )
    }

    var body: some View {
        ZStack {
            Color.clear

            PrimaryActionButton(
                title: state.buttonText,
                systemImage: state.systemImage,
                palette: state.theme.palette,
                isDefaultAction: false,
                defersActionUntilNextRunLoop: false,
                renderState: state.buttonRenderState,
                action: {}
            )
            .scaleEffect(buttonScale, anchor: .center)
            .position(x: width * 0.5, y: height * 0.5)

            if state.cursorVisible {
                CursorOverlayShape()
                    .fill(Color.white.opacity(0.96))
                    .overlay(
                        CursorOverlayShape()
                            .stroke(Color(red: 18 / 255, green: 18 / 255, blue: 21 / 255).opacity(0.78), lineWidth: 1.6)
                    )
                    .frame(width: cursorWidth, height: cursorHeight)
                    .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 6)
                    .position(x: cursorPositionForHotspot.x, y: cursorPositionForHotspot.y)
            }
        }
        .frame(width: width, height: height)
        .background(Color.clear)
    }
}

private struct CursorOverlayShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(
                x: rect.minX + (rect.width * x / 30),
                y: rect.minY + (rect.height * y / 38)
            )
        }

        var path = Path()
        path.move(to: point(3, 2))
        path.addLine(to: point(24, 21))
        path.addLine(to: point(14, 21))
        path.addLine(to: point(18, 35))
        path.addLine(to: point(13, 37))
        path.addLine(to: point(9, 23))
        path.addLine(to: point(1, 31))
        path.closeSubpath()
        return path
    }
}
