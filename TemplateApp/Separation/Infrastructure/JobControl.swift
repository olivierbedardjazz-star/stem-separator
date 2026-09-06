import Foundation
import Darwin

/// All mutable state is protected by lock; cancellation never waits on the main thread.
final class JobControl: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    private var process: Process?
    func check() throws {
        lock.lock(); let value = cancelled; lock.unlock()
        if value { throw SeparationFailure.cancelled }
    }
    var isCancelled: Bool { lock.lock(); defer { lock.unlock() }; return cancelled }
    func attach(_ process: Process) throws {
        lock.lock(); defer { lock.unlock() }
        if cancelled { throw SeparationFailure.cancelled }
        self.process = process
    }
    func detach() { lock.lock(); process = nil; lock.unlock() }
    func cancel() {
        lock.lock(); cancelled = true; lock.unlock()
        stopWorker()
    }
    func stopWorker() {
        lock.lock()
        if let process, process.isRunning { process.terminate() }
        lock.unlock()
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) { [self] in
            lock.lock(); defer { lock.unlock() }
            if let process, process.isRunning { kill(process.processIdentifier, SIGKILL) }
        }
    }
}
