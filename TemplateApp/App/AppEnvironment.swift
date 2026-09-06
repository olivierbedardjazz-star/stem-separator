import Combine
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    let settingsStore: AppSettingsStore
    let shellState: TemplateShellState
    let commandDispatcher: AppCommandDispatcher

    private var cancellables: Set<AnyCancellable> = []

    init(
        settingsStore: AppSettingsStore = AppSettingsStore(),
        commandDispatcher: AppCommandDispatcher? = nil
    ) {
        self.settingsStore = settingsStore
        self.shellState = TemplateShellState()
        self.commandDispatcher = commandDispatcher ?? AppCommandDispatcher(
            shellState: self.shellState
        )
        self.shellState.isAuthorized = settingsStore.hasAcceptedResponsibleUse
        AppLifecycleCoordinator.store = self.shellState
        bindSettingsState()
        self.commandDispatcher.handleAppLaunch()
        Task.detached(priority: .utility) { JobWorkspace.recover() }
    }

    private func bindSettingsState() {
        settingsStore.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.shellState.isAuthorized = self.settingsStore.hasAcceptedResponsibleUse
                }
            }
            .store(in: &cancellables)
    }
}
