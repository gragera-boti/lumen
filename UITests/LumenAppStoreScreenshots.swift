import XCTest

@MainActor
class LumenAppStoreScreenshots: XCTestCase {
    private nonisolated(unsafe) var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        await MainActor.run {
            let localApp = XCUIApplication()
            localApp.launchArguments.append("-UITesting")
            setupSnapshot(localApp)
            localApp.launch()
            self.app = localApp
        }
    }

    func testTakeScreenshots() throws {
        // Wait for feed to load and menu bar to settle
        let feedLoaded = app.staticTexts.firstMatch.waitForExistence(timeout: 5.0)
        XCTAssertTrue(feedLoaded)
        sleep(4) // Wait for top bar animations to fully complete
        
        // 1. Home Feed (Affirmation with AI Background)
        // Swipe to get a different card to ensure it's fully loaded and shows an AI background
        app.swipeLeft()
        sleep(5) // Wait for crossfade transition and UI settling
        snapshot("01_AffirmationAiBackground")
        
        // Swipe again so the editor shows a different affirmation
        app.swipeLeft()
        sleep(3) // Wait for swipe transition
        
        // 2. Affirmation Editor
        app.buttons["Edit"].tap()
        sleep(3) // Wait for sheet to present
        
        // Tap AI tab
        let aiTab = app.buttons["AI ✨"]
        if aiTab.waitForExistence(timeout: 2.0) {
            aiTab.tap()
            sleep(1)
            
            let generateBtn = app.buttons["Generate AI background"]
            if generateBtn.waitForExistence(timeout: 2.0) {
                generateBtn.tap()
                sleep(4) // Wait for the fake mock API cycle to complete and UI to settle
            }
        }
        
        snapshot("02_Editor")
        
        // Dismiss the editor sheet using the Cancel button
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
        } else {
            app.windows.firstMatch.swipeDown(velocity: .fast)
        }
        
        // Wait extremely long for the sheet to dismiss entirely
        sleep(5)
        
        // Let's directly try tapping the button with the Favorite localized text
        let favoriteButton = app.buttons["Favorite"]
        if favoriteButton.waitForExistence(timeout: 5.0) {
            favoriteButton.tap()
        } else {
            let altFavButton = app.buttons["feed.favorite"]
            if altFavButton.waitForExistence(timeout: 2.0) {
                 altFavButton.tap()
            } else {
                 app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.85)).tap()
            }
        }
        
        // Wait for the favorite to register
        sleep(3)
        
        // 4. Explore
        app.tabBars.buttons["Explore"].tap()
        sleep(2) // Wait for explore content to load
        snapshot("04_Explore")
    }
}
