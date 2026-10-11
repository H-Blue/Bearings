import Foundation
import SwiftData
import XCTest
@testable import Bearings

final class JournalAnalysisServiceTests: XCTestCase {
    @MainActor
    func testExplicitRefreshBypassesCachesAndPreservesCorrection() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = JournalDay(key: "2026-10-01")!
        _ = try store.create(day: day, body: "In-month walk with a friend.")
        let model = ServiceFixtureIntelligence()
        let service = JournalAnalysisService(store: store, intelligence: model)

        await service.analyze(day: day)
        await service.analyze(day: day)
        var analysisCount = await model.analysisCount
        XCTAssertEqual(analysisCount, 1)
        XCTAssertTrue(service.setEmotion(.joy, for: day))
        await service.regenerate(day: day)
        analysisCount = await model.analysisCount
        XCTAssertEqual(analysisCount, 2)
        XCTAssertEqual(service.overrides[day.key], .joy)

        let week = AnalysisPeriod.week(containing: day)
        await service.reflect(period: week)
        await service.reflect(period: week)
        var reflectionCount = await model.reflectionPrompts.count
        XCTAssertEqual(reflectionCount, 1)
        await service.regenerate(period: week)
        reflectionCount = await model.reflectionPrompts.count
        XCTAssertEqual(reflectionCount, 2)
        XCTAssertEqual(service.overrides[day.key], .joy)
    }

    @MainActor
    func testDailyConcurrentRequestsReuseCommittedCacheAndCorrections() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = JournalDay(key: "2026-10-01")!
        let entry = try store.create(day: day, body: "In-month walk with a friend.")
        let model = ServiceFixtureIntelligence(delay: .milliseconds(40))
        let service = JournalAnalysisService(store: store, intelligence: model)
        async let first: Void = service.analyze(day: day)
        async let second: Void = service.analyze(day: day)
        _ = await (first, second)
        let initialCalls = await model.analysisCount
        XCTAssertEqual(initialCalls, 1)
        XCTAssertEqual(service.daily[day.key]?.content.primaryEmotion, .peace)
        XCTAssertTrue(service.setEmotion(.joy, for: day))
        await service.analyze(day: day)
        let cachedCalls = await model.analysisCount
        XCTAssertEqual(cachedCalls, 1)
        try store.update(entry: entry, body: "In-month joyful walk.")
        await service.analyze(day: day)
        XCTAssertEqual(service.overrides[day.key], .joy)
        XCTAssertFalse(try XCTUnwrap(store.dailyAnalysis(for: day)).isStale)
    }

    @MainActor
    func testEditDuringInferenceDiscardsOldOutputAndRetriesLatestSnapshot() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = JournalDay(key: "2026-10-01")!
        let entry = try store.create(day: day, body: "Old synthetic account.")
        let gate = ServiceGateIntelligence()
        let service = JournalAnalysisService(store: store, intelligence: gate)
        let task = Task { await service.analyze(day: day) }
        await gate.waitForStart()
        try store.update(entry: entry, body: "New synthetic account.")
        await gate.resume()
        await task.value
        let saved = try XCTUnwrap(store.dailyAnalysis(for: day))
        XCTAssertEqual(saved.content.summary, "New synthetic account.")
        XCTAssertEqual(saved.sourceFingerprint,
                       AnalysisFingerprint.entries(try store.snapshots(from: day, through: day), version: JournalAnalysisService.version))
        let count = await gate.count
        XCTAssertEqual(count, 2)
    }

    @MainActor
    func testMonthlyClipsWeeksAndPreservesIndependentEventsAndCorrection() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let outside = JournalDay(key: "2026-09-30")!
        let inside = JournalDay(key: "2026-10-01")!
        _ = try store.create(day: outside, body: "Outside-month concert.")
        _ = try store.create(day: inside, body: "In-month walk with a friend.")
        try store.setEmotionOverride(.joy, for: inside)
        let model = ServiceFixtureIntelligence()
        let service = JournalAnalysisService(store: store, intelligence: model)
        service.loadStored()
        let month = AnalysisPeriod.month(containing: inside)
        await service.reflect(period: month)
        let saved = try XCTUnwrap(store.reflection(for: month))
        XCTAssertEqual(saved.content.importantEvents, ["2026-10-01: Walk with a friend"])
        let prompts = await model.reflectionPrompts
        XCTAssertFalse(prompts.isEmpty)
        XCTAssertTrue(prompts.allSatisfy { !$0.contains("Outside-month") && !$0.contains("2026-09-30") })
        XCTAssertTrue(prompts.contains { $0.contains("Joy") })
        let count = prompts.count
        await service.reflect(period: month)
        let cachedCount = await model.reflectionPrompts.count
        XCTAssertEqual(cachedCount, count)
        XCTAssertNil(try store.dailyAnalysis(for: outside))
        let clipped = month.clippedWeeks.first!
        XCTAssertEqual(clipped.firstDay.key, "2026-10-01")
        XCTAssertEqual(clipped.lastDay.key, "2026-10-04")
        XCTAssertNotNil(try store.reflection(for: clipped))
    }

    @MainActor
    func testConcurrentMonthlyAndClippedWeeklyRequestsShareGeneration() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = JournalDay(key: "2026-10-01")!
        _ = try store.create(day: day, body: "In-month walk.")
        let model = ServiceFixtureIntelligence(delay: .milliseconds(30))
        let service = JournalAnalysisService(store: store, intelligence: model)
        let month = AnalysisPeriod.month(containing: day)
        async let monthly: Void = service.reflect(period: month)
        async let weekly: Void = service.reflect(period: month.clippedWeeks.first!)
        _ = await (monthly, weekly)
        let prompts = await model.reflectionPrompts
        XCTAssertEqual(prompts.filter { $0.contains("Requested weekly period") }.count, 1)
        XCTAssertNotNil(try store.reflection(for: month))
    }

    func testCivilWeekBoundsIncludeEveryDateWithoutCrossingSupportedYears() {
        for key in ["0001-01-01", "9999-12-31", "2026-03-08", "2011-12-30"] {
            let day = JournalDay(key: key)!
            let week = AnalysisPeriod.week(containing: day)
            XCTAssertLessThanOrEqual(week.firstDay, day)
            XCTAssertGreaterThanOrEqual(week.lastDay, day)
            XCTAssertTrue(week.days.contains(day))
            XCTAssertLessThanOrEqual(week.days.count, 7)
        }
        let week = AnalysisPeriod.week(containing: JournalDay(key: "2026-10-01")!)
        XCTAssertEqual(week.firstDay.key, "2026-09-28")
        XCTAssertEqual(week.lastDay.key, "2026-10-04")
    }

    @MainActor
    func testUnavailableAndEmptySourcesKeepWritingAndAllowCorrections() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = JournalDay(key: "2026-10-01")!
        let model = ServiceFixtureIntelligence(available: false)
        let service = JournalAnalysisService(store: store, intelligence: model)
        await service.analyze(day: day)
        XCTAssertEqual(service.availability, .unavailable("Synthetic unavailable model"))
        XCTAssertNil(service.daily[day.key])
        let entry = try store.create(day: day, body: "Synthetic saved writing.")
        await service.analyzeChangedDays()
        let calls = await model.analysisCount
        XCTAssertEqual(calls, 0)
        XCTAssertEqual(entry.body, "Synthetic saved writing.")
        service.setEmotion(.peace, for: day)
        XCTAssertEqual(service.overrides[day.key], .peace)
        await service.reflect(period: .month(containing: day))
        XCTAssertNil(service.reflections[AnalysisPeriod.month(containing: day).key])
        let empty = JournalDay(key: "2026-11-01")!
        let period = AnalysisPeriod.month(containing: empty)
        await service.reflect(period: period)
        XCTAssertEqual(service.states[period.key], .failed(AnalysisError.emptySource.errorDescription!))
    }

    @MainActor
    func testFailedDerivedReadHidesOldInterpretationsAndPreservesWriting() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = JournalDay(key: "2026-10-01")!
        let entry = try store.create(day: day, body: "Committed synthetic writing.")
        let content = DailyAnalysisContent(summary: "A synthetic interpretation", primaryEmotion: .peace,
                                           secondaryEmotion: nil, importantEvents: [], emotionalTrajectory: "Uncertain")
        try store.saveDailyAnalysis(content, for: day,
                                    sourceFingerprint: AnalysisFingerprint.entries(try store.snapshots(from: day, through: day), version: 1), version: 1)
        try store.setEmotionOverride(.joy, for: day)
        let service = JournalAnalysisService(store: store, intelligence: ServiceFixtureIntelligence())
        service.loadStored()
        XCTAssertNotNil(service.daily[day.key])
        let context = ModelContext(container)
        context.autosaveEnabled = false
        context.insert(DailyAnalysisRecord(dayKey: "2026-10-02", contentData: Data("corrupt".utf8),
                                           sourceFingerprint: "fixture", generatedAt: Date(), analysisVersion: 1))
        try context.save()
        try store.update(entry: entry, body: "Changed committed synthetic writing.")
        service.loadStored()
        XCTAssertTrue(service.daily.isEmpty)
        XCTAssertEqual(service.overrides[day.key], .joy)
        guard case .failed? = service.states["storage"] else { return XCTFail("Read failure should remain visible") }
        XCTAssertEqual(try store.entries(for: day).first?.body, "Changed committed synthetic writing.")
    }

    @MainActor
    func testDailyRetryRepairsCorruptPayloadWithoutChangingWritingOrCorrection() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = JournalDay(key: "2026-10-01")!
        let entry = try store.create(day: day, body: "Committed synthetic writing.")
        let original = try XCTUnwrap(store.snapshots(from: day, through: day).first)
        try store.setEmotionOverride(.joy, for: day)
        let fingerprint = AnalysisFingerprint.entries([original], version: JournalAnalysisService.version)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        context.insert(DailyAnalysisRecord(dayKey: day.key, contentData: Data("corrupt".utf8),
                                           sourceFingerprint: fingerprint, generatedAt: Date(),
                                           analysisVersion: JournalAnalysisService.version))
        try context.save()
        let model = ServiceFixtureIntelligence()
        let service = JournalAnalysisService(store: store, intelligence: model)
        service.loadStored()
        guard case .failed? = service.states["storage"] else {
            return XCTFail("Corrupt cached content should produce a visible read error.")
        }
        XCTAssertEqual(service.overrides[day.key], .joy)

        await service.analyze(day: day)

        let repaired = try XCTUnwrap(store.dailyAnalysis(for: day))
        try repaired.content.validate()
        XCTAssertFalse(repaired.isStale)
        XCTAssertEqual(repaired.sourceFingerprint, fingerprint)
        XCTAssertEqual(service.states["storage"], .idle)
        XCTAssertEqual(service.states[day.key], .idle)
        XCTAssertEqual(service.overrides[day.key], .joy)
        XCTAssertEqual(try store.emotionOverrides(from: day, through: day)[day.key], .joy)
        let unchanged = try XCTUnwrap(store.snapshots(from: day, through: day).first)
        XCTAssertEqual(unchanged.id, entry.id)
        XCTAssertEqual(unchanged.body, original.body)
        XCTAssertEqual(unchanged.createdAt, original.createdAt)
        XCTAssertEqual(unchanged.modifiedAt, original.modifiedAt)
        XCTAssertEqual(unchanged.createdTimeZoneIdentifier, original.createdTimeZoneIdentifier)
        let calls = await model.analysisCount
        XCTAssertEqual(calls, 1)
        let committed = ModelContext(container)
        var descriptor = FetchDescriptor<DailyAnalysisRecord>()
        descriptor.includePendingChanges = false
        XCTAssertEqual(try committed.fetch(descriptor).count, 1)
    }

    @MainActor
    func testPeriodRetryRepairsCorruptPayloadAndMetadataUsingCommittedCorrection() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = JournalDay(key: "2026-10-01")!
        _ = try store.create(day: day, body: "Committed synthetic writing.")
        let original = try XCTUnwrap(store.snapshots(from: day, through: day).first)
        try store.setEmotionOverride(.joy, for: day)
        let model = ServiceFixtureIntelligence()
        let service = JournalAnalysisService(store: store, intelligence: model)
        service.loadStored()
        let period = AnalysisPeriod.week(containing: day)
        await service.reflect(period: period)
        XCTAssertNotNil(try store.reflection(for: period))

        for corruptMetadata in [false, true] {
            let context = ModelContext(container)
            context.autosaveEnabled = false
            var descriptor = FetchDescriptor<ReflectionRecord>()
            descriptor.includePendingChanges = false
            let record = try XCTUnwrap(context.fetch(descriptor).first)
            if corruptMetadata {
                record.kindRawValue = "invalid"
                record.firstDayKey = "invalid"
                record.lastDayKey = "invalid"
            } else {
                record.contentData = Data("corrupt".utf8)
            }
            try context.save()
            service.loadStored()
            guard case .failed? = service.states["storage"] else {
                return XCTFail("Corrupt period data should produce a visible read error.")
            }
            XCTAssertTrue(service.reflections.isEmpty)
            XCTAssertEqual(service.overrides[day.key], .joy)
            XCTAssertThrowsError(try store.reflection(for: period))

            await service.reflect(period: period)

            let repaired = try XCTUnwrap(store.reflection(for: period))
            try repaired.content.validate()
            XCTAssertEqual(repaired.period, period)
            XCTAssertFalse(repaired.isStale)
            XCTAssertEqual(repaired.sourceFingerprint,
                           try store.reflectionFingerprint(for: period, version: JournalAnalysisService.version))
            XCTAssertEqual(service.states["storage"], .idle)
            XCTAssertEqual(service.states[period.key], .idle)
            XCTAssertEqual(service.overrides[day.key], .joy)
            let prompts = await model.reflectionPrompts
            XCTAssertTrue(try XCTUnwrap(prompts.last).contains("Joy"),
                          "Regeneration must use the saved correction even while display caches are hidden.")
        }

        let prompts = await model.reflectionPrompts
        XCTAssertEqual(prompts.count, 3)
        let dailyCalls = await model.analysisCount
        XCTAssertEqual(dailyCalls, 1)
        let unchanged = try XCTUnwrap(store.snapshots(from: day, through: day).first)
        XCTAssertEqual(unchanged.id, original.id)
        XCTAssertEqual(unchanged.body, original.body)
        XCTAssertEqual(unchanged.createdAt, original.createdAt)
        XCTAssertEqual(unchanged.modifiedAt, original.modifiedAt)
        XCTAssertEqual(try store.emotionOverrides(from: day, through: day)[day.key], .joy)
        let committed = ModelContext(container)
        var descriptor = FetchDescriptor<ReflectionRecord>()
        descriptor.includePendingChanges = false
        XCTAssertEqual(try committed.fetch(descriptor).count, 1)
    }

    @MainActor
    func testUnavailableModelKeepsCorruptPayloadAndVisibleReadError() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = JournalDay(key: "2026-10-01")!
        _ = try store.create(day: day, body: "Committed synthetic writing.")
        try store.setEmotionOverride(.joy, for: day)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        context.insert(DailyAnalysisRecord(dayKey: day.key, contentData: Data("corrupt".utf8),
                                           sourceFingerprint: "synthetic", generatedAt: Date(),
                                           analysisVersion: JournalAnalysisService.version))
        try context.save()
        let model = ServiceFixtureIntelligence(available: false)
        let service = JournalAnalysisService(store: store, intelligence: model)
        service.loadStored()

        await service.analyze(day: day)

        guard case .failed? = service.states["storage"] else {
            return XCTFail("Unavailable inference must not conceal the unresolved read failure.")
        }
        XCTAssertEqual(service.availability, .unavailable("Synthetic unavailable model"))
        XCTAssertEqual(service.overrides[day.key], .joy)
        let calls = await model.analysisCount
        XCTAssertEqual(calls, 0)
        XCTAssertThrowsError(try store.dailyAnalysis(for: day)) { error in
            XCTAssertTrue(error is DecodingError)
        }
        XCTAssertEqual(try store.entries(for: day).first?.body, "Committed synthetic writing.")
        XCTAssertEqual(try store.emotionOverrides(from: day, through: day)[day.key], .joy)
    }

    @MainActor
    func testReadOnlyCorrectionFailureReturnsFalseAndPreservesSavedChoiceForRetry() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("BearingsCorrectionResultTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("Journal.store")
        let day = JournalDay(key: "2026-10-01")!
        let writer = try PersistenceController.makeContainer(storeURL: url)
        let writerStore = JournalStore(context: writer.mainContext)
        _ = try writerStore.create(day: day, body: "Committed synthetic writing.")
        try writerStore.setEmotionOverride(.love, for: day)

        let schema = PersistenceController.schema
        let configuration = ModelConfiguration("BearingsReadOnlyCorrectionResultTests", schema: schema,
                                                url: url, allowsSave: false, cloudKitDatabase: .none)
        let reader = try ModelContainer(for: schema, configurations: [configuration])
        let store = JournalStore(context: reader.mainContext)
        let service = JournalAnalysisService(store: store, intelligence: ServiceFixtureIntelligence())
        service.loadStored()

        for _ in 0..<2 {
            XCTAssertFalse(service.setEmotion(.sadness, for: day))
            XCTAssertFalse(service.setEmotion(nil, for: day))
            guard case .failed? = service.states[day.key] else {
                return XCTFail("A failed correction operation must remain available to retry.")
            }
            XCTAssertEqual(service.overrides[day.key], .love)
            XCTAssertEqual(try store.emotionOverrides(from: day, through: day)[day.key], .love)
            XCTAssertEqual(try store.entries(for: day).first?.body, "Committed synthetic writing.")
            XCTAssertFalse(reader.mainContext.hasChanges)
        }
        // Successful operations report their result independently of display-cache equality.
        let writable = JournalAnalysisService(store: writerStore, intelligence: ServiceFixtureIntelligence())
        writable.loadStored()
        XCTAssertTrue(writable.setEmotion(.joy, for: day))
        XCTAssertEqual(writable.overrides[day.key], .joy)
        XCTAssertTrue(writable.setEmotion(nil, for: day))
        XCTAssertNil(writable.overrides[day.key])
        XCTAssertTrue(try writerStore.emotionOverrides(from: day, through: day).isEmpty)
    }

    @MainActor
    func testFailedCorrectionReadClearsOnlyUntrustedChoicesAndCanRetry() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = JournalDay(key: "2026-10-01")!
        _ = try store.create(day: day, body: "Committed synthetic writing.")
        try store.setEmotionOverride(.love, for: day)
        let service = JournalAnalysisService(store: store, intelligence: ServiceFixtureIntelligence())
        service.loadStored()
        await service.analyze(day: day)
        XCTAssertEqual(service.overrides[day.key], .love)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        var descriptor = FetchDescriptor<EmotionOverrideRecord>()
        descriptor.includePendingChanges = false
        let record = try XCTUnwrap(context.fetch(descriptor).first)
        record.emotionRawValue = "unsupported"
        try context.save()

        service.loadStored()

        XCTAssertTrue(service.overrides.isEmpty)
        XCTAssertNotNil(service.daily[day.key])
        guard case .failed? = service.states["storage"] else {
            return XCTFail("An authoritative correction read error should remain visible.")
        }
        record.emotionRawValue = JournalEmotion.love.rawValue
        try context.save()
        service.loadStored()
        XCTAssertEqual(service.overrides[day.key], .love)
        XCTAssertNotNil(service.daily[day.key])
        XCTAssertEqual(service.states["storage"], .idle)
    }

    @MainActor
    func testCancellationDoesNotPersistUnfinishedInterpretation() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = JournalDay(key: "2026-10-01")!
        _ = try store.create(day: day, body: "Old synthetic account.")
        _ = store.takeChangedDays()
        let gate = ServiceGateIntelligence()
        let service = JournalAnalysisService(store: store, intelligence: gate)
        let task = Task { await service.analyze(day: day) }
        await gate.waitForStart()
        service.cancel()
        await gate.resume()
        await task.value
        XCTAssertNil(try store.dailyAnalysis(for: day))
        XCTAssertEqual(service.states[day.key], .idle)
        await service.analyzeChangedDays()
        XCTAssertNotNil(try store.dailyAnalysis(for: day), "Canceled work must remain queued for foreground retry.")
    }
}

private actor ServiceFixtureIntelligence: JournalIntelligence {
    let delay: Duration
    let available: Bool
    private(set) var analysisCount = 0
    private(set) var reflectionPrompts: [String] = []
    init(delay: Duration = .zero, available: Bool = true) { self.delay = delay; self.available = available }
    func availability() async -> IntelligenceAvailability { available ? .available : .unavailable("Synthetic unavailable model") }
    func analyze(_ text: String) async throws -> DailyAnalysisContent {
        analysisCount += 1
        try await Task.sleep(for: delay)
        return DailyAnalysisContent(summary: "Walk with a friend", primaryEmotion: .peace, secondaryEmotion: .love,
                                    importantEvents: ["Walk with a friend"], emotionalTrajectory: "Perhaps peaceful")
    }
    func reflect(_ text: String, kind: ReflectionKind) async throws -> ReflectionContent {
        reflectionPrompts.append(text)
        return ReflectionContent(overview: "A remembered walk", importantEvents: ["Walk"], emotionalThemes: "Peace",
                                 relationships: "Friend", interests: "Walking", changes: "Insufficient information")
    }
}

private actor ServiceGateIntelligence: JournalIntelligence {
    private var continuation: CheckedContinuation<Void, Never>?
    private var startedWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var count = 0
    func availability() async -> IntelligenceAvailability { .available }
    func analyze(_ text: String) async throws -> DailyAnalysisContent {
        count += 1
        if count == 1 {
            await withCheckedContinuation { continuation in
                self.continuation = continuation
                for waiter in startedWaiters { waiter.resume() }
                startedWaiters.removeAll()
            }
        }
        return DailyAnalysisContent(summary: text.contains("New synthetic") ? "New synthetic account." : "Old synthetic account.",
                                    primaryEmotion: .uncertain, secondaryEmotion: nil, importantEvents: [],
                                    emotionalTrajectory: "Unclear")
    }
    func waitForStart() async {
        if continuation != nil { return }
        await withCheckedContinuation { startedWaiters.append($0) }
    }
    func resume() { continuation?.resume(); continuation = nil }
    func reflect(_ text: String, kind: ReflectionKind) async throws -> ReflectionContent { throw AnalysisError.generationFailed }
}
