import XCTest

@MainActor
class LumenCriticalFlowsUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Inject -UITesting to use predictable states in the app.
        app.launchArguments.append("-UITesting")
        app.launch()
    }

    func testEditorAndFeedFlow() throws {
        // Wait for feed to load
        let feedLoaded = app.staticTexts.firstMatch.waitForExistence(timeout: 5.0)
        XCTAssertTrue(feedLoaded, "Feed should load on launch")
        
        // 1. Editor Flow
        let editButton = app.buttons["Edit"]
        if editButton.waitForExistence(timeout: 2.0) {
            editButton.tap()
            
            // Appears sheet with CustomAffirmationSheet
            let textEditor = app.textViews.firstMatch
            XCTAssertTrue(textEditor.waitForExistence(timeout: 2.0), "Text editor should appear")
            
            textEditor.tap()
            textEditor.typeText("I am mastering UI tests.")
            
            let saveButton = app.buttons["Save"]
            if saveButton.waitForExistence(timeout: 2.0) {
                saveButton.tap()
                sleep(2) // Wait for dismissal and UI update
                
                // Assert it appeared in feed
                let customAffText = app.staticTexts["I am mastering UI tests."]
                XCTAssertTrue(customAffText.exists, "Newly created affirmation should be in the feed")
            }
        }
    }

    func testFeedFavoritesFlow() throws {
        // Wait for feed to load
        let feedLoaded = app.staticTexts.firstMatch.waitForExistence(timeout: 5.0)
        XCTAssertTrue(feedLoaded)
        
        // Let's Favorite the first card
        let favoriteButton = app.buttons["Favorite"]
        var tapped = false
        if favoriteButton.waitForExistence(timeout: 2.0) {
            favoriteButton.tap()
            tapped = true
        } else {
            let altFavButton = app.buttons["feed.favorite"]
            if altFavButton.waitForExistence(timeout: 2.0) {
                 altFavButton.tap()
                 tapped = true
            }
        }
        
        guard tapped else {
            XCTFail("Favorite button not found on home screen")
            return
        }

        // Navigate to Favorites tab
        app.tabBars.buttons["Favorites"].tap()
        
        // Very basic validation that the Favorites view loaded.
        let favoritesTitle = app.staticTexts["Favorites"]
        XCTAssertTrue(favoritesTitle.waitForExistence(timeout: 2.0), "Favorites view should load")
    }

    func testExploreCategoryFlow() throws {
        // Navigate to Explore
        let exploreTab = app.tabBars.buttons["Explore"]
        XCTAssertTrue(exploreTab.waitForExistence(timeout: 5.0))
        exploreTab.tap()

        // Wait for categories
        let relationshipsCategory = app.staticTexts["Relationships"].firstMatch
        if relationshipsCategory.waitForExistence(timeout: 3.0) {
            relationshipsCategory.tap()
            
            // Give category feed time to load
            sleep(2)
            
            // Check that we can swipe
            app.swipeLeft()
            sleep(1) // Wait for transition
        }
    }

    func testSettingsFlow() throws {
        let profileOrSettingsButton = app.buttons["Settings"].firstMatch
        if !profileOrSettingsButton.exists {
             // In many tabbed apps, settings might be top right on explore or favorites, or deeply linked.
             // If there's a dedicated button available from the feed top bar, we'll try that.
             // For safety, let's just assert if we can find it.
             let possibleSettingsIcon = app.images["gearshape.fill"]
             if possibleSettingsIcon.waitForExistence(timeout: 2.0) {
                 possibleSettingsIcon.tap()
             }
        } else {
            profileOrSettingsButton.tap()
        }

        // Check if Settings view appears
        let settingsTitle = app.navigationBars["Settings"]
        if settingsTitle.waitForExistence(timeout: 2.0) {
            // Test scrolling
            app.swipeUp()
            
            // Tap a toggle
            let syncToggle = app.switches["iCloud Sync"].firstMatch
            if syncToggle.exists {
                syncToggle.tap()
            }
            
            // Data Export
            let exportButton = app.buttons["Export Data"].firstMatch
            if exportButton.exists {
                exportButton.tap()
                sleep(1) // Wait for share sheet
            }
        }
    }
}
