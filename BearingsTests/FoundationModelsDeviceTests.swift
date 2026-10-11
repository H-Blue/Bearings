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
        let intelligence = DeviceTracingIntelligence(base: JournalIntelligenceFactory.make())
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
        XCTAssertEqual(week.firstDay.key, "2026-10-11")
        XCTAssertEqual(week.lastDay.key, "2026-10-17")
        await service.reflect(period: week)
        let weeklyCalls = await intelligence.weeklyCalls
        let weeklyDiagnostics = await intelligence.weeklyDiagnostics
        XCTAssertEqual(service.states[week.key], .idle,
                       "Weekly stages: \(weeklyCalls.extractions) extraction, \(weeklyCalls.compositions) composition calls; \(weeklyDiagnostics.missingExcerpts) missing excerpts, \(weeklyDiagnostics.invalidDates) invalid dates.")
        let weekly = try XCTUnwrap(store.reflection(for: week))
        try weekly.content.validate()
        XCTAssertFalse(weekly.content.overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        XCTAssertFalse(weekly.isStale)
        XCTAssertEqual(weekly.period, week)
        XCTAssertEqual(weekly.analysisVersion, JournalAnalysisService.version)
        XCTAssertNotNil(weekly.content.weeklyDetails)
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
        let expectedMonthlyEvents = Set(daily.content.importantEvents.map { "\(day.key): \($0)" })
        XCTAssertTrue(Set(monthly.content.importantEvents) == expectedMonthlyEvents)

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

private actor DeviceTracingIntelligence: JournalIntelligence {
    private let base: any JournalIntelligence
    private(set) var weeklyCalls = (extractions: 0, compositions: 0)
    private(set) var weeklyDiagnostics = (missingExcerpts: 0, invalidDates: 0)

    init(base: any JournalIntelligence) { self.base = base }
    func availability() async -> IntelligenceAvailability { await base.availability() }
    func analyze(_ text: String) async throws -> DailyAnalysisContent { try await base.analyze(text) }
    func reflect(_ text: String, kind: ReflectionKind) async throws -> ReflectionContent {
        try await base.reflect(text, kind: kind)
    }
    func extractWeeklySignals(_ text: String) async throws -> WeeklySignals {
        weeklyCalls.extractions += 1
        let result = try await base.extractWeeklySignals(text)
        let signals = result.focusAreas + result.explicitGoals + result.progress + result.obstacles
            + result.unfinishedThreads + result.emotionalChanges + result.precedingWeekContinuity
        weeklyDiagnostics.missingExcerpts += signals.filter { !text.contains($0.evidenceExcerpt) }.count
        weeklyDiagnostics.missingExcerpts += result.importantEvents.filter { !text.contains($0.evidenceExcerpt) }.count
        let requested = AnalysisPeriod.week(containing: JournalDay(key: "2026-10-11")!)
        weeklyDiagnostics.invalidDates += result.importantEvents.filter {
            guard let day = JournalDay(key: $0.dayKey) else { return true }
            return !requested.days.contains(day)
        }.count
        return result
    }
    func composeWeeklyReflection(_ text: String) async throws -> ReflectionContent {
        weeklyCalls.compositions += 1
        return try await base.composeWeeklyReflection(text)
    }
    func emotionalZoom(_ text: String) async throws -> EmotionalZoomContent {
        try await base.emotionalZoom(text)
    }
}
