import XCTest

/// Layout proof: every main screen, the paywall and first run, shot at the default text size and at an
/// accessibility size, in portrait and (on an iPad) in landscape. Each frame is attached to the result.
/// XCTest rotates the device, which nothing else can do headless; a landscape attachment comes back turned
/// 90 degrees clockwise. Run on an iPad and on an iPhone:
/// `gh-sim test --device "iPad Pro 13-inch (M5)" --only RavelUITests/ScreenCaptureUITests`.
@MainActor
final class ScreenCaptureUITests: XCTestCase {
    private struct Scene {
        var name: String
        var arguments: [String]
        var action: ((XCUIApplication) -> Void)?
    }

    private var scenes: [Scene] {
        [
            Scene(name: "first-run", arguments: ["-UITesting"]),
            Scene(name: "projects", arguments: ["-SeedDemo"]),
            Scene(name: "counter", arguments: ["-SeedDemo", "-NoPattern", "-OpenProject", "Raglan Sweater"]),
            Scene(name: "pdf", arguments: ["-SeedDemo", "-OpenProject", "Raglan Sweater"]),
            Scene(name: "guided", arguments: ["-SeedDemo", "-OpenProject", "Ribbed Beanie"]),
            Scene(name: "details", arguments: ["-SeedDemo", "-OpenProject", "Raglan Sweater", "-OpenDetails"]),
            Scene(name: "library", arguments: ["-SeedDemo", "-Tab", "1"]),
            Scene(name: "design", arguments: ["-SeedDemo", "-Tab", "1", "-OpenDesign", "raglanPullover"]),
            Scene(name: "paywall-sheet", arguments: ["-SeedDemo", "-MockProducts", "-Tab", "1", "-OpenDesign", "ribbedBeanie"]) { app in
                let unlock = app.buttons["design.castOn"]
                if unlock.waitForExistence(timeout: 10) { unlock.tap() }
                _ = app.buttons["paywall.yearly"].waitForExistence(timeout: 10)
            },
            Scene(name: "paywall", arguments: ["-SeedDemo", "-MockProducts", "-PaywallSnapshot", "yearly"]),
            Scene(name: "stash", arguments: ["-SeedDemo", "-Tab", "2"]),
            Scene(name: "yarn", arguments: ["-SeedDemo", "-Tab", "2", "-OpenYarn"]),
        ]
    }

    private static let accessibilitySize = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]

    override func setUp() {
        continueAfterFailure = true
    }

    func testPortrait() { shoot(landscape: false, large: false) }
    func testPortraitAccessibility() { shoot(landscape: false, large: true) }

    func testLandscape() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("iPhone stays portrait") }
        shoot(landscape: true, large: false)
    }

    func testLandscapeAccessibility() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else { throw XCTSkip("iPhone stays portrait") }
        shoot(landscape: true, large: true)
    }

    private func shoot(landscape: Bool, large: Bool) {
        let orientation: UIDeviceOrientation = landscape ? .landscapeLeft : .portrait
        let device = UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
        for scene in scenes {
            XCUIDevice.shared.orientation = orientation
            let app = XCUIApplication()
            app.launchArguments = scene.arguments + (large ? Self.accessibilitySize : [])
            app.launch()
            sleep(3)
            scene.action?(app)
            // Rotation can land after launch; settle before the frame is taken.
            XCUIDevice.shared.orientation = orientation
            sleep(2)
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = [device, scene.name, landscape ? "landscape" : "portrait", large ? "ax" : "default"].joined(separator: "-")
            shot.lifetime = .keepAlways
            add(shot)
            app.terminate()
        }
        XCUIDevice.shared.orientation = .portrait
    }
}
