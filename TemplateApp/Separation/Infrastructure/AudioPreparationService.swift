import AVFoundation
import Foundation

/// Synchronous I/O service; called only from the session's background task.
enum AudioPreparationService {
    static let supportedExtensions = ["wav", "wave", "aif", "aiff", "mp3", "m4a"]
    static func inspect(_ url: URL) throws -> AudioSelection {
        guard url.isFileURL, supportedExtensions.contains(url.pathExtension.lowercased()) else {
            throw SeparationFailure.invalidAudio
        }
        let scope = url.startAccessingSecurityScopedResource()
        defer { if scope { url.stopAccessingSecurityScopedResource() } }
        let audio: AVAudioFile
        do { audio = try AVAudioFile(forReading: url) } catch { throw SeparationFailure.invalidAudio }
        let format = audio.processingFormat
        let duration = Double(audio.length) / format.sampleRate
        guard audio.length > 0, duration.isFinite, duration <= 1200,
              (1...2).contains(format.channelCount) else { throw SeparationFailure.invalidAudio }
        return AudioSelection(url: url, duration: duration, sampleRate: format.sampleRate, channels: Int(format.channelCount))
    }
    static func prepare(_ selection: AudioSelection, directory: URL, control: JobControl) throws -> PreparedAudio {
        let scope = selection.url.startAccessingSecurityScopedResource()
        defer { if scope { selection.url.stopAccessingSecurityScopedResource() } }
        _ = try inspect(selection.url)
        let source = try AVAudioFile(forReading: selection.url)
        guard let target = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false),
              let converter = AVAudioConverter(from: source.processingFormat, to: target),
              let input = AVAudioPCMBuffer(pcmFormat: source.processingFormat, frameCapacity: 8192),
              let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: 8192) else {
            throw SeparationFailure.invalidAudio
        }
        let url = directory.appendingPathComponent("input.f32le")
        guard FileManager.default.createFile(atPath: url.path, contents: nil) else {
            throw SeparationFailure(message: "Could not create temporary audio. Check free disk space.")
        }
        let handle = try FileHandle(forWritingTo: url)
        defer { try? handle.close() }
        var frames = 0
        let reader = ConverterInputReader(source: source, buffer: input)
        while true {
            try control.check()
            var error: NSError?
            let status = converter.convert(to: output, error: &error) { count, status in
                reader.read(count: count, status: status)
            }
            if let readError = reader.error { throw readError }
            if status == .error { throw error ?? SeparationFailure.invalidAudio as NSError }
            let count = Int(output.frameLength)
            if count > 0, let channels = output.floatChannelData {
                var samples = [Float](repeating: 0, count: count * 2)
                for i in 0..<count {
                    let left = channels[0][i], right = channels[1][i]
                    guard left.isFinite, right.isFinite else { throw SeparationFailure.invalidAudio }
                    samples[i * 2] = left; samples[i * 2 + 1] = right
                }
                try samples.withUnsafeBytes { try handle.write(contentsOf: Data($0)) }
                frames += count
                guard frames <= 44100 * 1200 else { throw SeparationFailure.invalidAudio }
            }
            if status == .endOfStream { break }
        }
        guard frames > 0 else { throw SeparationFailure.invalidAudio }
        return PreparedAudio(url: url, frames: frames)
    }
}

// AVAudioConverter invokes its input block synchronously during convert(). The reader
// and its buffer never escape that one background conversion; no UI actor shares them.
private final class ConverterInputReader: @unchecked Sendable {
    let source: AVAudioFile
    let buffer: AVAudioPCMBuffer
    var error: Error?
    init(source: AVAudioFile, buffer: AVAudioPCMBuffer) { self.source = source; self.buffer = buffer }
    func read(count: AVAudioPacketCount, status: UnsafeMutablePointer<AVAudioConverterInputStatus>) -> AVAudioBuffer? {
        do {
            guard source.framePosition < source.length else { status.pointee = .endOfStream; return nil }
            let remaining = AVAudioFrameCount(min(Int64(UInt32.max), source.length - source.framePosition))
            try source.read(into: buffer, frameCount: min(count, buffer.frameCapacity, remaining))
            status.pointee = buffer.frameLength == 0 ? .endOfStream : .haveData
            return buffer.frameLength == 0 ? nil : buffer
        } catch { self.error = error; status.pointee = .endOfStream; return nil }
    }
}
