import XCTest

/// These tests use an isolated, file-backed store. Resetting that store is opt-in:
/// relaunching with only `--uitesting` must preserve entries.
final class JournalFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-test-store"]
        app.launch()
        waitFor(app.buttons["timeline.today"])
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    func testEntryPersistsAcrossRelaunchAndCanBeEdited() {
        let original = "A quiet morning at the river."
        let addition = " A new detail remembered later."

        openToday()
        createEntry(body: original)
        attachScreenshot(named: "Day with saved entry")

        relaunchPreservingStore()
        openToday()
        let persistedEntry = entryButton(containing: original)
        waitFor(persistedEntry)
        persistedEntry.tap()

        let editor = bodyEditor()
        XCTAssertEqual(editor.value as? String, original)
        editor.tap()
        editor.typeText(addition)
        XCTAssertTrue((editor.value as? String ?? "").contains(addition))
        finishEditing()

        relaunchPreservingStore()
        openToday()
        let editedEntry = entryButton(containing: original)
        waitFor(editedEntry)
        editedEntry.tap()
        let savedBody = bodyEditor().value as? String ?? ""
        XCTAssertTrue(savedBody.contains(original), "The original writing should survive an edit.")
        XCTAssertTrue(savedBody.contains(addition), "The edit should survive a process relaunch.")
        attachScreenshot(named: "Persisted edited entry")
    }

    func testMultipleEntriesRemainOnTheSameDay() throws {
        let first = "First memory from this day."
        let second = "Another memory from the same day."
        let third = "A third moment remembered."
        let fourth = "One more detail from this day."

        openToday()
        createEntry(body: first)
        createEntry(body: second)
        createEntry(body: third)
        createEntry(body: fourth)

        XCTAssertEqual(entryButtons().count, 4)
        XCTAssertTrue(entryButton(containing: first).exists)
        XCTAssertTrue(entryButton(containing: second).exists)
        XCTAssertTrue(entryButton(containing: third).exists)
        XCTAssertTrue(entryButton(containing: fourth).exists)

        waitFor(app.buttons["day.back"]).tap()
        waitFor(app.buttons["timeline.today"])
        let today = try timelineTodayDateButton()
        revealTimelineDate(today)
        XCTAssertTrue(today.label.contains("4 entries"), "The date's accessible count should include every saved memory.")
        attachScreenshot(named: "Timeline with three dots and a remaining count")
        today.tap()
        waitFor(app.buttons["day.newEntry"])
        XCTAssertEqual(entryButtons().count, 4, "Returning from the timeline must show all four entries.")

        relaunchPreservingStore()
        revealTimelineDate(today)
        XCTAssertTrue(today.label.contains("4 entries"), "The timeline's full count should survive a process relaunch.")
        attachScreenshot(named: "Persisted timeline remaining-count marker")
        today.tap()
        waitFor(entryButton(containing: fourth))
        XCTAssertEqual(entryButtons().count, 4, "All four entries should persist on the same civil day.")
        for body in [first, second, third, fourth] {
            XCTAssertTrue(entryButton(containing: body).exists)
        }
        attachScreenshot(named: "Four entries on one day")
    }

    func testBlankDraftDoesNotCreateAnEntry() {
        openToday()
        XCTAssertEqual(entryButtons().count, 0)
        waitFor(app.buttons["day.newEntry"]).tap()
        _ = bodyEditor()
        waitFor(app.buttons["editor.done"]).tap()
        waitForDisappearance(app.textViews["editor.body"])
        waitFor(app.buttons["day.newEntry"])
        XCTAssertEqual(entryButtons().count, 0, "Leaving an untouched draft must keep the day empty.")

        relaunchPreservingStore()
        openToday()
        XCTAssertEqual(entryButtons().count, 0, "A blank draft must not appear after relaunch.")
    }

    func testEntryDeletionRequiresConfirmationAndPersists() {
        let body = "A memory to remove deliberately."
        openToday()
        createEntry(body: body)
        waitFor(entryButton(containing: body)).tap()
        _ = bodyEditor()
        waitFor(app.buttons["editor.delete"]).tap()

        let confirmation = app.alerts["Delete Entry"]
        waitFor(confirmation)
        waitFor(confirmation.buttons["Cancel"]).tap()
        waitForDisappearance(confirmation)
        XCTAssertEqual(bodyEditor().value as? String, body, "Cancel must preserve the entry.")

        waitFor(app.buttons["editor.delete"]).tap()
        waitFor(confirmation)
        waitFor(confirmation.buttons["Delete"]).tap()
        waitForDisappearance(app.textViews["editor.body"])
        waitFor(app.buttons["day.newEntry"])
        XCTAssertFalse(entryButton(containing: body).exists)
        XCTAssertEqual(entryButtons().count, 0)

        relaunchPreservingStore()
        openToday()
        XCTAssertEqual(entryButtons().count, 0, "Deletion should survive a process relaunch.")
        attachScreenshot(named: "Day after confirmed deletion")
    }

    func testLongWritingCanBeSavedWithTheKeyboardOpen() {
        let lines = (1...24).map { "Memory \($0): Walking slowly, noticing light and sound." }
        let body = lines.joined(separator: "\n")

        openToday()
        waitFor(app.buttons["day.newEntry"]).tap()
        let editor = bodyEditor()
        editor.tap()
        editor.typeText(body)
        XCTAssertTrue(app.keyboards.firstMatch.exists)
        XCTAssertEqual(editor.value as? String, body)
        attachScreenshot(named: "Long entry with native keyboard")
        waitFor(app.buttons["editor.hideKeyboard"]).tap()
        waitForDisappearance(app.keyboards.firstMatch)
        XCTAssertEqual(editor.value as? String, body, "Hiding the keyboard must preserve every line of writing.")
        attachScreenshot(named: "Long entry after hiding keyboard")
        editor.tap()
        waitFor(app.keyboards.firstMatch)
        XCTAssertEqual(editor.value as? String, body)
        attachScreenshot(named: "Long entry after keyboard returns")
        finishEditing()

        relaunchPreservingStore()
        openToday()
        waitFor(entryButton(containing: lines[0])).tap()
        XCTAssertEqual(bodyEditor().value as? String, body, "All lines should persist, including off-screen writing.")
    }

    func testMorningBranchPersistsAndPeriodCanBeChanged() {
        let body = "The morning light reached the kitchen table."
        openToday()
        let morning = app.buttons["day.period.morning"]
        XCTAssertEqual(waitFor(morning).label, "Morning, 0 entries")
        morning.tap()
        let editor = bodyEditor()
        assertSelectedPeriod("Morning")
        editor.tap()
        editor.typeText(body)
        finishEditing()
        XCTAssertEqual(waitFor(morning).label, "Morning, 1 entry")
        attachScreenshot(named: "Morning branch with saved memory")

        relaunchPreservingStore()
        openToday()
        XCTAssertEqual(waitFor(morning).label, "Morning, 1 entry")
        morning.tap()
        XCTAssertEqual(bodyEditor().value as? String, body)
        assertSelectedPeriod("Morning")

        waitFor(app.buttons["editor.period"]).tap()
        waitFor(app.buttons["Evening"].firstMatch).tap()
        assertSelectedPeriod("Evening")
        finishEditing()
        XCTAssertEqual(waitFor(morning).label, "Morning, 0 entries")
        XCTAssertEqual(waitFor(app.buttons["day.period.evening"]).label, "Evening, 1 entry")

        relaunchPreservingStore()
        openToday()
        XCTAssertEqual(waitFor(app.buttons["day.period.evening"]).label, "Evening, 1 entry")
        app.buttons["day.period.evening"].tap()
        XCTAssertEqual(bodyEditor().value as? String, body)
        assertSelectedPeriod("Evening")
        attachScreenshot(named: "Reassigned period after relaunch")
    }

    func testPreviousMonthDayRetainsEntryAndNavigationContext() throws {
        // Calendar keys are local Gregorian civil dates, matching the app. A test
        // run is assumed not to cross local midnight or a time-zone change.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let month = calendar.dateComponents([.year, .month], from: Date())
        let monthStart = try XCTUnwrap(calendar.date(from: DateComponents(year: month.year, month: month.month, day: 1, hour: 12)))
        let previousMonth = try XCTUnwrap(calendar.date(byAdding: .month, value: -1, to: monthStart))
        let previous = calendar.dateComponents([.year, .month, .day], from: previousMonth)
        let previousKey = String(format: "%04d-%02d-%02d", try XCTUnwrap(previous.year), try XCTUnwrap(previous.month), try XCTUnwrap(previous.day))
        let previousDay = app.buttons["timeline.openDay.\(previousKey)"]
        let body = "A memory kept on an earlier calendar day."

        waitFor(app.buttons["timeline.previousMonth"]).tap()
        waitFor(previousDay).tap()
        waitFor(app.buttons["day.newEntry"])
        createEntry(body: body)
        waitFor(app.buttons["day.back"]).tap()
        waitFor(app.buttons["timeline.today"])
        XCTAssertTrue(waitFor(previousDay).label.contains("1 entry"), "Reverse navigation should retain the earlier month and its marker.")
        attachScreenshot(named: "Earlier calendar day with an entry marker")

        waitFor(app.buttons["timeline.nextMonth"]).tap()
        waitForDisappearance(previousDay)
        waitFor(app.buttons["timeline.previousMonth"]).tap()
        XCTAssertTrue(waitFor(previousDay).label.contains("1 entry"))

        relaunchPreservingStore()
        waitFor(app.buttons["timeline.previousMonth"]).tap()
        XCTAssertTrue(waitFor(previousDay).label.contains("1 entry"))
        previousDay.tap()
        waitFor(entryButton(containing: body)).tap()
        XCTAssertEqual(bodyEditor().value as? String, body)
        finishEditing()
        waitFor(app.buttons["day.back"]).tap()
        openToday()
        XCTAssertEqual(entryButtons().count, 0, "Writing on a selected earlier day must not create an entry on today.")
    }

    func testForwardAndReverseNavigationWithReduceMotion() {
        app.terminate()
        app.launchArguments = ["--uitesting", "--reduce-motion"]
        app.launch()
        openToday()
        XCTAssertTrue(waitFor(app.buttons["day.period.morning"]).exists)
        attachScreenshot(named: "Day with Reduce Motion enabled")
        waitFor(app.buttons["day.back"]).tap()
        XCTAssertTrue(waitFor(app.buttons["timeline.today"]).exists)
        attachScreenshot(named: "Timeline after Reduce Motion reverse navigation")
        openToday()
        waitFor(app.buttons["day.back"]).tap()
        XCTAssertTrue(waitFor(app.buttons["timeline.previousMonth"]).exists)
    }

    func testTimelineDateCellRemainsReachableWithLargeText() throws {
        let today = try timelineTodayDateButton()
        revealTimelineDate(today)
        attachScreenshot(named: "Timeline with visible calendar date labels")

        today.tap()
        XCTAssertTrue(waitFor(app.buttons["day.newEntry"]).isHittable)
        let back = waitFor(app.buttons["day.back"])
        XCTAssertTrue(back.isHittable)
        back.tap()
        XCTAssertTrue(waitFor(today).isHittable, "Returning from a day should preserve the selected date's position.")
        attachScreenshot(named: "Timeline after returning to the selected date")
    }

    func testTimelineCanBeScrolledFromTheBottomAndRetainsPosition() throws {
        let today = try timelineTodayDateButton()
        waitFor(today)
        XCTAssertFalse(app.staticTexts["Bearings"].exists)
        XCTAssertFalse(app.staticTexts["Find what’s been lost inside."].exists)
        XCTAssertFalse(app.staticTexts["Your story begins with a day."].exists)
        XCTAssertEqual(app.buttons["timeline.today"].label, "Write today")
        let initialX = today.frame.midX
        let right = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.88))
        let left = app.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.88))
        right.press(forDuration: 0.1, thenDragTo: left)
        XCTAssertLessThan(today.frame.midX, initialX - 40,
                          "A thumb swipe near the bottom must move the timeline.")
        left.press(forDuration: 0.1, thenDragTo: right)
        XCTAssertTrue(today.isHittable, "A reverse bottom swipe should reveal today's date again.")
        let returnedX = today.frame.midX
        attachScreenshot(named: "Centered timeline after bottom thumb swipes")
        today.tap()
        waitFor(app.buttons["day.newEntry"])
        waitFor(app.buttons["day.back"]).tap()
        waitFor(today)
        XCTAssertEqual(today.frame.midX, returnedX, accuracy: 2,
                       "Returning from a day must retain the scrolled timeline position.")
    }

    private func timelineTodayDateButton() throws -> XCUIElement {
        // Match the app's local Gregorian date identity. These tests assume a
        // run does not cross local midnight or a time-zone change.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let date = calendar.dateComponents([.year, .month, .day], from: Date())
        let key = String(format: "%04d-%02d-%02d", try XCTUnwrap(date.year),
                         try XCTUnwrap(date.month), try XCTUnwrap(date.day))
        return app.buttons["timeline.openDay.\(key)"]
    }

    private func revealTimelineDate(_ date: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        // Large accessibility text sizes need a vertical scroll to reveal the
        // whole date cell, including both its markers and its number label.
        for _ in 0..<4 {
            if date.isHittable && date.frame.maxY <= app.frame.maxY - 44 { break }
            app.swipeUp()
        }
        XCTAssertTrue(date.isHittable, "The timeline date cell should be reachable at the system text size.", file: file, line: line)
        XCTAssertLessThanOrEqual(date.frame.maxY, app.frame.maxY - 44,
                                 "The complete date cell should fit above the screen's bottom edge.", file: file, line: line)
    }

    private func openToday() {
        waitFor(app.buttons["timeline.today"]).tap()
        waitFor(app.buttons["day.newEntry"])
    }

    private func createEntry(body: String) {
        waitFor(app.buttons["day.newEntry"]).tap()
        let editor = bodyEditor()
        editor.tap()
        editor.typeText(body)
        XCTAssertEqual(editor.value as? String, body)
        finishEditing()
        waitFor(entryButton(containing: body.components(separatedBy: "\n")[0]))
    }

    private func finishEditing() {
        let saved = app.staticTexts["editor.saved"]
        waitFor(saved)
        let savedStatus = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "Saved"), object: saved)
        XCTAssertEqual(XCTWaiter.wait(for: [savedStatus], timeout: 8), .completed,
                       "The editor should confirm the writing was saved before leaving.")
        XCTAssertEqual(saved.label, "Saved")
        waitFor(app.buttons["editor.done"]).tap()
        waitForDisappearance(app.textViews["editor.body"])
        waitFor(app.buttons["day.newEntry"])
    }

    private func relaunchPreservingStore() {
        app.terminate()
        app.launchArguments = ["--uitesting"]
        app.launch()
        waitFor(app.buttons["timeline.today"])
    }

    private func bodyEditor() -> XCUIElement {
        waitFor(app.textViews["editor.body"])
    }

    private func assertSelectedPeriod(_ title: String, file: StaticString = #filePath, line: UInt = #line) {
        let picker = waitFor(app.buttons["editor.period"])
        let selected = NSPredicate { _, _ in
            picker.label.contains(title) || (picker.value as? String ?? "").contains(title)
        }
        let expectation = XCTNSPredicateExpectation(predicate: selected, object: picker)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 8), .completed,
                       "The editor should show the selected \(title.lowercased()) period.", file: file, line: line)
    }

    private func entryButtons() -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "day.entry."))
    }

    private func entryButton(containing excerpt: String) -> XCUIElement {
        entryButtons().matching(NSPredicate(format: "label CONTAINS %@", excerpt)).firstMatch
    }

    @discardableResult
    private func waitFor(_ element: XCUIElement, timeout: TimeInterval = 8,
                         file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Expected UI element: \(element)", file: file, line: line)
        return element
    }

    private func waitForDisappearance(_ element: XCUIElement, timeout: TimeInterval = 8,
                                      file: StaticString = #filePath, line: UInt = #line) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed,
                       "UI element should disappear: \(element)", file: file, line: line)
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
