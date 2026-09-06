import AppKit

@MainActor
enum AppLifecycleCoordinator {
    static weak var store: SeparationStore?
    static func requestTermination() -> NSApplication.TerminateReply {
        guard let store, store.isBusy else { return .terminateNow }
        let alert = NSAlert()
        alert.messageText = "Cancel separation and quit?"
        alert.informativeText = "The current job will stop. Your original audio and previously completed stems will be kept."
        alert.addButton(withTitle: "Keep Separating")
        alert.addButton(withTitle: "Cancel and Quit")
        guard alert.runModal() == .alertSecondButtonReturn else { return .terminateCancel }
        store.cancel()
        Task { @MainActor in
            while store.isBusy { try? await Task.sleep(for: .milliseconds(100)) }
            NSApp.reply(toApplicationShouldTerminate: true)
        }
        return .terminateLater
    }
}
