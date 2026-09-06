import AppKit
import SwiftUI

@main
struct TemplateAppApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        Window("Stem Separator", id: "main") {
            Group {
                if environment.settingsStore.hasAcceptedResponsibleUse {
                    RootView(
                        shellState: environment.shellState,
                        commandDispatcher: environment.commandDispatcher
                    )
                } else {
                    ResponsibleUseGateView(settingsStore: environment.settingsStore)
                }
            }
            .frame(
                minWidth: AppWindowMetrics.minimumWindowWidth,
                minHeight: AppWindowMetrics.minimumWindowHeight
            )
        }
        .defaultSize(
            width: AppWindowMetrics.defaultWindowWidth,
            height: AppWindowMetrics.defaultWindowHeight
        )
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        .commands {
            AppMenuCommands(commandDispatcher: environment.commandDispatcher)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hasAppliedInitialWindowFrame = false
    private var menuObservers: [NSObjectProtocol] = []

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        AppLifecycleCoordinator.requestTermination()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        // SwiftUI can reconstruct commands after sheets and observable state updates.
        // Clean after those mutations as well as at launch/activation.
        menuObservers = [NSMenu.didAddItemNotification, NSMenu.didChangeItemNotification].map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.cleanMenus() }
            }
        }
        cleanMenus()
        applyInitialWindowFrameIfNeeded()
        scheduleMenuCleanupPasses()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        cleanMenus()
        applyInitialWindowFrameIfNeeded()
        scheduleMenuCleanupPasses()
    }

    func applicationDidUpdate(_ notification: Notification) {
        cleanMenus()
    }

    private func cleanMenus() {
        guard let mainMenu = NSApp.mainMenu else {
            return
        }

        rebuildApplicationMenu(using: mainMenu)
        if NSApp.windowsMenu != nil { NSApp.windowsMenu = nil }

        for title in ["Window", "View"] {
            if let item = mainMenu.items.first(where: { $0.title == title }) {
                mainMenu.removeItem(item)
            }
        }

        if
            let editItem = mainMenu.items.first(where: { $0.title == "Edit" }),
            let editMenu = editItem.submenu,
            let selectAllItem = editMenu.items.first(where: { $0.title == "Select All" })
        {
            editMenu.removeItem(selectAllItem)
        }
    }

    private func rebuildApplicationMenu(using mainMenu: NSMenu) {
        guard let appMenuItem = mainMenu.items.first else {
            return
        }

        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Stem Separator"

        // Keep the exact minimal menu, but do not replace a correct menu during
        // each native event. Rebuilding while typing can swallow picker keystrokes.
        if let current = appMenuItem.submenu, current.items.count == 3,
           current.items[0].title == "About \(appName)", current.items[1].isSeparatorItem,
           current.items[2].title == "Quit \(appName)" { return }

        let appMenu = NSMenu(title: appName)

        let aboutItem = NSMenuItem(
            title: "About \(appName)",
            action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
            keyEquivalent: ""
        )
        aboutItem.target = NSApp
        appMenu.addItem(aboutItem)

        appMenu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit \(appName)",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = NSApp
        appMenu.addItem(quitItem)

        appMenuItem.submenu = appMenu
    }

    private func applyInitialWindowFrameIfNeeded() {
        guard !hasAppliedInitialWindowFrame else {
            return
        }

        guard let window = NSApp.windows.first(where: { $0.canBecomeMain }) else {
            DispatchQueue.main.async { [weak self] in
                self?.applyInitialWindowFrameIfNeeded()
            }
            return
        }

        hasAppliedInitialWindowFrame = true

        let targetContentSize = NSSize(
            width: AppWindowMetrics.defaultWindowWidth,
            height: AppWindowMetrics.defaultWindowHeight
        )

        window.setContentSize(targetContentSize)
        window.minSize = NSSize(
            width: AppWindowMetrics.minimumWindowWidth,
            height: AppWindowMetrics.minimumWindowHeight
        )
        window.center()
    }

    private func scheduleMenuCleanupPasses() {
        let delays: [TimeInterval] = [0, 0.05, 0.15]

        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.cleanMenus()
            }
        }
    }
}

struct AppMenuCommands: Commands {
    @ObservedObject var commandDispatcher: AppCommandDispatcher

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open Audio…") { commandDispatcher.chooseAudio() }
                .keyboardShortcut("o").disabled(!commandDispatcher.canSelect)
            Divider()
            Button("Separate Stems") {
                commandDispatcher.performPrimaryAction()
            }
            .keyboardShortcut(.return, modifiers: .command)
            .disabled(!commandDispatcher.canPerformPrimaryAction)
            Button("Cancel Separation") { commandDispatcher.cancel() }
                .keyboardShortcut(".").disabled(!commandDispatcher.canCancel)
        }

        CommandGroup(replacing: .help) {
            Button("Check for Updates...") {
                commandDispatcher.checkForUpdates()
            }
            .disabled(!commandDispatcher.canCheckForUpdates)
            Button("Third-Party Notices") { commandDispatcher.showNotices() }
        }

        CommandGroup(replacing: .toolbar) {}
        CommandGroup(replacing: .sidebar) {}

        CommandGroup(replacing: .windowSize) {}
        CommandGroup(replacing: .windowArrangement) {}
        CommandGroup(replacing: .windowList) {}

        CommandGroup(replacing: .singleWindowList) {}

        CommandGroup(replacing: .textEditing) {}
    }
}
