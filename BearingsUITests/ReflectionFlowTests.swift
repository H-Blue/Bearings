import XCTest

/// Every journal sentence and AI response here is synthetic. The injected local
/// provider makes these flows independent of Apple Intelligence hardware.
final class ReflectionFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        launch(reset: true, provider: "--ai-fixture")
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    func testUnavailableAIKeepsWritingAndManualFeelingAvailable() throws {
        app.terminate()
        launch(reset: true, provider: "--ai-unavailable")
        openToday()
        createEntry("A synthetic memory of a quiet walk by the river.")
        reveal(app.staticTexts["reflection.daily.unavailable"])
        XCTAssertTrue(app.staticTexts["reflection.daily.unavailable"].label.contains("unavailable"))
        chooseFeeling("Love")
        attachScreenshot("Manual day feeling while on-device AI is unavailable")
        app.buttons["day.back"].tap()
        let day = try todayButton()
        XCTAssertTrue(waitFor(day).label.contains("Love"))
        attachScreenshot("Timeline with persisted manual emotion indicator")

        app.terminate()
        launch(reset: false, provider: "--ai-unavailable")
        XCTAssertTrue(waitFor(day).label.contains("Love"), "A manual feeling must persist even without AI.")
        openToday()
        XCTAssertTrue(entryButton().exists, "AI unavailability must preserve the original writing.")
        reveal(app.buttons["reflection.weekly"])
        app.buttons["reflection.weekly"].tap()
        XCTAssertTrue(waitFor(app.staticTexts["reflection.period.unavailable"]).exists)
        app.buttons["reflection.done"].tap()
        reveal(app.buttons["reflection.monthly"])
        app.buttons["reflection.monthly"].tap()
        XCTAssertTrue(waitFor(app.staticTexts["reflection.period.unavailable"]).exists)
    }

    func testEmotionalZoomFindsVagueWritingAndAsksAQuestion() {
        openToday()
        waitFor(app.buttons["day.newEntry"]).tap()
        let editor = waitFor(app.textViews["editor.body"])
        editor.tap()
        editor.typeText("I feel bad about the thing that happened.")

        let zoom = waitFor(app.buttons["editor.zoom"])
        XCTAssertTrue(zoom.isEnabled)
        zoom.tap()

        XCTAssertEqual(waitFor(app.staticTexts["editor.zoom.excerpt"]).label, "“I feel bad”")
        XCTAssertTrue(app.staticTexts["editor.zoom.explanation"].label.contains("does not yet show"))
        XCTAssertEqual(app.staticTexts["editor.zoom.question"].label,
                       "What happened that made this feel difficult?")
        XCTAssertTrue(app.buttons["editor.zoom.refresh"].exists)
        app.buttons["editor.zoom.refresh"].tap()
        XCTAssertEqual(waitFor(app.staticTexts["editor.zoom.question"]).label,
                       "What happened that made this feel difficult?")
        attachScreenshot("Emotional Zoom question for vague journal writing")
        finishEditing()
        XCTAssertTrue(entryButton().exists)
    }

    func testManualFeelingSurvivesRegenerationAndCanReturnToAISuggestion() throws {
        openToday()
        createEntry("A synthetic memory of a quiet walk by the river.")
        reveal(app.staticTexts["reflection.daily.summary"])
        XCTAssertTrue(app.staticTexts["reflection.daily.summary"].label.contains("peace"))
        XCTAssertTrue(app.buttons["reflection.daily.refresh"].exists)
        attachScreenshot("Synthetic daily reflection")
        chooseFeeling("Joy")
        app.buttons["reflection.daily.refresh"].tap()
        XCTAssertEqual(waitFor(app.buttons["reflection.emotionMenu"]).value as? String, "Joy")
        attachScreenshot("User-corrected daily feeling")
        app.buttons["day.back"].tap()
        XCTAssertTrue(waitFor(try todayButton()).label.contains("Joy"))
        attachScreenshot("Timeline with user-corrected feeling")

        openToday()
        reveal(entryButton())
        entryButton().tap()
        let editor = waitFor(app.textViews["editor.body"])
        editor.tap()
        editor.typeText(" A second synthetic detail.")
        finishEditing()
        reveal(app.buttons["reflection.emotionMenu"])
        XCTAssertEqual(app.buttons["reflection.emotionMenu"].value as? String, "Joy")
        chooseFeeling("Use AI suggestion")
        app.buttons["day.back"].tap()
        XCTAssertTrue(waitFor(try todayButton()).label.contains("Peace"))
    }

    func testWeeklyAndMonthlyReflectionsUseSyntheticLocalProvider() {
        openToday()
        createEntry("A synthetic memory of a quiet walk by the river.")
        for kind in ["weekly", "monthly"] {
            reveal(app.buttons["reflection.\(kind)"])
            app.buttons["reflection.\(kind)"].tap()
            XCTAssertTrue(waitFor(app.staticTexts["reflection.period.summary"], timeout: 15).label.contains(kind))
            XCTAssertTrue(app.buttons["reflection.period.refresh"].exists)
            app.buttons["reflection.period.refresh"].tap()
            XCTAssertTrue(waitFor(app.staticTexts["reflection.period.summary"], timeout: 15).label.contains(kind))
            attachScreenshot("Synthetic \(kind) reflection")
            waitFor(app.buttons["reflection.done"]).tap()
        }
    }

    func testEmptyPeriodsOfferWritingWithoutGenerationError() {
        openToday()
        reveal(app.staticTexts["reflection.daily.empty"])
        for kind in ["weekly", "monthly"] {
            reveal(app.buttons["reflection.\(kind)"])
            app.buttons["reflection.\(kind)"].tap()
            XCTAssertTrue(waitFor(app.staticTexts["reflection.period.empty"]).label.contains("Write something"))
            XCTAssertFalse(app.buttons["reflection.period.retry"].exists)
            waitFor(app.buttons["reflection.done"]).tap()
        }
    }

    func testEntryDateCanMoveWithoutChangingCreationMetadata() throws {
        openToday()
        createEntry("A synthetic memory assigned to a different journal day.")
        reveal(entryButton())
        entryButton().tap()
        waitFor(app.buttons["editor.metadata"]).tap()
        let created = app.staticTexts["editor.createdAt"]
        reveal(created)
        let createdLabel = created.label
        reveal(app.staticTexts["editor.creationTimeZone"])
        attachScreenshot("Saved entry creation details before journal-day reassignment")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let today = try XCTUnwrap(components.day)
        let range = try XCTUnwrap(calendar.range(of: .day, in: .month, for: Date()))
        let targetDay = today == range.last ? today - 1 : today + 1
        let targetKey = String(format: "%04d-%02d-%02d", try XCTUnwrap(components.year),
                               try XCTUnwrap(components.month), targetDay)
        // Native graphical calendar cell labels differ across iOS versions.
        // Match the standalone civil day numeral, excluding toolbar elements.
        let calendarPicker = app.descendants(matching: .any).matching(identifier: "editor.journalDay").firstMatch
        let dayCell = calendarPicker.buttons.matching(NSPredicate(format: "label MATCHES %@", ".*\\b\(targetDay)\\b.*")).firstMatch
        reveal(dayCell, scrollingUp: false)
        dayCell.tap()
        waitFor(app.buttons["editor.metadataDone"]).tap()
        finishEditing()
        XCTAssertFalse(entryButton().exists, "Moving the entry must remove it from the previous day.")
        app.buttons["day.back"].tap()
        let target = app.buttons["timeline.openDay.\(targetKey)"]
        waitFor(target).tap()
        reveal(entryButton())
        entryButton().tap()
        waitFor(app.buttons["editor.metadata"]).tap()
        reveal(app.staticTexts["editor.createdAt"])
        XCTAssertEqual(app.staticTexts["editor.createdAt"].label, createdLabel,
                       "Changing the journal day must preserve its creation time.")
        reveal(app.staticTexts["editor.modifiedAt"])
        attachScreenshot("Entry metadata after independent journal-day reassignment")
    }

    private func launch(reset: Bool, provider: String) {
        app.launchArguments = ["--uitesting", provider, "--reduce-motion"]
        if reset { app.launchArguments.append("--reset-test-store") }
        app.launch()
        waitFor(app.buttons["timeline.today"], timeout: 12)
    }

    private func openToday() {
        waitFor(app.buttons["timeline.today"]).tap()
        waitFor(app.buttons["day.newEntry"])
    }

    private func createEntry(_ text: String) {
        waitFor(app.buttons["day.newEntry"]).tap()
        let editor = waitFor(app.textViews["editor.body"])
        editor.tap()
        editor.typeText(text)
        finishEditing()
    }

    private func finishEditing() {
        waitFor(app.buttons["editor.done"]).tap()
        let disappeared = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: app.textViews["editor.body"])
        XCTAssertEqual(XCTWaiter.wait(for: [disappeared], timeout: 8), .completed)
        waitFor(app.buttons["day.newEntry"])
    }

    private func chooseFeeling(_ title: String) {
        reveal(app.buttons["reflection.emotionMenu"])
        app.buttons["reflection.emotionMenu"].tap()
        attachScreenshot("Native day-feeling menu before choosing \(title)")
        let option = app.buttons[title].firstMatch
        reveal(option)
        option.tap()
    }

    private func entryButton() -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "day.entry.")).firstMatch
    }

    private func todayButton() throws -> XCUIElement {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        let key = String(format: "%04d-%02d-%02d", try XCTUnwrap(components.year),
                         try XCTUnwrap(components.month), try XCTUnwrap(components.day))
        return app.buttons["timeline.openDay.\(key)"]
    }

    private func reveal(_ element: XCUIElement, scrollingUp: Bool = true) {
        for _ in 0..<8 {
            if element.exists && element.isHittable { break }
            if scrollingUp { app.swipeUp() }
            else { app.swipeDown() }
        }
        XCTAssertTrue(element.waitForExistence(timeout: 8))
        XCTAssertTrue(element.isHittable)
    }

    @discardableResult
    private func waitFor(_ element: XCUIElement, timeout: TimeInterval = 8,
                         file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Expected UI element: \(element)", file: file, line: line)
        return element
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
