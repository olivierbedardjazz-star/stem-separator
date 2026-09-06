import Foundation
import Darwin

enum StemOutputWriter {
    static let names = ["vocals", "drums", "bass", "other"]
    static func commit(stems: [WorkerStem], input: PreparedAudio, workspace: URL, destination: URL,
                       baseName: String, control: JobControl) throws -> URL {
        let fm = FileManager.default
        let stage = destination.appendingPathComponent(".stem-separator-" + UUID().uuidString, isDirectory: true)
        try fm.createDirectory(at: stage, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        defer { try? fm.removeItem(at: stage) }
        try JobWorkspace.recordStaging(workspace: workspace, destination: destination, stage: stage)
        var peak: Float = 1
        let workerOutput = workspace.appendingPathComponent("worker-output")
        for stem in stems {
            let url = workerOutput.appendingPathComponent(stem.file)
            let attributes = try fm.attributesOfItem(atPath: url.path)
            guard attributes[.type] as? FileAttributeType == .typeRegular,
                  (attributes[.size] as? NSNumber)?.intValue == input.frames * 8 else {
                throw SeparationFailure(message: "A stem file was incomplete. No output folder was saved.")
            }
            try readSamples(url, control: control) { values in
                for value in values {
                    guard value.isFinite else { throw SeparationFailure(message: "The model produced invalid audio. No output folder was saved.") }
                    peak = max(peak, abs(value))
                }
            }
        }
        // One common attenuation retains relative stem balance and prevents PCM clipping.
        let gain = peak > 1 ? 0.999 / peak : 1
        for stem in stems {
            try control.check()
            let url = stage.appendingPathComponent(stem.name + ".wav")
            let byteCount = input.frames * 6
            var header = Data()
            func text(_ s: String) { header.append(contentsOf: s.utf8) }
            func u16(_ n: UInt16) { var v = n.littleEndian; withUnsafeBytes(of: &v) { header.append(contentsOf: $0) } }
            func u32(_ n: UInt32) { var v = n.littleEndian; withUnsafeBytes(of: &v) { header.append(contentsOf: $0) } }
            text("RIFF"); u32(UInt32(36 + byteCount)); text("WAVEfmt "); u32(16)
            u16(1); u16(2); u32(44100); u32(44100 * 6); u16(6); u16(24)
            text("data"); u32(UInt32(byteCount))
            guard fm.createFile(atPath: url.path, contents: header) else { throw SeparationFailure(message: "Could not write the output folder. Check its permissions and free disk space.") }
            let file = try FileHandle(forWritingTo: url)
            do {
                try file.seekToEnd()
                try readSamples(workerOutput.appendingPathComponent(stem.file), control: control) { values in
                    var data = Data(capacity: values.count * 3)
                    for value in values {
                        let pcm = Int32((max(-1, min(1, value * gain)) * 8388607).rounded())
                        data.append(UInt8(truncatingIfNeeded: pcm))
                        data.append(UInt8(truncatingIfNeeded: pcm >> 8))
                        data.append(UInt8(truncatingIfNeeded: pcm >> 16))
                    }
                    try file.write(contentsOf: data)
                }
                try file.synchronize(); try file.close()
            } catch { try? file.close(); throw error }
        }
        let safe = String(baseName.replacingOccurrences(of: ":", with: "-").replacingOccurrences(of: "/", with: "-").prefix(100))
        for index in 1...10000 {
            try control.check()
            let name = (safe.isEmpty ? "Audio" : safe) + " - Stems" + (index == 1 ? "" : " (\(index))")
            let target = destination.appendingPathComponent(name, isDirectory: true)
            // Same-volume atomic, exclusive rename: never replace another result, even in a race.
            if renamex_np(stage.path, target.path, UInt32(RENAME_EXCL)) == 0 {
                try? fm.removeItem(at: target.appendingPathComponent(".stem-separator-owner"))
                return target
            }
            if errno != EEXIST { throw SeparationFailure(message: "Could not finish the output folder. Choose a writable local folder with enough free space.") }
        }
        throw SeparationFailure(message: "Too many folders share this audio name. Choose another output folder.")
    }
    private static func readSamples(_ url: URL, control: JobControl, body: ([Float]) throws -> Void) throws {
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        while let data = try file.read(upToCount: 65536), !data.isEmpty {
            try control.check()
            guard data.count % 4 == 0 else { throw SeparationFailure(message: "A stem file was incomplete.") }
            let samples: [Float] = data.withUnsafeBytes { bytes in
                stride(from: 0, to: bytes.count, by: 4).map { bytes.loadUnaligned(fromByteOffset: $0, as: Float.self) }
            }
            try body(samples)
        }
    }
}
