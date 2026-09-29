import AppKit
import Combine

@MainActor
final class AppCommandDispatcher: ObservableObject {
    let shellState: SeparationStore
    #if !APP_STORE
    private let updateCoordinator: AppUpdateCoordinator
    #endif
    private var cancellables: Set<AnyCancellable> = []
    #if APP_STORE
    init(shellState: SeparationStore) {
        self.shellState = shellState
        shellState.objectWillChange.sink { [weak self] in self?.objectWillChange.send() }.store(in: &cancellables)
    }
    #else
    init(shellState: SeparationStore, updateCoordinator: AppUpdateCoordinator = AppUpdateCoordinator()) {
        self.shellState = shellState
        self.updateCoordinator = updateCoordinator
        updateCoordinator.isSeparationBusy = { [weak shellState] in shellState?.isBusy == true || shellState?.isChoosingDestination == true }
        shellState.objectWillChange.merge(with: updateCoordinator.stateDidChange)
            .sink { [weak self] in self?.objectWillChange.send() }.store(in: &cancellables)
        updateCoordinator.$sessionBusy.sink { [weak shellState] busy in shellState?.updaterBusy = busy }.store(in: &cancellables)
    }
    #endif
    func handleAppLaunch() {}
    var canPerformPrimaryAction: Bool { shellState.canStart }
    func performPrimaryAction() { shellState.start() }
    func chooseAudio() { shellState.chooseAudio() }
    func cancel() { shellState.cancel() }
    var canSelect: Bool { shellState.canSelect }
    var canCancel: Bool { shellState.isBusy && shellState.stage != .cancelling }
    #if !APP_STORE
    func checkForUpdates() { guard canCheckForUpdates else { return }; updateCoordinator.checkForUpdates() }
    var canCheckForUpdates: Bool { !shellState.isBusy && !shellState.isChoosingDestination && updateCoordinator.canCheckForUpdates }
    #endif
    func showAboutPanel() { NSApp.orderFrontStandardAboutPanel(nil) }
    func showNotices() {
        if let url = Bundle.main.url(forResource: "THIRD_PARTY_NOTICES", withExtension: "md") { NSWorkspace.shared.open(url) }
    }
}
