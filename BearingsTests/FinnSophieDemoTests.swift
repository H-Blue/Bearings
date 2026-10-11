import SwiftData
import XCTest
@testable import Bearings

final class FinnSophieDemoTests: XCTestCase {
    @MainActor
    func testSeederCreatesTwelveEntriesThroughSaturdayAndPreparedSundayReview() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        try FinnSophieDemoSeeder.seed(in: container)
        let store = JournalStore(context: container.mainContext)

        let firstDay = try XCTUnwrap(JournalDay(key: "2026-10-04"))
        let lastWrittenDay = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let reviewDay = try XCTUnwrap(JournalDay(key: "2026-10-11"))
        let snapshots = try store.snapshots(from: firstDay, through: reviewDay)

        XCTAssertEqual(snapshots.count, 12)
        XCTAssertEqual(Set(snapshots.map(\.dayKey)), Set((4...10).map { "2026-10-\(String(format: "%02d", $0))" }))
        XCTAssertEqual(try store.entries(for: lastWrittenDay).count, 1)
        XCTAssertTrue(try store.entries(for: reviewDay).isEmpty)
        XCTAssertTrue(snapshots.first?.body.hasPrefix("Weird talk with Sophie.") == true)
        XCTAssertTrue(snapshots.last?.body.contains("I turn it into a task") == true)

        let period = AnalysisPeriod.weekForReview(on: reviewDay)
        let reflection = try XCTUnwrap(store.reflection(for: period))
        XCTAssertEqual(period.firstDay.key, "2026-10-04")
        XCTAssertEqual(period.lastDay.key, "2026-10-10")
        XCTAssertEqual(reflection.analysisVersion, JournalAnalysisService.version)
        XCTAssertFalse(reflection.isStale)
        XCTAssertEqual(reflection.content.isPreparedDemo, true)
        XCTAssertEqual(reflection.content.weeklyDetails?.lessonReadiness, .continueCurrentLesson)
        XCTAssertTrue(reflection.content.weeklyDetails?.realisticImprovement.contains("ask what she needs") == true)
        XCTAssertEqual(
            reflection.sourceFingerprint,
            try store.reflectionFingerprint(for: period, version: JournalAnalysisService.version)
        )
    }

    @MainActor
    func testSeederDoesNotDuplicateAnExistingDemo() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        try FinnSophieDemoSeeder.seed(in: container)
        try FinnSophieDemoSeeder.seed(in: container)
        let store = JournalStore(context: container.mainContext)
        let firstDay = try XCTUnwrap(JournalDay(key: "2026-10-04"))
        let reviewDay = try XCTUnwrap(JournalDay(key: "2026-10-11"))

        XCTAssertEqual(try store.snapshots(from: firstDay, through: reviewDay).count, 12)
    }
}
