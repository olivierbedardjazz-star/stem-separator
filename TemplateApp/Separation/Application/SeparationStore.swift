import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor
final class SeparationStore: ObservableObject {
    @Published private(set) var selection: AudioSelection?
    @Published private(set) var destination: URL?
    @Published private(set) var result: URL?
    @Published private(set) var stage: SeparationStage?
    @Published private(set) var progress: Double?
    @Published private(set) var message: String?
    @Published private(set) var isInspecting = false
    @Published private(set) var isChoosingDestination = false
    @Published var isAuthorized = false
    @Published var updaterBusy = false
    private var selectionGeneration = UUID()
    private var jobID: UUID?
    private var control: JobControl?
    private let defaults: UserDefaults
    private let chooseOutputFolder: @MainActor (URL?) async -> URL?
    var isBusy: Bool { jobID != nil }
    var canStart: Bool { isAuthorized && !isBusy && !isInspecting && !updaterBusy && !isChoosingDestination && selection != nil }
    var canSelect: Bool { isAuthorized && !isBusy && !updaterBusy && !isChoosingDestination }

    init(defaults: UserDefaults = .standard, chooseOutputFolder: @escaping @MainActor (URL?) async -> URL? = SeparationStore.presentOutputFolder) {
        self.defaults = defaults
        self.chooseOutputFolder = chooseOutputFolder
        if let bookmark = defaults.data(forKey: "stem-separator.v1.output-bookmark") {
            var stale = false
            if let url = try? URL(resolvingBookmarkData: bookmark, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale), !stale {
                destination = url
            } else { defaults.removeObject(forKey: "stem-separator.v1.output-bookmark") }
        }
    }
    func chooseAudio() {
        guard canSelect else { return }
        let panel = NSOpenPanel()
        panel.title = "Choose audio"; panel.allowsMultipleSelection = false; panel.canChooseDirectories = false
        panel.allowedContentTypes = AudioPreparationService.supportedExtensions.compactMap { UTType(filenameExtension: $0) }
        if panel.runModal() == .OK, let url = panel.url { accept([url]) }
    }
    func accept(_ urls: [URL]) {
        guard canSelect else { return }
        guard urls.count == 1, let url = urls.first else { message = "Drop one audio file at a time."; return }
        let generation = UUID(); selectionGeneration = generation; isInspecting = true; message = nil
        Task { [weak self] in
            let value = await Task.detached(priority: .userInitiated) { Result { try AudioPreparationService.inspect(url) } }.value
            guard let self, self.selectionGeneration == generation else { return }
            self.isInspecting = false
            switch value {
            case .success(let audio): self.selection = audio; self.result = nil
            case .failure: self.message = SeparationFailure.invalidAudio.message
            }
        }
    }
    func clearAudio() {
        guard canSelect else { return }
        // A pending metadata read must not restore a selection after it is cleared.
        selectionGeneration = UUID()
        selection = nil
        isInspecting = false
        result = nil
        message = nil
    }
    static func presentOutputFolder(initial: URL?) async -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose where to save your stems"
        panel.prompt = "Separate Stems"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = initial
        return await withCheckedContinuation { continuation in
            panel.begin { response in
                continuation.resume(returning: response == .OK ? panel.url : nil)
            }
        }
    }
    func start() {
        guard canStart else { return }
        isChoosingDestination = true
        Task { [weak self] in
            guard let self else { return }
            let folder = await self.chooseOutputFolder(self.destination)
            self.isChoosingDestination = false
            // Cancelling the picker never falls back to the previous destination.
            guard let folder, self.canStart else { return }
            self.destination = folder
            let data = try? folder.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            self.defaults.set(data, forKey: "stem-separator.v1.output-bookmark")
            self.startJob(destination: folder)
        }
    }
    private func startJob(destination: URL) {
        guard canStart, let selection else { return }
        let id = UUID(), control = JobControl()
        self.jobID = id; self.control = control; stage = .preparing; progress = nil; result = nil; message = nil
        let session = SeparationSession(worker: StemWorkerProcess(executable: StemWorkerProcess.bundledExecutable))
        let store = self
        Task { [weak self] in
            let outcome = await Task.detached(priority: .userInitiated) {
                Result { try session.run(selection: selection, destination: destination, jobID: id, control: control) { stage, progress in
                    Task { @MainActor in
                        guard store.jobID == id, store.stage != .cancelling else { return }
                        store.stage = stage; store.progress = progress
                    }
                } }
            }.value
            guard let self, self.jobID == id else { return }
            self.jobID = nil; self.control = nil; self.stage = nil; self.progress = nil
            switch outcome {
            case .success(let folder): self.result = folder; self.message = nil
            case .failure(let error):
                self.message = (error as? SeparationFailure)?.message ?? "Could not finish this job. Check that the audio and output folder are still available and there is enough free disk space."
            }
        }
    }
    func cancel() {
        guard isBusy, stage != .cancelling else { return }
        stage = .cancelling; progress = nil; control?.cancel()
    }
    func reveal() {
        guard let result, FileManager.default.fileExists(atPath: result.path) else {
            message = "The result folder was moved or removed."; return
        }
        NSWorkspace.shared.activateFileViewerSelecting([result])
    }
}
