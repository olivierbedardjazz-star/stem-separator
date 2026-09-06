import AVFoundation
import XCTest
@testable import TemplateApp

final class SeparationTests: XCTestCase {
    private func directory() throws -> URL {
        let base = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("build/Tests")
        let url = base.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    private func fixture(at root: URL, rate: Double = 48000, channels: AVAudioChannelCount = 1, seconds: Double = 0.3) throws -> URL {
        let url = root.appendingPathComponent("Audio ' café ; $(safe).wav")
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: rate, channels: channels, interleaved: false)!
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(rate * seconds))!
        buffer.frameLength = buffer.frameCapacity
        for channel in 0..<Int(channels) {
            for i in 0..<Int(buffer.frameLength) { buffer.floatChannelData![channel][i] = Float(sin(Double(i) * 440 * 2 * .pi / rate) * 0.1) }
        }
        try file.write(from: buffer)
        return url
    }
    func testNativeConversionAndTransactionalWAV() throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        let selection = try AudioPreparationService.inspect(fixture(at: root))
        XCTAssertEqual(selection.channels, 1)
        let control = JobControl()
        let prepared = try AudioPreparationService.prepare(selection, directory: root, control: control)
        XCTAssertEqual(prepared.frames, 13230, accuracy: 2)
        let data = try Data(contentsOf: prepared.url)
        XCTAssertEqual(data.count, prepared.frames * 8)
        let workerOutput = root.appendingPathComponent("worker-output")
        try FileManager.default.createDirectory(at: workerOutput, withIntermediateDirectories: false)
        let stems = StemOutputWriter.names.map { WorkerStem(name: $0, file: $0 + ".f32le", byteCount: data.count) }
        for stem in stems { try data.write(to: workerOutput.appendingPathComponent(stem.file)) }
        let first = try StemOutputWriter.commit(stems: stems, input: prepared, workspace: root, destination: root, baseName: "Song", control: control)
        let second = try StemOutputWriter.commit(stems: stems, input: prepared, workspace: root, destination: root, baseName: "Song", control: control)
        XCTAssertEqual(first.lastPathComponent, "Song - Stems")
        XCTAssertEqual(second.lastPathComponent, "Song - Stems (2)")
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: first.path).sorted(), StemOutputWriter.names.map { $0 + ".wav" }.sorted())
        for name in StemOutputWriter.names {
            let file = try AVAudioFile(forReading: first.appendingPathComponent(name + ".wav"))
            XCTAssertEqual(file.length, Int64(prepared.frames))
            XCTAssertEqual(file.fileFormat.sampleRate, 44100)
            XCTAssertEqual(file.fileFormat.channelCount, 2)
            XCTAssertEqual(file.fileFormat.settings[AVLinearPCMBitDepthKey] as? Int, 24)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: selection.url.path))
    }
    func testCorruptStemNeverCommits() throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        let worker = root.appendingPathComponent("worker-output")
        try FileManager.default.createDirectory(at: worker, withIntermediateDirectories: false)
        let stems = StemOutputWriter.names.map { WorkerStem(name: $0, file: $0 + ".f32le", byteCount: 8) }
        for stem in stems { try Data([0]).write(to: worker.appendingPathComponent(stem.file)) }
        XCTAssertThrowsError(try StemOutputWriter.commit(stems: stems, input: PreparedAudio(url: root, frames: 1), workspace: root, destination: root, baseName: "Bad", control: JobControl()))
        XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: root.path).contains { $0.hasPrefix(".stem-separator-") || $0 == "Bad - Stems" })
    }
    func testCancelledBeforePreparation() throws {
        let control = JobControl(); control.cancel()
        XCTAssertThrowsError(try control.check())
    }
    func testBundledWorkerEndToEnd() throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        let source = try fixture(at: root, rate: 44100, channels: 2, seconds: 2)
        let selection = try AudioPreparationService.inspect(source)
        let result = try SeparationSession(worker: StemWorkerProcess(executable: StemWorkerProcess.bundledExecutable))
            .run(selection: selection, destination: root, jobID: UUID(), control: JobControl()) { _, _ in }
        for name in StemOutputWriter.names {
            let audio = try AVAudioFile(forReading: result.appendingPathComponent(name + ".wav"))
            XCTAssertEqual(audio.length, 88200)
            XCTAssertEqual(audio.fileFormat.settings[AVLinearPCMBitDepthKey] as? Int, 24)
        }
    }
    func testMissingWorkerFailsClearly() throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertThrowsError(try StemWorkerProcess(executable: root.appendingPathComponent("missing"))
            .run(input: PreparedAudio(url: root, frames: 1), jobID: UUID(), directory: root, control: JobControl()) { _, _ in }) { error in
                XCTAssertTrue(error.localizedDescription.contains("missing"))
            }
    }
    func testBundledWorkerMultipleChunksAndSaving() throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        let selection = try AudioPreparationService.inspect(fixture(at: root, rate: 48000, channels: 2, seconds: 14))
        let result = try SeparationSession(worker: StemWorkerProcess(executable: StemWorkerProcess.bundledExecutable))
            .run(selection: selection, destination: root, jobID: UUID(), control: JobControl()) { _, _ in }
        for name in StemOutputWriter.names {
            let audio = try AVAudioFile(forReading: result.appendingPathComponent(name + ".wav"))
            XCTAssertEqual(audio.length, 14 * 44100, accuracy: 2)
            XCTAssertEqual(audio.fileFormat.settings[AVLinearPCMBitDepthKey] as? Int, 24)
        }
    }
    func testDestinationFailureIdentifiesPhaseWithoutPath() throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        let selection = try AudioPreparationService.inspect(fixture(at: root))
        let missing = root.appendingPathComponent("private-destination-name")
        XCTAssertThrowsError(try SeparationSession(worker: StemWorkerProcess(executable: StemWorkerProcess.bundledExecutable))
            .run(selection: selection, destination: missing, jobID: UUID(), control: JobControl()) { _, _ in }) { error in
                let message = (error as? SeparationFailure)?.message ?? ""
                XCTAssertTrue(message.contains("checking output folder"))
                XCTAssertTrue(message.contains("NSCocoaErrorDomain"))
                XCTAssertFalse(message.contains(missing.lastPathComponent))
                XCTAssertFalse(message.contains(root.path))
            }
    }
    func testNativeMP3AndM4AAndAIFFIntake() throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        let mp3 = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Fixtures/generated-tone.mp3")
        let formats: [(String, [String: Any])] = [
            ("m4a", [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 128000]),
            ("aiff", [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 2, AVLinearPCMBitDepthKey: 16, AVLinearPCMIsBigEndianKey: true, AVLinearPCMIsFloatKey: false])
        ]
        var files = [mp3]
        for (suffix, settings) in formats {
            let url = root.appendingPathComponent("tone." + suffix)
            do {
                let audio = try AVAudioFile(forWriting: url, settings: settings)
                let buffer = AVAudioPCMBuffer(pcmFormat: audio.processingFormat, frameCapacity: 44100)!
                buffer.frameLength = 44100
                for c in 0..<2 { for i in 0..<44100 { buffer.floatChannelData![c][i] = Float(sin(Double(i) * 0.1) * 0.1) } }
                try audio.write(from: buffer)
            }
            files.append(url)
        }
        for url in files {
            let selection = try AudioPreparationService.inspect(url)
            let prepared = try AudioPreparationService.prepare(selection, directory: root, control: JobControl())
            XCTAssertGreaterThan(prepared.frames, 40000)
            XCTAssertLessThan(prepared.frames, 50000)
            try FileManager.default.removeItem(at: prepared.url)
        }
    }
    func testCancelRunningBundledJob() throws {
        let root = try directory(); defer { try? FileManager.default.removeItem(at: root) }
        let selection = try AudioPreparationService.inspect(fixture(at: root, seconds: 10))
        let control = JobControl()
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) { control.cancel() }
        XCTAssertThrowsError(try SeparationSession(worker: StemWorkerProcess(executable: StemWorkerProcess.bundledExecutable))
            .run(selection: selection, destination: root, jobID: UUID(), control: control) { _, _ in }) { error in
                XCTAssertEqual((error as? SeparationFailure)?.message, SeparationFailure.cancelled.message)
            }
        XCTAssertFalse(try FileManager.default.contentsOfDirectory(atPath: root.path).contains { $0.hasSuffix("Stems") || $0.hasPrefix(".stem-separator-") })
    }
    func testRecoverySkipsLiveAndUnmarkedWorkspaces() throws {
        let live = try JobWorkspace(id: UUID())
        let unknown = JobWorkspace.root.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: unknown, withIntermediateDirectories: false)
        defer { try? FileManager.default.removeItem(at: unknown); withExtendedLifetime(live) {} }
        JobWorkspace.recover()
        XCTAssertTrue(FileManager.default.fileExists(atPath: live.url.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: unknown.path))
    }
    @MainActor func testSettingsDoNotReuseTemplateAcceptanceAndQueueRejectsMultiple() {
        let suite = "StemSeparatorTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(99, forKey: "template-app.responsible-use-version")
        let settings = AppSettingsStore(defaults: defaults)
        XCTAssertFalse(settings.hasAcceptedResponsibleUse)
        settings.acceptResponsibleUse(); XCTAssertTrue(settings.hasAcceptedResponsibleUse)
        let store = SeparationStore(defaults: defaults); store.isAuthorized = true
        store.accept([URL(fileURLWithPath: "/a"), URL(fileURLWithPath: "/b")])
        XCTAssertEqual(store.message, "Drop one audio file at a time.")
        XCTAssertNil(store.selection); XCTAssertFalse(store.canStart)
    }
    @MainActor func testClearAudioInvalidatesPendingReadAndKeepsOriginal() async throws {
        let root = try directory()
        let suite = "StemSeparatorTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer {
            try? FileManager.default.removeItem(at: root)
            defaults.removePersistentDomain(forName: suite)
        }
        let url = try fixture(at: root)
        let original = try Data(contentsOf: url)
        let store = SeparationStore(defaults: defaults)
        store.isAuthorized = true
        store.accept([url])
        store.clearAudio()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertNil(store.selection)
        XCTAssertFalse(store.isInspecting)
        XCTAssertFalse(store.canStart)

        store.accept([url])
        for _ in 0..<200 where store.isInspecting {
            try await Task.sleep(for: .milliseconds(10))
        }
        XCTAssertEqual(store.selection?.url, url)
        XCTAssertNil(store.destination)
        XCTAssertTrue(store.canStart)
        store.updaterBusy = true
        store.clearAudio()
        XCTAssertNotNil(store.selection)
        store.updaterBusy = false
        store.clearAudio()
        XCTAssertNil(store.selection)
        XCTAssertNil(store.message)
        XCTAssertEqual(try Data(contentsOf: url), original)
    }
    @MainActor func testDestinationPromptCancellationNeverStartsOrUsesOldFolder() async throws {
        let root = try directory()
        let suite = "StemSeparatorTests." + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { try? FileManager.default.removeItem(at: root); defaults.removePersistentDomain(forName: suite) }
        defaults.set(try root.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil), forKey: "stem-separator.v1.output-bookmark")
        var calls = 0
        var response: CheckedContinuation<URL?, Never>?
        let store = SeparationStore(defaults: defaults) { initial in
            calls += 1
            XCTAssertEqual(initial?.path, root.path)
            return await withCheckedContinuation { response = $0 }
        }
        store.isAuthorized = true
        store.start()
        XCTAssertEqual(calls, 0)
        let url = try fixture(at: root)
        store.accept([url])
        for _ in 0..<200 where store.isInspecting { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertTrue(store.canStart)
        store.start()
        XCTAssertTrue(store.isChoosingDestination)
        XCTAssertFalse(store.canStart)
        XCTAssertFalse(store.canSelect)
        store.start()
        for _ in 0..<200 where response == nil { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertEqual(calls, 1)
        response?.resume(returning: nil)
        for _ in 0..<200 where store.isChoosingDestination { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertFalse(store.isChoosingDestination)
        XCTAssertFalse(store.isBusy)
        XCTAssertNil(store.result)
        XCTAssertNil(store.stage)
        XCTAssertEqual(store.selection?.url, url)
        XCTAssertTrue(store.canStart)
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path), [url.lastPathComponent])
    }
    @MainActor func testUpdaterPlaceholdersRemainDisarmed() {
        let config = AppUpdateConfiguration(feedURLString: "https://github.com/SET_GITHUB_OWNER/SET_GITHUB_REPOSITORY/releases/latest/download/appcast.xml", publicEDKey: "SET_SPARKLE_PUBLIC_KEY")
        XCTAssertFalse(config.isReadyForUpdates)
    }
    @MainActor func testUpdaterRejectsInvalidKeysAndCredentialBearingFeeds() {
        let feed = "https://github.com/olivierbedardjazz-star/stem-separator/releases/latest/download/appcast.xml"
        let key = Data(repeating: 1, count: 32).base64EncodedString()
        XCTAssertTrue(AppUpdateConfiguration(feedURLString: feed, publicEDKey: key).isReadyForUpdates)
        XCTAssertFalse(AppUpdateConfiguration(feedURLString: feed, publicEDKey: "abc").isReadyForUpdates)
        XCTAssertFalse(AppUpdateConfiguration(feedURLString: feed.replacingOccurrences(of: "https://", with: "https://user:password@"), publicEDKey: key).isReadyForUpdates)
        XCTAssertFalse(AppUpdateConfiguration(feedURLString: feed + "?token=example", publicEDKey: key).isReadyForUpdates)
    }
}
