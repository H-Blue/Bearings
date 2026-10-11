import Foundation
import SwiftData
import XCTest
@testable import Bearings

/// Explicit physical-device smoke coverage. Ordinary simulator tests never
/// depend on Apple's model, and all journal material here is synthetic.
final class FoundationModelsDeviceTests: XCTestCase {
    @MainActor
    func testOnDeviceEmotionalZoomDailyWeeklyMonthlyPersistenceAndCache() async throws {
        #if targetEnvironment(simulator)
        throw XCTSkip("Real Foundation Models smoke coverage requires a supported physical device.")
        #else
        // Effective when the test runner enables test timeouts. Model generation
        // remains asynchronous; no semaphore or blocking wait is used.
        executionTimeAllowance = 600
        let intelligence = JournalIntelligenceFactory.make()
        switch await intelligence.availability() {
        case .available: break
        case .unavailable(let reason): throw XCTSkip(reason)
        }

        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = try XCTUnwrap(JournalDay(key: "2026-10-11"))
        _ = try store.create(
            day: day,
            body: "I was worried before meeting a friend for lunch. We laughed about a shared memory. After a quiet walk, I felt peaceful.",
            period: .midday
        )
        let service = JournalAnalysisService(store: store, intelligence: intelligence)
        service.loadStored()
        defer { service.cancel() }

        let zoomSource = "I felt bad about the thing that happened before lunch."
        let zoom = try await service.emotionalZoom(text: zoomSource)
        try zoom.validate(source: zoomSource)

        await service.analyze(day: day)
        XCTAssertEqual(service.states[day.key], .idle)
        let daily = try XCTUnwrap(store.dailyAnalysis(for: day))
        try daily.content.validate()
        XCTAssertFalse(daily.content.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertTrue(JournalEmotion.allCases.contains(daily.content.primaryEmotion))
        XCTAssertFalse(daily.isStale)
        XCTAssertEqual(daily.dayKey, day.key)
        XCTAssertEqual(daily.analysisVersion, JournalAnalysisService.version)
        let snapshots = try store.snapshots(from: day, through: day)
        XCTAssertEqual(daily.sourceFingerprint,
                       AnalysisFingerprint.entries(snapshots, version: JournalAnalysisService.version))

        service.setEmotion(.peace, for: day)
        XCTAssertEqual(service.states[day.key], .idle)
        XCTAssertEqual(try store.emotionOverrides(from: day, through: day)[day.key], .peace)

        let week = AnalysisPeriod.week(containing: day)
        XCTAssertEqual(week.firstDay.key, "2026-10-05")
        XCTAssertEqual(week.lastDay.key, "2026-10-11")
        await service.reflect(period: week)
        XCTAssertEqual(service.states[week.key], .idle)
        let weekly = try XCTUnwrap(store.reflection(for: week))
        try weekly.content.validate()
        XCTAssertFalse(weekly.content.overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertFalse(weekly.isStale)
        XCTAssertEqual(weekly.period, week)
        XCTAssertEqual(weekly.analysisVersion, JournalAnalysisService.version)
        XCTAssertEqual(weekly.sourceFingerprint,
                       try store.reflectionFingerprint(for: week, version: JournalAnalysisService.version))

        let month = AnalysisPeriod.month(containing: day)
        XCTAssertEqual(month.firstDay.key, "2026-10-01")
        XCTAssertEqual(month.lastDay.key, "2026-10-31")
        await service.reflect(period: month)
        XCTAssertEqual(service.states[month.key], .idle)
        let monthly = try XCTUnwrap(store.reflection(for: month))
        try monthly.content.validate()
        XCTAssertFalse(monthly.content.overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertFalse(monthly.isStale)
        XCTAssertEqual(monthly.period, month)
        XCTAssertEqual(monthly.analysisVersion, JournalAnalysisService.version)
        XCTAssertEqual(monthly.sourceFingerprint,
                       try store.reflectionFingerprint(for: month, version: JournalAnalysisService.version))
        // These booleans avoid printing any returned journal interpretation on failure.
        XCTAssertTrue(Set(monthly.content.importantEvents) == Set(weekly.content.importantEvents))

        await service.analyze(day: day)
        await service.reflect(period: week)
        await service.reflect(period: month)
        XCTAssertEqual(try store.dailyAnalysis(for: day)?.generatedAt, daily.generatedAt)
        XCTAssertEqual(try store.reflection(for: week)?.generatedAt, weekly.generatedAt)
        XCTAssertEqual(try store.reflection(for: month)?.generatedAt, monthly.generatedAt)
        XCTAssertEqual(try store.emotionOverrides(from: day, through: day)[day.key], .peace)

        let reloaded = JournalAnalysisService(store: store, intelligence: intelligence)
        reloaded.loadStored()
        XCTAssertEqual(reloaded.overrides[day.key], .peace)
        XCTAssertEqual(reloaded.daily[day.key]?.sourceFingerprint, daily.sourceFingerprint)
        #endif
    }
}
