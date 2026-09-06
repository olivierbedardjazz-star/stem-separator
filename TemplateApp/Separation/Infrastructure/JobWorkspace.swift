import Foundation
import Darwin

/// Recovery never follows symlinks or deletes an unmarked directory. A live job
/// owns an advisory lock, so a second app instance cannot sweep its workspace.
final class JobWorkspace {
    let url: URL
    private let descriptor: Int32
    static var root: URL { FileManager.default.temporaryDirectory.appendingPathComponent("StemSeparatorJobs", isDirectory: true) }
    init(id: UUID) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: Self.root, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        url = Self.root.appendingPathComponent(id.uuidString, isDirectory: true)
        try fm.createDirectory(at: url, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
        descriptor = open(url.appendingPathComponent(".lock").path, O_CREAT | O_RDWR | O_NOFOLLOW, 0o600)
        guard descriptor >= 0, flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            if descriptor >= 0 { close(descriptor) }
            throw SeparationFailure(message: "Could not create the temporary workspace.")
        }
        try Data("StemSeparatorJob-v1".utf8).write(to: url.appendingPathComponent(".owner"), options: .atomic)
    }
    deinit {
        try? FileManager.default.removeItem(at: url)
        flock(descriptor, LOCK_UN); close(descriptor)
    }
    static func recordStaging(workspace: URL, destination: URL, stage: URL) throws {
        let bookmark = try destination.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        let record = StagingRecord(bookmark: bookmark, name: stage.lastPathComponent, owner: workspace.lastPathComponent)
        try JSONEncoder().encode(record).write(to: workspace.appendingPathComponent("staging.json"), options: .atomic)
        try Data(record.owner.utf8).write(to: stage.appendingPathComponent(".stem-separator-owner"), options: .atomic)
    }
    static func recover() {
        let fm = FileManager.default
        guard let children = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isSymbolicLinkKey, .isDirectoryKey]) else { return }
        for child in children {
            guard UUID(uuidString: child.lastPathComponent) != nil,
                  let values = try? child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]),
                  values.isDirectory == true, values.isSymbolicLink != true,
                  (try? String(contentsOf: child.appendingPathComponent(".owner"), encoding: .utf8)) == "StemSeparatorJob-v1" else { continue }
            let fd = open(child.appendingPathComponent(".lock").path, O_RDWR | O_NOFOLLOW)
            guard fd >= 0 else { continue }
            defer { close(fd) }
            guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { continue }
            defer { flock(fd, LOCK_UN) }
            if let data = try? Data(contentsOf: child.appendingPathComponent("staging.json")),
               let record = try? JSONDecoder().decode(StagingRecord.self, from: data),
               record.owner == child.lastPathComponent,
               record.name.hasPrefix(".stem-separator-"),
               UUID(uuidString: String(record.name.dropFirst(".stem-separator-".count))) != nil {
                var stale = false
                if let parent = try? URL(resolvingBookmarkData: record.bookmark, options: [.withSecurityScope, .withoutUI], relativeTo: nil, bookmarkDataIsStale: &stale), !stale {
                    let scope = parent.startAccessingSecurityScopedResource()
                    defer { if scope { parent.stopAccessingSecurityScopedResource() } }
                    let stage = parent.appendingPathComponent(record.name)
                    let info = try? stage.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey])
                    if info?.isDirectory == true, info?.isSymbolicLink != true,
                       (try? String(contentsOf: stage.appendingPathComponent(".stem-separator-owner"), encoding: .utf8)) == record.owner {
                        try? fm.removeItem(at: stage)
                    }
                }
            }
            try? fm.removeItem(at: child)
        }
    }
    private struct StagingRecord: Codable { let bookmark: Data; let name: String; let owner: String }
}
