import Foundation
import OSLog

struct SeparationSession: Sendable {
    let worker: StemWorkerProcess
    func run(selection: AudioSelection, destination: URL, jobID: UUID, control: JobControl,
             progress: @escaping @Sendable (SeparationStage, Double?) -> Void) throws -> URL {
        let log = Logger(subsystem: "com.oliviergrenierbedard.stemseparator", category: "separation")
        let start = Date()
        log.info("Job started")
        var phase = "creating temporary workspace"
        do {
            let lease = try JobWorkspace(id: jobID)
            let workspace = lease.url
            defer { withExtendedLifetime(lease) {} }
            let scope = destination.startAccessingSecurityScopedResource()
            defer { if scope { destination.stopAccessingSecurityScopedResource() } }
            phase = "checking output folder"
            let values = try destination.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey, .isDirectoryKey])
            guard values.isDirectory == true else { throw SeparationFailure(message: "Choose an output folder before separating.") }
            let required = Int64(selection.duration * 44100 * 64) + 512 * 1024 * 1024
            if let available = values.volumeAvailableCapacityForImportantUsage, available < required {
                throw SeparationFailure(message: "There is not enough free space in the output location. Free some space or choose another disk.")
            }
            let probe = destination.appendingPathComponent(".stem-separator-probe-" + jobID.uuidString)
            do {
                try FileManager.default.createDirectory(at: probe, withIntermediateDirectories: false)
                try FileManager.default.removeItem(at: probe)
            } catch {
                throw SeparationFailure(message: "The output folder is not writable. Choose another folder before separating.")
            }
            progress(.preparing, nil)
            phase = "preparing audio"
            let input = try AudioPreparationService.prepare(selection, directory: workspace, control: control)
            phase = "running separation engine"
            let stems = try worker.run(input: input, jobID: jobID, directory: workspace, control: control, progress: progress)
            progress(.writing, nil)
            phase = "saving stems"
            let result = try StemOutputWriter.commit(stems: stems, input: input, workspace: workspace,
                                                    destination: destination, baseName: selection.url.deletingPathExtension().lastPathComponent, control: control)
            log.info("Job completed in \(Int(Date().timeIntervalSince(start)), privacy: .public) seconds")
            return result
        } catch {
            let native = error as NSError
            // Never record localizedDescription or userInfo: both may contain audio paths.
            let domain = [NSCocoaErrorDomain, NSPOSIXErrorDomain, NSOSStatusErrorDomain].contains(native.domain) ? native.domain : "ApplicationError"
            log.error("Job failed while \(phase, privacy: .public); domain=\(domain, privacy: .public); code=\(native.code, privacy: .public)")
            if let failure = error as? SeparationFailure { throw failure }
            throw SeparationFailure(message: "Could not finish \(phase). Check that the audio and output folder are available and there is enough free space. (\(domain) \(native.code))")
        }
    }
}
