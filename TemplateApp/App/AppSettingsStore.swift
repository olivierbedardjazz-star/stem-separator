import Combine
import Foundation

@MainActor
final class AppSettingsStore: ObservableObject {
    static let currentResponsibleUseVersion = 1

    @Published private(set) var acceptedResponsibleUseVersion: Int

    private let defaults: UserDefaults

    private enum Keys {
        static let responsibleUseVersion = "stem-separator.v1.responsible-use-version"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.acceptedResponsibleUseVersion = defaults.integer(forKey: Keys.responsibleUseVersion)
    }

    var hasAcceptedResponsibleUse: Bool {
        acceptedResponsibleUseVersion >= Self.currentResponsibleUseVersion
    }

    func acceptResponsibleUse() {
        acceptedResponsibleUseVersion = Self.currentResponsibleUseVersion
        defaults.set(acceptedResponsibleUseVersion, forKey: Keys.responsibleUseVersion)
    }

    func diagnosticSnapshot() -> [String: String] {
        [
            Keys.responsibleUseVersion: String(acceptedResponsibleUseVersion)
        ]
    }
}
