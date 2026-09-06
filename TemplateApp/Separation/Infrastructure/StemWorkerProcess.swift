import Foundation
import Darwin

struct StemWorkerProcess: Sendable {
    let executable: URL
    static var bundledExecutable: URL {
        Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/StemWorker.app/Contents/MacOS/StemWorker")
    }
    func run(input: PreparedAudio, jobID: UUID, directory: URL, control: JobControl,
             progress: @escaping @Sendable (SeparationStage, Double?) -> Void) throws -> [WorkerStem] {
        guard FileManager.default.isExecutableFile(atPath: executable.path) else {
            throw SeparationFailure(message: "The bundled separation engine is missing. Rebuild or reinstall Stem Separator.")
        }
        let process = Process(), stdin = Pipe(), stdout = Pipe(), stderr = Pipe()
        process.executableURL = executable
        process.currentDirectoryURL = directory
        process.environment = ["PATH": "/usr/bin:/bin", "HOME": directory.path, "TMPDIR": directory.path,
                               "PYTHONNOUSERSITE": "1", "OMP_NUM_THREADS": "4", "PYTORCH_ENABLE_MPS_FALLBACK": "0"]
        process.standardInput = stdin; process.standardOutput = stdout; process.standardError = stderr
        try control.attach(process)
        defer { control.detach(); try? stdin.fileHandleForWriting.close() }
        try control.check()
        signal(SIGPIPE, SIG_IGN)
        try process.run()
        if control.isCancelled { control.stopWorker() }
        let startupWatchdog = DispatchWorkItem { control.stopWorker() }
        DispatchQueue.global().asyncAfter(deadline: .now() + 45, execute: startupWatchdog)
        defer { startupWatchdog.cancel() }
        // Both pipes must drain concurrently. stderr is deliberately discarded, never logged.
        let drain = DispatchGroup()
        drain.enter()
        DispatchQueue.global().async {
            while !stderr.fileHandleForReading.availableData.isEmpty {}
            drain.leave()
        }
        let watchdog = DispatchWorkItem { control.stopWorker() }
        DispatchQueue.global().asyncAfter(deadline: .now() + 10800, execute: watchdog)
        defer { watchdog.cancel() }
        var buffer = Data(), ready = false, expectedSequence = 1
        var result: [WorkerStem]?
        var failure: Error?
        do {
            while true {
                let chunk = stdout.fileHandleForReading.availableData
                if chunk.isEmpty { break }
                buffer.append(chunk)
                while let newline = buffer.firstIndex(of: 10) {
                    guard newline < 65536 else { throw protocolFailure }
                    let line = Data(buffer.prefix(upTo: newline))
                    buffer.removeSubrange(...newline)
                    let event = try JSONDecoder().decode(WorkerEvent.self, from: line)
                    guard event.protocolVersion == 1 else { throw protocolFailure }
                    if !ready {
                        guard event.type == "ready", event.jobID == nil else { throw protocolFailure }
                        ready = true
                        startupWatchdog.cancel()
                        let request: [String: Any] = ["protocolVersion": 1, "type": "separate", "jobID": jobID.uuidString.lowercased(),
                            "input": ["path": input.url.path, "frames": input.frames, "channels": 2, "sampleRate": 44100,
                                      "layout": "interleaved", "sampleType": "float32-le", "byteCount": input.frames * 8],
                            "outputDirectory": directory.appendingPathComponent("worker-output").path,
                            "modelID": "htdemucs", "device": "cpu"]
                        var data = try JSONSerialization.data(withJSONObject: request); data.append(10)
                        try stdin.fileHandleForWriting.write(contentsOf: data)
                        continue
                    }
                    guard event.jobID == jobID.uuidString.lowercased(), event.sequence == expectedSequence, result == nil else { throw protocolFailure }
                    expectedSequence += 1
                    switch event.type {
                    case "stage":
                        guard let value = event.stage, let stage = SeparationStage(rawValue: value) else { throw protocolFailure }
                        progress(stage, nil)
                    case "progress":
                        guard let done = event.completedUnits, let total = event.totalUnits, total > 0, done >= 0, done <= total else { throw protocolFailure }
                        progress(.separating, Double(done) / Double(total))
                    case "result":
                        guard event.frames == input.frames, event.channels == 2, event.sampleRate == 44100,
                              event.sampleType == "float32-le", event.layout == "interleaved",
                              let stems = event.stems, stems.count == 4,
                              Set(stems.map(\.name)) == Set(["vocals", "drums", "bass", "other"]),
                              stems.allSatisfy({ $0.file == $0.name + ".f32le" && $0.byteCount == input.frames * 8 }) else { throw protocolFailure }
                        result = stems
                    case "error":
                        throw SeparationFailure(message: event.code == "modelIntegrity" ? "The bundled model failed its integrity check. Rebuild or reinstall the app." : "The separation engine could not finish. Try a shorter audio file.")
                    default: throw protocolFailure
                    }
                }
                guard buffer.count < 65536 else { throw protocolFailure }
            }
            guard buffer.isEmpty else { throw protocolFailure }
        } catch { failure = error; control.stopWorker() }
        process.waitUntilExit()
        drain.wait()
        try control.check()
        if let failure { throw failure }
        guard process.terminationReason == .exit, process.terminationStatus == 0, let result else {
            throw SeparationFailure(message: "The separation engine stopped unexpectedly. Try a shorter file, or close other memory-intensive apps.")
        }
        return result
    }
    private var protocolFailure: SeparationFailure { SeparationFailure(message: "The separation engine returned an invalid response. Rebuild or reinstall the app.") }
}
