import XCTest
import AppKit

@MainActor
final class StemSeparatorUITests: XCTestCase {
    func testNativeWorkflowMenusAndLegalSurface() throws {
        continueAfterFailure = false
        let clipboard = NSPasteboard.general
        let original: [NSPasteboardItem] = clipboard.pasteboardItems?.map { item in
            let copy = NSPasteboardItem()
            for type in item.types { if let data = item.data(forType: type) { copy.setData(data, forType: type) } }
            return copy
        } ?? []
        var clipboardChange = clipboard.changeCount
        defer {
            if clipboard.changeCount == clipboardChange {
                clipboard.clearContents(); clipboard.writeObjects(original.map { $0 as NSPasteboardWriting })
            }
        }
        func pastePath(_ path: String, into app: XCUIApplication) {
            clipboard.clearContents(); clipboard.setString(path, forType: .string)
            clipboardChange = clipboard.changeCount
            app.typeKey("a", modifierFlags: .command)
            app.typeKey("v", modifierFlags: .command)
        }
        let app: XCUIApplication
        if let installedPath = ProcessInfo.processInfo.environment["STEM_TEST_APP"] {
            app = XCUIApplication(url: URL(fileURLWithPath: installedPath))
        } else {
            app = XCUIApplication()
        }
        app.launch()
        let accept = app.buttons["I Accept"]
        if accept.waitForExistence(timeout: 3) { accept.click() }
        XCTAssertTrue(app.buttons["Choose Audio"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Separate Stems"].isEnabled)
        XCTAssertFalse(app.menuBars.menuBarItems["Window"].exists)
        XCTAssertFalse(app.menuBars.menuBarItems["View"].exists)
        app.buttons["Terms"].click()
        XCTAssertTrue(app.staticTexts["Terms of Use"].waitForExistence(timeout: 3))
        app.buttons["Close"].click()
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        app.buttons["Choose Audio"].click()
        app.typeKey("g", modifierFlags: [.command, .shift])
        pastePath(root.appendingPathComponent("Tests/Fixtures/generated-tone.mp3").path, into: app)
        Thread.sleep(forTimeInterval: 1)
        app.typeKey(.return, modifierFlags: [])
        app.descendants(matching: .any).matching(identifier: "open-panel").firstMatch.buttons["OKButton"].click()
        XCTAssertTrue(app.buttons["Replace Audio"].waitForExistence(timeout: 5))
        let separate = app.buttons["Separate Stems"]
        XCTAssertTrue(separate.isEnabled)
        XCTAssertFalse(app.buttons["Choose Folder"].exists)
        separate.click()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "open-panel").firstMatch.waitForExistence(timeout: 3))
        app.descendants(matching: .any).matching(identifier: "open-panel").firstMatch.buttons["Cancel"].click()
        XCTAssertTrue(separate.isEnabled)
        XCTAssertFalse(app.buttons["Show in Finder"].exists)
        let ready = XCTAttachment(screenshot: app.windows.firstMatch.screenshot()); ready.name = "Ready branded workflow"; ready.lifetime = .keepAlways; add(ready)
        separate.click()
        app.typeKey("g", modifierFlags: [.command, .shift])
        pastePath(root.appendingPathComponent("build/UITestOutput").path, into: app)
        Thread.sleep(forTimeInterval: 1)
        app.typeKey(.return, modifierFlags: [])
        app.descendants(matching: .any).matching(identifier: "open-panel").firstMatch.buttons["OKButton"].click()
        XCTAssertTrue(app.buttons["Show in Finder"].waitForExistence(timeout: 60))
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertFalse(app.menuBars.menuBarItems["Window"].exists)
        XCTAssertFalse(app.menuBars.menuBarItems["View"].exists)
        let done = XCTAttachment(screenshot: app.windows.firstMatch.screenshot()); done.name = "Completed branded workflow"; done.lifetime = .keepAlways; add(done)
        app.terminate()
    }
}
