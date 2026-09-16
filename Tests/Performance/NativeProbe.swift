import Foundation
import AVFoundation
import Darwin

final class WritingCounter: @unchecked Sendable {
    private let lock = NSLock(); private var count = 0
    func next() -> Int { lock.lock(); defer { lock.unlock() }; count += 1; return count }
}

@main struct NativeProbe {
    static func emit(_ values: [String: Any]) {
        var out = values; out["time"] = Date().timeIntervalSince1970
        let data = try! JSONSerialization.data(withJSONObject: out, options: [.sortedKeys])
        FileHandle.standardOutput.write(data + Data([10]))
    }
    static func main() throws {
        let args = CommandLine.arguments
        let mode = args[1]
        let fm = FileManager.default
        if mode == "session" {
            let source = URL(fileURLWithPath: args[2]), destination = URL(fileURLWithPath: args[3])
            let worker = URL(fileURLWithPath: args[4]), cancelAt = args.count > 5 ? args[5] : "none"
            let outputMode = args.count > 6 ? SeparationMode(rawValue: args[6])! : .stems
            let control = JobControl(); let writingCounter = WritingCounter()
            emit(["type": "start", "tempRoot": JobWorkspace.root.path])
            do {
                let selection = try AudioPreparationService.inspect(source)
                let result = try SeparationSession(worker: StemWorkerProcess(executable: worker)).run(selection: selection, destination: destination, jobID: UUID(), control: control, mode: outputMode) { stage, fraction in
                    emit(["type": "phase", "stage": stage.rawValue, "fraction": fraction as Any? ?? NSNull()])
                    if stage == .writing && writingCounter.next() == 2 && cancelAt == "native-writing" {
                        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(50)) { control.cancel() }
                    }
                    if (cancelAt == "inference" && stage == .separating && (fraction ?? 0) > 0) || (cancelAt == "writing" && stage == .writing) { control.cancel() }
                }
                emit(["type": "result", "folder": result.lastPathComponent])
            } catch { emit(["type": "error", "message": error.localizedDescription]) }
            emit(["type": "end", "remainingJobs": (try? fm.contentsOfDirectory(atPath: JobWorkspace.root.path).count) ?? 0])
        } else if mode == "recover" {
            JobWorkspace.recover(); emit(["type": "recovered"])
        } else if mode == "crash-stage" {
            let lease = try JobWorkspace(id: UUID())
            let dest = URL(fileURLWithPath: args[2])
            let stage = dest.appendingPathComponent(".stem-separator-" + UUID().uuidString)
            try fm.createDirectory(at: stage, withIntermediateDirectories: false)
            try JobWorkspace.recordStaging(workspace: lease.url, destination: dest, stage: stage)
            try Data(repeating: 1, count: 1024 * 1024).write(to: stage.appendingPathComponent("partial.wav"))
            emit(["type": "crashReady", "job": lease.url.path, "stage": stage.path])
            _exit(99) // Deliberate test-process death: no deinit cleanup.
        } else if mode == "lease-tests" {
            for _ in 0..<100 {
                do { let lease = try JobWorkspace(id: UUID()); try Data(repeating: 1, count: 4096).write(to: lease.url.appendingPathComponent("input")); withExtendedLifetime(lease) {} }
            }
            let before = try fm.contentsOfDirectory(atPath: JobWorkspace.root.path).count
            let live = try JobWorkspace(id: UUID())
            let unknown = JobWorkspace.root.appendingPathComponent(UUID().uuidString)
            try fm.createDirectory(at: unknown, withIntermediateDirectories: false)
            JobWorkspace.recover()
            emit(["type": "leaseTests", "remainingAfter100": before, "liveProtected": fm.fileExists(atPath: live.url.path), "unmarkedProtected": fm.fileExists(atPath: unknown.path)])
            try fm.removeItem(at: unknown); withExtendedLifetime(live) {}
        } else if mode == "corrupt-output" {
            let lease = try JobWorkspace(id: UUID()), dest = URL(fileURLWithPath: args[2])
            let worker = lease.url.appendingPathComponent("worker-output")
            try fm.createDirectory(at: worker, withIntermediateDirectories: false)
            let stems = StemOutputWriter.names.map { WorkerStem(name: $0, file: $0 + ".f32le", byteCount: 8) }
            for s in stems { try Data([0]).write(to: worker.appendingPathComponent(s.file)) }
            do {
                _ = try StemOutputWriter.commit(stems: stems, input: PreparedAudio(url: lease.url, frames: 1), workspace: lease.url, destination: dest, baseName: "invalid", control: JobControl())
                emit(["type": "unexpectedSuccess"])
            } catch { emit(["type": "expectedFailure", "remainingDestinationItems": try fm.contentsOfDirectory(atPath: dest.path).count]) }
            withExtendedLifetime(lease) {}
        }
    }
}
