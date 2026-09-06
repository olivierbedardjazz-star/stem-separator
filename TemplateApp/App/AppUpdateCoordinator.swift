import AppKit
import Combine
import Foundation
import Sparkle

@MainActor
protocol AppUpdateCoordinating {
    var canCheckForUpdates: Bool { get }
    var stateDidChange: AnyPublisher<Void, Never> { get }

    func checkForUpdates()
}

@MainActor
struct AppUpdateConfiguration {
    enum ReadinessIssue: Equatable {
        case missingFeedURL
        case placeholderFeedURL
        case invalidFeedURL
        case unsupportedFeedURL
        case missingPublicKey
        case placeholderPublicKey
        case invalidPublicKey

        var recoverySuggestion: String {
            switch self {
            case .missingFeedURL:
                return "Add a real GitHub Releases appcast URL to TEMPLATE_APP_SPARKLE_APPCAST_URL in project.yml."
            case .placeholderFeedURL:
                return "Replace the placeholder GitHub repository tokens in TEMPLATE_APP_SPARKLE_APPCAST_URL."
            case .invalidFeedURL:
                return "Use a valid HTTPS URL for the Sparkle appcast feed."
            case .unsupportedFeedURL:
                return "Point the updater at a GitHub Releases appcast URL ending in appcast.xml."
            case .missingPublicKey:
                return "Set TEMPLATE_APP_SPARKLE_PUBLIC_ED_KEY in project.yml to the real Sparkle public ED key."
            case .placeholderPublicKey:
                return "Replace the placeholder Sparkle public key token in project.yml."
            case .invalidPublicKey:
                return "Set a valid 32-byte base64 Ed25519 public key in project.yml."
            }
        }
    }

    let feedURL: URL?
    let publicEDKey: String?
    let readinessIssue: ReadinessIssue?

    var isReadyForUpdates: Bool {
        readinessIssue == nil
    }

    var developerGuidance: String {
        if let readinessIssue {
            return """
            \(readinessIssue.recoverySuggestion)
            The template keeps the Help menu updater surface on purpose, but it is not release-armed until those placeholder values are replaced.
            After updating project.yml, run xcodegen generate and rebuild the app so Info.plist picks up the new values.
            """
        }

        return "Sparkle is armed with a non-placeholder GitHub Releases appcast URL and public ED key."
    }

    init(feedURLString: String?, publicEDKey: String?) {
        let normalizedFeedURLString = feedURLString?.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedPublicEDKey = publicEDKey?.trimmingCharacters(in: .whitespacesAndNewlines)
        let feedURL = normalizedFeedURLString.flatMap(URL.init(string:))

        self.feedURL = feedURL
        self.publicEDKey = normalizedPublicEDKey
        self.readinessIssue = Self.resolveReadinessIssue(
            feedURLString: normalizedFeedURLString,
            feedURL: feedURL,
            publicEDKey: normalizedPublicEDKey
        )
    }

    init(bundle: Bundle = .main) {
        let feedURLString = bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String
        let publicEDKey = (bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        self.init(feedURLString: feedURLString, publicEDKey: publicEDKey)
    }

    private static func resolveReadinessIssue(
        feedURLString: String?,
        feedURL: URL?,
        publicEDKey: String?
    ) -> ReadinessIssue? {
        guard let feedURLString, !feedURLString.isEmpty else {
            return .missingFeedURL
        }

        if containsPlaceholderToken(feedURLString) {
            return .placeholderFeedURL
        }

        guard let feedURL else {
            return .invalidFeedURL
        }

        guard feedURL.scheme != nil, feedURL.host != nil else {
            return .invalidFeedURL
        }

        guard isSupportedGitHubAppcastURL(feedURL) else {
            return .unsupportedFeedURL
        }

        guard let publicEDKey, !publicEDKey.isEmpty else {
            return .missingPublicKey
        }

        if containsPlaceholderToken(publicEDKey) {
            return .placeholderPublicKey
        }

        guard Data(base64Encoded: publicEDKey)?.count == 32 else {
            return .invalidPublicKey
        }

        return nil
    }

    private static func containsPlaceholderToken(_ value: String) -> Bool {
        value.contains("SET_GITHUB_OWNER")
            || value.contains("SET_GITHUB_REPOSITORY")
            || value.contains("SET_SPARKLE_PUBLIC_KEY")
    }

    private static func isSupportedGitHubAppcastURL(_ feedURL: URL) -> Bool {
        guard feedURL.scheme?.lowercased() == "https" else {
            return false
        }

        guard feedURL.host?.lowercased() == "github.com" else {
            return false
        }

        guard feedURL.user == nil, feedURL.password == nil, feedURL.port == nil,
              feedURL.query == nil, feedURL.fragment == nil else { return false }

        let pathComponents = feedURL.path.split(separator: "/")
        guard pathComponents.count == 6 else {
            return false
        }

        guard pathComponents[2] == "releases" else {
            return false
        }

        return pathComponents[3] == "latest" && pathComponents[4] == "download"
            && pathComponents.last == "appcast.xml"
    }
}

@MainActor
final class AppUpdateCoordinator: NSObject, AppUpdateCoordinating, SPUUpdaterDelegate {
    var stateDidChange: AnyPublisher<Void, Never> { stateDidChangeSubject.eraseToAnyPublisher() }
    @Published private(set) var sessionBusy = false
    var isSeparationBusy: () -> Bool = { false }
    private let configuration = AppUpdateConfiguration()
    private let stateDidChangeSubject = PassthroughSubject<Void, Never>()
    private var updaterController: SPUStandardUpdaterController!
    private var observations: [NSKeyValueObservation] = []
    var canCheckForUpdates: Bool { !configuration.isReadyForUpdates || updaterController.updater.canCheckForUpdates }
    override init() {
        super.init()
        updaterController = SPUStandardUpdaterController(startingUpdater: configuration.isReadyForUpdates, updaterDelegate: self, userDriverDelegate: nil)
        observations = [
            updaterController.updater.observe(\.canCheckForUpdates, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.stateDidChangeSubject.send(()) }
            },
            updaterController.updater.observe(\.sessionInProgress, options: [.initial, .new]) { [weak self] _, _ in
                Task { @MainActor in
                    guard let self else { return }
                    self.sessionBusy = self.updaterController.updater.sessionInProgress
                    self.stateDidChangeSubject.send(())
                }
            }
        ]
    }
    func updater(_ updater: SPUUpdater, mayPerform updateCheck: SPUUpdateCheck) throws {
        if isSeparationBusy() {
            throw NSError(domain: "StemSeparator.Update", code: 1, userInfo: [NSLocalizedDescriptionKey: "Finish or cancel separation before updating."])
        }
    }
    func checkForUpdates() {
        guard !isSeparationBusy() else { return }
        guard configuration.isReadyForUpdates else {
            let alert = NSAlert()
            alert.messageText = "Updates will be available in the public release."
            alert.informativeText = "This local evaluation build includes the update system. Its release feed and signing key have not been configured yet."
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        updaterController.checkForUpdates(nil)
    }
}
