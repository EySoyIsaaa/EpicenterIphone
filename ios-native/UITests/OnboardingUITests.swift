import XCTest

final class OnboardingUITests: XCTestCase {
    func testEntireRedButtonAdvancesAndClosesTutorial() {
        let app = XCUIApplication()
        app.launchArguments = ["-hasOnboarded", "NO"]
        app.launch()
        let button = app.buttons["onboarding-primary"]
        XCTAssertTrue(button.waitForExistence(timeout: 15))
        // Tap the red area far from the text: previously only the text was hit-testable.
        for _ in 0..<3 {
            XCTAssertTrue(button.isHittable)
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.5)).tap()
        }
        let epicenterTab = app.tabBars.buttons["Epicenter"]
        let entered = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: epicenterTab)
        XCTAssertEqual(XCTWaiter.wait(for: [entered], timeout: 8), .completed)
        XCTAssertFalse(button.exists)
    }
}
