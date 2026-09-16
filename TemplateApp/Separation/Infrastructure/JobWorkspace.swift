import Foundation
import Darwin
import OSLog

/// Audio is temporary. Durable journals contain only ownership, bookmarks and locks.
/// Every cleanup holds the journal lock; legacy jobs also retain their original lock.
final class JobWorkspace {
    let url: URL
    private let descriptor: Int32
    private let journalDescriptor: Int32
    static var root: URL { FileManager.default.temporaryDirectory.appendingPathComponent("StemSeparatorJobs", isDirectory: true) }
    static var journalRoot: URL { FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("com.oliviergrenierbedard.stemseparator/CleanupRecovery", isDirectory: true) }
    private static let marker = "StemSeparatorJob-v1"
    private static let log = Logger(subsystem: "com.oliviergrenierbedard.stemseparator", category: "cleanup")

    init(id: UUID) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: Self.root, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        url = Self.root.appendingPathComponent(id.uuidString, isDirectory: true)
        let journal = try Self.makeJournal(id.uuidString)
        journalDescriptor = Self.lock(journal)
        guard journalDescriptor >= 0 else { throw SeparationFailure(message: "Could not lock the cleanup journal.") }
        do {
            try fm.createDirectory(at: url, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            descriptor = Self.lock(url)
            guard descriptor >= 0 else { throw SeparationFailure(message: "Could not create the temporary workspace.") }
            try Data(Self.marker.utf8).write(to: url.appendingPathComponent(".owner"), options: .atomic)
        } catch {
            Self.unlock(journalDescriptor)
            throw error
        }
    }
    deinit {
        _ = Self.clean(url, journal: Self.journalRoot.appendingPathComponent(url.lastPathComponent))
        Self.unlock(descriptor)
        Self.unlock(journalDescriptor)
    }
    private static func lock(_ directory: URL) -> Int32 {
        let fd = open(directory.appendingPathComponent(".lock").path, O_CREAT | O_RDWR | O_NOFOLLOW, 0o600)
        guard fd >= 0 else { return -1 }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { close(fd); return -1 }
        return fd
    }
    private static func unlock(_ fd: Int32) { flock(fd, LOCK_UN); close(fd) }
    private static func owned(_ directory: URL) -> Bool {
        guard let info = try? directory.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]),
              info.isDirectory == true, info.isSymbolicLink != true else { return false }
        return (try? String(contentsOf: directory.appendingPathComponent(".owner"), encoding: .utf8)) == marker
    }
    private static func makeJournal(_ name: String) throws -> URL {
        guard UUID(uuidString: name) != nil else { throw SeparationFailure(message: "Invalid cleanup ownership.") }
        let fm = FileManager.default
        try fm.createDirectory(at: journalRoot, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let journal = journalRoot.appendingPathComponent(name, isDirectory: true)
        if fm.fileExists(atPath: journal.path) {
            guard owned(journal) else { throw SeparationFailure(message: "Cleanup journal ownership is invalid.") }
        } else {
            try fm.createDirectory(at: journal, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            try Data(marker.utf8).write(to: journal.appendingPathComponent(".owner"), options: .atomic)
        }
        return journal
    }
    static func recordStaging(workspace: URL, destination: URL, stage: URL) throws {
        let journal = try makeJournal(workspace.lastPathComponent)
        let bookmark = try destination.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        let record = StagingRecord(bookmark: bookmark, name: stage.lastPathComponent, owner: workspace.lastPathComponent)
        // Persist before any audio is written to staging. Local copy supports legacy recovery.
        let data = try JSONEncoder().encode(record)
        try data.write(to: journal.appendingPathComponent("staging.json"), options: .atomic)
        try data.write(to: workspace.appendingPathComponent("staging.json"), options: .atomic)
        try Data(record.owner.utf8).write(to: stage.appendingPathComponent(".stem-separator-owner"), options: .atomic)
    }
    /// Returns unresolved inactive jobs. Active jobs are never reported or cleaned.
    @discardableResult static func recover() -> Int {
        let fm = FileManager.default
        let legacy = (try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        let journals = (try? fm.contentsOfDirectory(at: journalRoot, includingPropertiesForKeys: nil)) ?? []
        var pending = 0
        for name in Set((legacy + journals).map(\.lastPathComponent)) where UUID(uuidString: name) != nil {
            let workspace = root.appendingPathComponent(name), journal = journalRoot.appendingPathComponent(name)
            guard owned(journal) || owned(workspace) else { continue }
            do {
                let durable = try makeJournal(name)
                let journalFD = lock(durable)
                guard journalFD >= 0 else { continue }
                defer { unlock(journalFD) }
                var workspaceFD: Int32 = -1
                if fm.fileExists(atPath: workspace.path) {
                    guard owned(workspace) else { pending += 1; continue }
                    workspaceFD = lock(workspace)
                    guard workspaceFD >= 0 else { continue }
                }
                defer { if workspaceFD >= 0 { unlock(workspaceFD) } }
                if !clean(workspace, journal: durable) { pending += 1 }
            } catch { pending += 1; log.error("Cleanup journal unavailable; retry required") }
        }
        return pending
    }
    private static func clean(_ workspace: URL, journal: URL) -> Bool {
        let fm = FileManager.default
        let durable = journal.appendingPathComponent("staging.json")
        let local = workspace.appendingPathComponent("staging.json")
        do {
            if !fm.fileExists(atPath: durable.path), fm.fileExists(atPath: local.path) {
                try Data(contentsOf: local).write(to: durable, options: .atomic)
            }
            var outputClean = true
            if fm.fileExists(atPath: durable.path) {
                outputClean = false
                if let data = try? Data(contentsOf: durable), let record = try? JSONDecoder().decode(StagingRecord.self, from: data),
                   record.owner == journal.lastPathComponent, record.name.hasPrefix(".stem-separator-"),
                   UUID(uuidString: String(record.name.dropFirst(".stem-separator-".count))) != nil {
                    outputClean = removeStaging(record)
                }
            }
            // Remove audio before ownership/lock records so a failure cannot strand unmarked audio.
            if fm.fileExists(atPath: workspace.path) {
                guard owned(workspace) else { return false }
                let metadata: Set<String> = [".owner", ".lock", "staging.json"]
                for file in try fm.contentsOfDirectory(at: workspace, includingPropertiesForKeys: nil) where !metadata.contains(file.lastPathComponent) {
                    try fm.removeItem(at: file)
                }
                // Durable record now survives even if macOS purges the entire temporary directory.
                try fm.removeItem(at: workspace)
            }
            if outputClean { try fm.removeItem(at: journal); return true }
            log.notice("Output cleanup pending; durable metadata retained for retry")
        } catch { log.error("Temporary cleanup incomplete; durable record retained for retry") }
        return false
    }
    private static func removeStaging(_ record: StagingRecord) -> Bool {
        var stale = false
        guard let parent = try? URL(resolvingBookmarkData: record.bookmark, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale) else { return false }
        let scope = parent.startAccessingSecurityScopedResource()
        defer { if scope { parent.stopAccessingSecurityScopedResource() } }
        guard (try? parent.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { return false }
        let stage = parent.appendingPathComponent(record.name)
        do {
            let info = try stage.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey])
            guard info.isDirectory == true, info.isSymbolicLink != true,
                  (try? String(contentsOf: stage.appendingPathComponent(".stem-separator-owner"), encoding: .utf8)) == record.owner else { return false }
            guard access(parent.path, W_OK | X_OK) == 0 else { return false }
            // Preserve marker until payload removal succeeds.
            for file in try FileManager.default.contentsOfDirectory(at: stage, includingPropertiesForKeys: nil) where file.lastPathComponent != ".stem-separator-owner" {
                try FileManager.default.removeItem(at: file)
            }
            let owner = stage.appendingPathComponent(".stem-separator-owner")
            try FileManager.default.removeItem(at: owner)
            if rmdir(stage.path) == 0 { return true }
            // If parent permissions changed during cleanup, restore the ownership proof.
            try Data(record.owner.utf8).write(to: owner, options: .atomic)
            return false
        } catch let error as NSError {
            return error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError
        }
    }
    private struct StagingRecord: Codable { let bookmark: Data; let name: String; let owner: String }
}
