import XCTest

@MainActor
class LumenAppStoreScreenshots: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-UITesting")
        setupSnapshot(app)
        app.launch()
    }

    func testTakeScreenshots() throws {
        // Wait for feed to load
        let feedLoaded = app.staticTexts.firstMatch.waitForExistence(timeout: 5.0)
        XCTAssertTrue(feedLoaded)
        
        // 1. Home Feed
        snapshot("01_HomeFeed")
        
        // 2. Open Explore Categories
        app.tabBars.buttons["Explore"].tap()
        let exploreLoaded = app.staticTexts["Categories"].waitForExistence(timeout: 2.0)
        snapshot("02_Explore")
        
        // 3. Open Affirmations Theme Generator
        app.tabBars.buttons["Settings"].tap()
        let settingsLoaded = app.staticTexts["Appearance"].waitForExistence(timeout: 2.0)
        app.buttons["Themes & Backgrounds"].tap()
        let themesLoaded = app.navigationBars.staticTexts["Themes & Backgrounds"].waitForExistence(timeout: 2.0)
        snapshot("03_Themes")
        
        // 4. Return to Home Feed and Open Paywall (from Settings)
        app.navigationBars.buttons.firstMatch.tap() // Back out of Themes
        app.buttons["paywall_subscription_button"].tap()
        let paywallLoaded = app.staticTexts["Unlock Lumen Premium"].waitForExistence(timeout: 2.0)
        snapshot("04_PremiumPaywall")
    }
}
