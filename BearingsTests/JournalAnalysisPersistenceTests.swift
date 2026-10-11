import Foundation
import SwiftData
import XCTest
@testable import Bearings

final class JournalAnalysisPersistenceTests: XCTestCase {
    private let dailyContent = DailyAnalysisContent(
        summary: "A walk offered a peaceful pause.", primaryEmotion: .peace, secondaryEmotion: .joy,
        importantEvents: ["Walked outdoors"], emotionalTrajectory: "Busy, then peaceful"
    )
    private let reflectionContent = ReflectionContent(
        overview: "Walking offered moments of peace.", importantEvents: ["Walked outdoors"],
        emotionalThemes: "Peace", relationships: "None mentioned", interests: "Walking",
        changes: "More time outdoors"
    )

    @MainActor
    func testDerivedResultsAndSeparateCorrectionSurviveFileReopenAndRegeneration() throws {
        let url = temporaryStoreURL()
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let week = AnalysisPeriod.week(containing: day)
        let generatedAt = Date(timeIntervalSince1970: 1_792_000_000)
        try autoreleasepool {
            let container = try PersistenceController.makeContainer(storeURL: url)
            let store = JournalStore(context: container.mainContext, now: { generatedAt })
            _ = try store.create(day: day, body: "A peaceful walk outdoors.")
            try saveDaily(on: day, store: store)
            try store.setEmotionOverride(.joy, for: day)
            try saveReflection(week, store: store)
            _ = store.takeChangedDays()
            try saveDaily(on: day, store: store)
            try saveReflection(week, store: store)
            XCTAssertTrue(store.takeChangedDays().isEmpty)
        }
        let reopened = try PersistenceController.makeContainer(storeURL: url)
        let store = JournalStore(context: reopened.mainContext)
        let daily = try XCTUnwrap(store.dailyAnalysis(for: day))
        XCTAssertEqual(daily.content, dailyContent)
        XCTAssertEqual(daily.analysisVersion, 1)
        XCTAssertEqual(daily.generatedAt, generatedAt)
        XCTAssertFalse(daily.isStale)
        XCTAssertEqual(try store.dailyAnalyses(from: day, through: day).map(\.dayKey), [day.key])
        XCTAssertEqual(try store.emotionOverrides(from: day, through: day), [day.key: .joy])
        XCTAssertEqual(try store.reflection(for: week)?.content, reflectionContent)
        XCTAssertFalse(try XCTUnwrap(store.reflection(for: week)).isStale)
    }

    @MainActor
    func testJournalMutationsInvalidateBothMovedDaysAndAllOverlappingPeriods() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let oldDay = try XCTUnwrap(JournalDay(key: "2026-09-30"))
        let newDay = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let unaffectedDay = try XCTUnwrap(JournalDay(key: "2026-11-15"))
        let entry = try store.create(day: oldDay, body: "A peaceful walk outdoors.")
        _ = try store.create(day: newDay, body: "Another peaceful day.")
        _ = try store.create(day: unaffectedDay, body: "Later plans.")
        try saveDaily(on: oldDay, store: store)
        try saveDaily(on: newDay, store: store)
        let oldWeek = AnalysisPeriod.week(containing: oldDay)
        let newWeek = AnalysisPeriod.week(containing: newDay)
        let oldMonth = AnalysisPeriod.month(containing: oldDay)
        let newMonth = AnalysisPeriod.month(containing: newDay)
        let unaffectedMonth = AnalysisPeriod.month(containing: unaffectedDay)
        for period in [oldWeek, newWeek, oldMonth, newMonth, unaffectedMonth] {
            try saveReflection(period, store: store)
        }
        try store.setEmotionOverride(.love, for: oldDay)
        for period in [oldWeek, oldMonth] { try saveReflection(period, store: store) }
        _ = store.takeChangedDays()
        let creation = entry.createdAt
        try store.update(entry: entry, body: entry.body, day: newDay)
        XCTAssertEqual(entry.createdAt, creation)
        XCTAssertEqual(store.takeChangedDays(), [oldDay, newDay])
        XCTAssertTrue(try XCTUnwrap(store.dailyAnalysis(for: oldDay)).isStale)
        XCTAssertTrue(try XCTUnwrap(store.dailyAnalysis(for: newDay)).isStale)
        for period in [oldWeek, newWeek, oldMonth, newMonth] {
            XCTAssertTrue(try XCTUnwrap(store.reflection(for: period)).isStale)
        }
        XCTAssertFalse(try XCTUnwrap(store.reflection(for: unaffectedMonth)).isStale)
        XCTAssertEqual(try store.emotionOverrides(from: oldDay, through: oldDay), [oldDay.key: .love])
        XCTAssertTrue(try store.entries(for: oldDay).isEmpty)

        try saveDaily(on: newDay, store: store)
        try saveReflection(newMonth, store: store)
        try store.update(entry: entry, body: "A new remembered detail.")
        XCTAssertTrue(try XCTUnwrap(store.dailyAnalysis(for: newDay)).isStale)
        XCTAssertTrue(try XCTUnwrap(store.reflection(for: newMonth)).isStale)
        try saveDaily(on: newDay, store: store)
        try saveReflection(newMonth, store: store)
        try store.delete(entry: entry)
        XCTAssertTrue(try XCTUnwrap(store.dailyAnalysis(for: newDay)).isStale)
        XCTAssertTrue(try XCTUnwrap(store.reflection(for: newMonth)).isStale)
        try saveDaily(on: newDay, store: store)
        try saveReflection(newMonth, store: store)
        _ = try store.create(day: newDay, body: "A newly saved note.")
        XCTAssertTrue(try XCTUnwrap(store.dailyAnalysis(for: newDay)).isStale)
        XCTAssertTrue(try XCTUnwrap(store.reflection(for: newMonth)).isStale)
    }

    @MainActor
    func testSourceChangesRejectOldDailyAndReflectionResultsEvenWhenClockDoesNotAdvance() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let instant = Date(timeIntervalSince1970: 1_792_000_000)
        let store = JournalStore(context: container.mainContext, now: { instant })
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let week = AnalysisPeriod.week(containing: day)
        let entry = try store.create(day: day, body: "Original source")
        try saveDaily(on: day, store: store)
        try saveReflection(week, store: store)
        let dailyFingerprint = AnalysisFingerprint.entries(try store.snapshots(from: day, through: day), version: 1)
        let weeklyFingerprint = try store.reflectionFingerprint(for: week, version: 1)
        try store.update(entry: entry, body: "Updated source in the same clock instant")
        XCTAssertThrowsError(try store.saveDailyAnalysis(dailyContent, for: day, sourceFingerprint: dailyFingerprint, version: 1)) {
            XCTAssertEqual($0 as? AnalysisError, .sourceChanged)
        }
        XCTAssertThrowsError(try store.saveReflection(reflectionContent, for: week, sourceFingerprint: weeklyFingerprint, version: 1)) {
            XCTAssertEqual($0 as? AnalysisError, .sourceChanged)
        }
        XCTAssertTrue(try XCTUnwrap(store.dailyAnalysis(for: day)).isStale)
        XCTAssertTrue(try XCTUnwrap(store.reflection(for: week)).isStale)
    }

    @MainActor
    func testCorrectionsInvalidateReflectionsPreserveAIEmotionAndRejectRunningReflection() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let week = AnalysisPeriod.week(containing: day)
        _ = try store.create(day: day, body: "A peaceful walk outdoors.")
        try saveDaily(on: day, store: store)
        try saveReflection(week, store: store)
        let fingerprint = try store.reflectionFingerprint(for: week, version: 1)
        _ = store.takeChangedDays()
        try store.setEmotionOverride(.sadness, for: day)
        XCTAssertTrue(store.takeChangedDays().isEmpty)
        XCTAssertFalse(try XCTUnwrap(store.dailyAnalysis(for: day)).isStale)
        XCTAssertEqual(try store.dailyAnalysis(for: day)?.content.primaryEmotion, .peace)
        XCTAssertTrue(try XCTUnwrap(store.reflection(for: week)).isStale)
        XCTAssertNotEqual(try store.reflectionFingerprint(for: week, version: 1), fingerprint)
        XCTAssertThrowsError(try store.saveReflection(reflectionContent, for: week, sourceFingerprint: fingerprint, version: 1)) {
            XCTAssertEqual($0 as? AnalysisError, .sourceChanged)
        }
        try store.setEmotionOverride(nil, for: day)
        XCTAssertTrue(try store.emotionOverrides(from: day, through: day).isEmpty)
        XCTAssertEqual(try store.reflectionFingerprint(for: week, version: 1), fingerprint)
    }

    @MainActor
    func testPrecedingWeekChangesInvalidateOnlyItsDirectWeeklyDependent() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        var clock = Date(timeIntervalSince1970: 1_792_000_000)
        let store = JournalStore(context: container.mainContext, now: { clock })
        let precedingDay = try XCTUnwrap(JournalDay(key: "2026-09-27"))
        let currentDay = try XCTUnwrap(JournalDay(key: "2026-10-04"))
        let nextDay = try XCTUnwrap(JournalDay(key: "2026-10-11"))
        let precedingEntry = try store.create(day: precedingDay, body: "A peaceful walk outdoors.")
        _ = try store.create(day: currentDay, body: "Another peaceful walk outdoors.")
        _ = try store.create(day: nextDay, body: "A later peaceful walk outdoors.")
        let preceding = AnalysisPeriod.week(containing: precedingDay)
        let current = AnalysisPeriod.week(containing: currentDay)
        let next = AnalysisPeriod.week(containing: nextDay)
        for day in [precedingDay, currentDay, nextDay] { try saveDaily(on: day, store: store) }
        for period in [preceding, current, next] { clock.addTimeInterval(1); try saveReflection(period, store: store) }
        let initialCurrentFingerprint = try store.reflectionFingerprint(for: current, version: 1)

        try store.update(entry: precedingEntry, body: "A changed peaceful walk outdoors.")
        XCTAssertTrue(try XCTUnwrap(store.reflection(for: preceding)).isStale)
        XCTAssertTrue(try XCTUnwrap(store.reflection(for: current)).isStale)
        XCTAssertFalse(try XCTUnwrap(store.reflection(for: next)).isStale,
                       "Invalidation must stop at the direct dependent week.")
        XCTAssertNotEqual(try store.reflectionFingerprint(for: current, version: 1), initialCurrentFingerprint)

        try saveDaily(on: precedingDay, store: store)
        clock.addTimeInterval(1); try saveReflection(preceding, store: store)
        clock.addTimeInterval(1); try saveReflection(current, store: store)
        try store.setEmotionOverride(.joy, for: precedingDay)
        XCTAssertTrue(try XCTUnwrap(store.reflection(for: preceding)).isStale)
        XCTAssertTrue(try XCTUnwrap(store.reflection(for: current)).isStale)

        clock.addTimeInterval(1); try saveReflection(preceding, store: store)
        clock.addTimeInterval(1); try saveReflection(current, store: store)
        clock.addTimeInterval(1); try saveReflection(next, store: store)
        let beforePriorRegeneration = try store.reflectionFingerprint(for: current, version: 1)
        clock.addTimeInterval(1); try saveReflection(preceding, store: store)
        XCTAssertTrue(try XCTUnwrap(store.reflection(for: current)).isStale)
        XCTAssertNotEqual(try store.reflectionFingerprint(for: current, version: 1), beforePriorRegeneration)
        XCTAssertFalse(try XCTUnwrap(store.reflection(for: next)).isStale)
    }

    @MainActor
    func testAuthoritativeSnapshotsExcludeUnsavedModelsEditsAndDerivedData() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let observed = container.mainContext
        let store = JournalStore(context: observed)
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let entry = try store.create(day: day, body: "Committed source")
        try saveDaily(on: day, store: store)
        let registered = try XCTUnwrap(observed.fetch(FetchDescriptor<JournalEntry>()).first)
        registered.body = "Uncommitted edit"
        observed.insert(JournalEntry(day: day, body: "Uncommitted insertion"))
        let derived = try XCTUnwrap(observed.fetch(FetchDescriptor<DailyAnalysisRecord>()).first)
        derived.contentData = Data("invalid pending JSON".utf8)
        observed.insert(EmotionOverrideRecord(dayKey: day.key, emotion: .anger, modifiedAt: Date()))
        let snapshots = try store.snapshots(from: day, through: day)
        XCTAssertEqual(snapshots.count, 1)
        XCTAssertEqual(snapshots.first?.id, entry.id)
        XCTAssertEqual(snapshots.first?.body, "Committed source")
        XCTAssertEqual(try store.dailyAnalysis(for: day)?.content, dailyContent)
        XCTAssertTrue(try store.emotionOverrides(from: day, through: day).isEmpty)
        observed.rollback()
    }

    @MainActor
    func testInvalidDerivedJSONAndEmotionTaxonomySurfaceReadErrors() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let context = ModelContext(container)
        context.autosaveEnabled = false
        context.insert(DailyAnalysisRecord(dayKey: day.key, contentData: Data("invalid".utf8),
                                          sourceFingerprint: "fixture", generatedAt: Date(), analysisVersion: 1))
        let override = EmotionOverrideRecord(dayKey: day.key, emotion: .peace, modifiedAt: Date())
        override.emotionRawValue = "unsupported"
        context.insert(override)
        try context.save()
        let store = JournalStore(context: container.mainContext)
        XCTAssertThrowsError(try store.dailyAnalysis(for: day))
        XCTAssertThrowsError(try store.emotionOverrides(from: day, through: day)) {
            XCTAssertEqual($0 as? AnalysisError, .invalidOutput)
        }
    }

    @MainActor
    private func saveDaily(on day: JournalDay, store: JournalStore) throws {
        let fingerprint = AnalysisFingerprint.entries(try store.snapshots(from: day, through: day), version: 1)
        try store.saveDailyAnalysis(dailyContent, for: day, sourceFingerprint: fingerprint, version: 1)
    }

    @MainActor
    private func saveReflection(_ period: AnalysisPeriod, store: JournalStore) throws {
        try store.saveReflection(reflectionContent, for: period,
                                 sourceFingerprint: store.reflectionFingerprint(for: period, version: 1), version: 1)
    }

    private func temporaryStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("BearingsAnalysisTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("Journal.store")
    }
}
