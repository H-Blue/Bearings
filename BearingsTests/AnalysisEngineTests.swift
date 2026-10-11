import Foundation
import SwiftData
import XCTest
@testable import Bearings

final class AnalysisEngineTests: XCTestCase {
    func testUnicodeChunksPreserveEveryByteAndRespectBudget() {
        // One grapheme is deliberately larger than any chunk budget.
        let largeGrapheme = "e" + String(repeating: "\u{0301}", count: 3_000)
        let source = "A quiet walk. 日本語 한국어 🧭👩🏽‍💻\n" + largeGrapheme + "\nLast event."
        for budget in [4, 17, 128, JournalAnalysisEngine.inputByteBudget] {
            let chunks = JournalAnalysisEngine.chunks(source, byteLimit: budget)
            XCTAssertEqual(Array(chunks.joined().utf8), Array(source.utf8))
            XCTAssertTrue(chunks.allSatisfy { !$0.isEmpty && $0.utf8.count <= budget })
        }
        XCTAssertTrue(JournalAnalysisEngine.chunks("").isEmpty)
    }

    @MainActor
    func testLongCommittedEntriesProcessEveryChunkAndRetainExtractedEvents() async throws {
        let body = String(repeating: SyntheticJournalSamples.variedDay + "\n", count: 80)
        let entries = try committedSnapshots([body, "I felt peaceful after a walk."])
        let mock = EngineMockIntelligence()
        let engine = JournalAnalysisEngine(intelligence: mock)

        let result = try await engine.analyze(entries: Array(entries.reversed()))
        let stats = await mock.statistics()
        let sourceChunks = stats.analyzedSources.map { text in
            String(text.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)[1])
        }
        XCTAssertGreaterThan(sourceChunks.count, entries.count)
        XCTAssertEqual(Array(sourceChunks.joined().utf8), Array(entries.map(\.body).joined().utf8))
        XCTAssertEqual(Set(result.importantEvents),
                       Set(stats.sourceEvents + ["A shared factual event"]))
        XCTAssertFalse(result.importantEvents.contains("Merge-only event"))
        try result.validate()
    }

    func testAdaptiveContextSubdivisionProcessesAllReflectionText() async throws {
        let source = String(repeating: "I called a friend and felt connected. ", count: 100)
        let mock = EngineMockIntelligence(mode: .contextLimit(800))
        let engine = JournalAnalysisEngine(intelligence: mock)

        let result = try await engine.reflect(text: source, kind: .weekly)
        let stats = await mock.statistics()
        XCTAssertTrue(stats.reflectionAttempts.contains { $0.utf8.count > 800 })
        XCTAssertGreaterThan(stats.reflectedSources.count, 1)
        XCTAssertEqual(Array(stats.reflectedSources.joined().utf8), Array(source.utf8))
        XCTAssertTrue(stats.reflectedSources.allSatisfy { $0.utf8.count <= 800 })
        XCTAssertEqual(Set(result.importantEvents), Set(stats.sourceEvents + ["A shared factual event"]))
    }

    func testIrreducibleContextErrorIsExplicit() async throws {
        let mock = EngineMockIntelligence(mode: .contextLimit(0))
        let engine = JournalAnalysisEngine(intelligence: mock)
        do {
            _ = try await engine.reflect(text: "A small journal.", kind: .monthly)
            XCTFail("An irreducible context error should be returned.")
        } catch {
            XCTAssertEqual(error as? AnalysisError, .contextTooLarge)
        }
        let stats = await mock.statistics()
        XCTAssertEqual(stats.reflectionAttempts.count, 1)
    }

    @MainActor
    func testUnavailableProviderExplainsStateWithoutInvokingGeneration() async throws {
        let entries = try committedSnapshots(["I felt sad when my friend moved away."])
        let mock = EngineMockIntelligence(mode: .unavailable)
        let engine = JournalAnalysisEngine(intelligence: mock)
        let availability = await engine.availability()
        XCTAssertEqual(availability, .unavailable("Synthetic device unavailable"))
        do {
            _ = try await engine.analyze(entries: entries)
            XCTFail("An unavailable provider should not generate a daily analysis.")
        } catch {
            XCTAssertEqual(error as? AnalysisError, .generationFailed)
        }
        do {
            _ = try await engine.reflect(text: "A period of writing.", kind: .weekly)
            XCTFail("An unavailable provider should not generate a reflection.")
        } catch {
            XCTAssertEqual(error as? AnalysisError, .generationFailed)
        }
        let stats = await mock.statistics()
        XCTAssertTrue(stats.analysisAttempts.isEmpty)
        XCTAssertTrue(stats.reflectionAttempts.isEmpty)
    }

    @MainActor
    func testEmptyCommittedSourcesDoNotInvokeGeneration() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = try XCTUnwrap(JournalDay(key: "2026-10-11"))
        let entry = try store.create(day: day, body: "A draft before clearing.")
        try store.update(entry: entry, body: " \n\t")
        let snapshots = try store.snapshots(from: day, through: day)
        let mock = EngineMockIntelligence()
        let engine = JournalAnalysisEngine(intelligence: mock)
        for source in [snapshots, []] {
            do {
                _ = try await engine.analyze(entries: source)
                XCTFail("Blank daily sources should be rejected.")
            } catch {
                XCTAssertEqual(error as? AnalysisError, .emptySource)
            }
        }
        do {
            _ = try await engine.reflect(text: " \n\t", kind: .weekly)
            XCTFail("A blank reflection source should be rejected.")
        } catch {
            XCTAssertEqual(error as? AnalysisError, .emptySource)
        }
        let stats = await mock.statistics()
        XCTAssertTrue(stats.analysisAttempts.isEmpty)
        XCTAssertTrue(stats.reflectionAttempts.isEmpty)
    }

    func testStructuredResultsRoundTripAndRejectUnknownEmotion() throws {
        let original = DailyAnalysisContent(
            summary: "A quiet walk brought some peace after a difficult morning.",
            primaryEmotion: .peace,
            secondaryEmotion: .sadness,
            importantEvents: ["Walked outside"],
            emotionalTrajectory: "Sadness, then some peace."
        )
        let data = try JSONEncoder().encode(original)
        XCTAssertEqual(try JSONDecoder().decode(DailyAnalysisContent.self, from: data), original)
        XCTAssertEqual(original.notableEmotions, [.peace, .sadness])
        XCTAssertEqual(DailyAnalysisContent(summary: "A day without a stated feeling.",
                                            primaryEmotion: .uncertain,
                                            secondaryEmotion: nil,
                                            importantEvents: [],
                                            emotionalTrajectory: "No clear emotional change was expressed.").notableEmotions,
                       [])
        XCTAssertEqual(DailyAnalysisContent(summary: "A peaceful day.",
                                            primaryEmotion: .peace,
                                            secondaryEmotion: .peace,
                                            importantEvents: [],
                                            emotionalTrajectory: "Peace remained steady.").notableEmotions,
                       [.peace])
        let invalid = String(decoding: data, as: UTF8.self)
            .replacingOccurrences(of: "\"peace\"", with: "\"unsupportedDiagnosis\"")
        XCTAssertThrowsError(try JSONDecoder().decode(DailyAnalysisContent.self,
                                                     from: Data(invalid.utf8)))
        XCTAssertEqual(Set(JournalEmotion.allCases.map(\.rawValue)),
                       ["joy", "peace", "sadness", "anger", "fear", "loneliness", "love", "uncertain"])
    }

    func testValidationRejectsBlankSummaryTrajectoryAndEvent() {
        let valid = DailyAnalysisContent(summary: "A synthetic day.", primaryEmotion: .uncertain,
                                         secondaryEmotion: nil, importantEvents: [],
                                         emotionalTrajectory: "The feelings are unclear.")
        var invalid = valid
        invalid.summary = " \n"
        XCTAssertThrowsError(try invalid.validate())
        invalid = valid
        invalid.emotionalTrajectory = "\t"
        XCTAssertThrowsError(try invalid.validate())
        invalid = valid
        invalid.importantEvents = [" "]
        XCTAssertThrowsError(try invalid.validate())
    }

    func testEmotionalZoomRequiresGroundedExcerptAndQuestion() throws {
        let source = "I feel bad about the thing that happened."
        let valid = EmotionalZoomContent(vagueExcerpt: "I feel bad",
                                         explanation: "The phrase does not identify the feeling or event.",
                                         probingQuestion: "What happened, and what feeling fits it most closely?")
        XCTAssertNoThrow(try valid.validate(source: source))
        XCTAssertThrowsError(try EmotionalZoomContent(vagueExcerpt: "Words not in the draft",
                                                       explanation: valid.explanation,
                                                       probingQuestion: valid.probingQuestion).validate(source: source))
        XCTAssertThrowsError(try EmotionalZoomContent(vagueExcerpt: " ", explanation: valid.explanation,
                                                       probingQuestion: valid.probingQuestion).validate(source: source))
        XCTAssertThrowsError(try EmotionalZoomContent(vagueExcerpt: nil, explanation: " ",
                                                       probingQuestion: valid.probingQuestion).validate(source: source))
        XCTAssertThrowsError(try EmotionalZoomContent(vagueExcerpt: nil, explanation: valid.explanation,
                                                       probingQuestion: "\n").validate(source: source))
    }

    func testEmotionalZoomDropsParaphrasedExcerptWithoutDiscardingUsefulResponse() throws {
        let source = "I want to hear the full timeline before responding."
        let content = EmotionalZoomContent.groundedModelOutput(
            vagueExcerpt: "I want to hear everything before I respond.",
            explanation: "The writer names a concrete plan and could consider what listening looks like in the moment.",
            probingQuestion: "How will you know that you heard the full timeline?",
            source: source
        )

        XCTAssertNil(content.vagueExcerpt)
        XCTAssertEqual(content.explanation, "The writer names a concrete plan and could consider what listening looks like in the moment.")
        XCTAssertEqual(content.probingQuestion, "How will you know that you heard the full timeline?")
        XCTAssertNoThrow(try content.validate(source: source))
    }

    func testEmotionalZoomRepairsEmptyRequiredFieldsWithNeutralPrompts() throws {
        let source = "I want to hear the full timeline before responding."
        let content = EmotionalZoomContent.groundedModelOutput(
            vagueExcerpt: nil,
            explanation: " \n",
            probingQuestion: "\t",
            source: source
        )

        XCTAssertNil(content.vagueExcerpt)
        XCTAssertEqual(content.explanation, "No exact passage was highlighted from this writing.")
        XCTAssertEqual(content.probingQuestion, "What detail feels most important to explore further?")
        XCTAssertNoThrow(try content.validate(source: source))
    }

    func testEmotionalZoomPreservesExactGroundedExcerpt() throws {
        let source = "I feel bad about the thing that happened."
        let content = EmotionalZoomContent.groundedModelOutput(
            vagueExcerpt: "  I feel bad  ",
            explanation: "The feeling and event are not yet specific.",
            probingQuestion: "What happened, and what feeling fits it most closely?",
            source: source
        )

        XCTAssertEqual(content.vagueExcerpt, "I feel bad")
        XCTAssertNoThrow(try content.validate(source: source))
    }

    func testEmotionalZoomProcessesEveryDraftChunkAndReturnsGroundedAmbiguity() async throws {
        let source = String(repeating: "A specific synthetic detail. ", count: 120) + "I feel bad about the thing."
        let mock = ZoomMockIntelligence()
        let engine = JournalAnalysisEngine(intelligence: mock)

        let result = try await engine.emotionalZoom(text: source)
        let inputs = await mock.inputs
        XCTAssertGreaterThan(inputs.count, 1)
        XCTAssertEqual(Array(inputs.joined().utf8), Array(source.utf8))
        XCTAssertEqual(result.vagueExcerpt, "I feel bad")
        try result.validate(source: source)
    }

    func testWeeklyPipelineExtractsGroundedSignalsBeforeInsufficientEvidenceReflection() async throws {
        let period = AnalysisPeriod.week(containing: try XCTUnwrap(JournalDay(key: "2026-10-06")))
        let evidence = "CURRENT DAY 2026-10-06\nI planned to finish the draft. Private raw detail."
        let mock = WeeklyPipelineMock()
        let engine = JournalAnalysisEngine(intelligence: mock)

        let result = try await engine.reflectWeekly(evidence: evidence, period: period)
        let calls = await mock.calls()

        XCTAssertEqual(calls.extractions.count, 1)
        XCTAssertTrue(calls.extractions[0].contains("I planned to finish the draft."))
        XCTAssertEqual(calls.compositions.count, 1)
        XCTAssertTrue(calls.compositions[0].contains("Explicit goals or intentions"))
        XCTAssertTrue(calls.compositions[0].contains("Finish the draft."))
        XCTAssertFalse(calls.compositions[0].contains("Private raw detail"),
                       "The final writing stage should receive only the compact signal packet.")
        XCTAssertEqual(result.importantEvents, ["2026-10-06: The writer planned to finish the draft."])
        XCTAssertEqual(result.weeklyDetails?.lessonReadiness, .insufficientEvidence)
        XCTAssertEqual(result.weeklyDetails?.reflectionQuestion, "What would show that the draft is moving forward?")
    }

    func testWeeklyPipelineRejectsUngroundedExtractionAndUnsupportedReadinessEvidence() async throws {
        let period = AnalysisPeriod.week(containing: try XCTUnwrap(JournalDay(key: "2026-10-06")))
        let evidence = "CURRENT DAY 2026-10-06\nI planned to finish the draft."
        for mode in [WeeklyPipelineMock.Mode.ungroundedExtraction, .unsupportedReadinessEvidence] {
            let engine = JournalAnalysisEngine(intelligence: WeeklyPipelineMock(mode: mode))
            do {
                _ = try await engine.reflectWeekly(evidence: evidence, period: period)
                XCTFail("Unsupported weekly claims must be rejected.")
            } catch {
                XCTAssertEqual(error as? AnalysisError, .invalidOutput)
            }
        }
    }

    @MainActor
    func testEngineRejectsMalformedProviderOutput() async throws {
        let entries = try committedSnapshots(["I felt uncertain about a difficult day."])
        let mock = EngineMockIntelligence(mode: .invalidOutput)
        let engine = JournalAnalysisEngine(intelligence: mock)
        do {
            _ = try await engine.analyze(entries: entries)
            XCTFail("An empty generated summary should not be accepted.")
        } catch {
            XCTAssertEqual(error as? AnalysisError, .invalidOutput)
        }
        do {
            _ = try await engine.reflect(text: "Some writing.", kind: .monthly)
            XCTFail("An empty generated overview should not be accepted.")
        } catch {
            XCTAssertEqual(error as? AnalysisError, .invalidOutput)
        }
    }

    @MainActor
    func testInferenceIsSerializedAcrossDailyAndReflectionRequests() async throws {
        let entries = try committedSnapshots(["I loved spending time with my family."])
        let mock = EngineMockIntelligence(mode: .delayed(25_000_000))
        let engine = JournalAnalysisEngine(intelligence: mock)
        async let first = engine.analyze(entries: entries)
        async let second = engine.reflect(text: "A peaceful week.", kind: .weekly)
        async let third = engine.analyze(entries: entries)
        _ = try await (first, second, third)
        let stats = await mock.statistics()
        XCTAssertEqual(stats.maximumConcurrentRequests, 1)
        XCTAssertEqual(stats.analysisAttempts.count + stats.reflectionAttempts.count, 3)
    }

    @MainActor
    func testCancellationPropagatesAndReleasesInferenceQueue() async throws {
        let entries = try committedSnapshots(["I worried about a new job."])
        let mock = EngineMockIntelligence(mode: .delayed(100_000_000))
        let engine = JournalAnalysisEngine(intelligence: mock)
        let task = Task { try await engine.analyze(entries: entries) }
        await mock.waitForFirstStart()
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Canceled generation should not be returned.")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        _ = try await engine.reflect(text: "A quiet week.", kind: .weekly)
        let stats = await mock.statistics()
        XCTAssertEqual(stats.maximumConcurrentRequests, 1)
        XCTAssertEqual(stats.reflectionAttempts.count, 1)
    }

    @MainActor
    func testCanceledQueuedRequestDoesNotInvokeModel() async throws {
        let entries = try committedSnapshots(["I felt joyful after meeting an old friend."])
        let mock = EngineMockIntelligence(mode: .blockingFirst)
        let engine = JournalAnalysisEngine(intelligence: mock)
        let first = Task { try await engine.analyze(entries: entries) }
        await mock.waitForFirstStart()
        let queued = Task { try await engine.analyze(entries: entries) }
        queued.cancel()
        await mock.releaseFirst()
        _ = try await first.value
        do {
            _ = try await queued.value
            XCTFail("A canceled queued task should not generate.")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        let stats = await mock.statistics()
        XCTAssertEqual(stats.analysisAttempts.count, 1)
    }

    @MainActor
    func testOversizedAggregationFailsExplicitlyWithoutDroppingSegments() async throws {
        let entries = try committedSnapshots([String(repeating: "A", count: 2_500)])
        let mock = EngineMockIntelligence(mode: .oversizedOutput)
        let engine = JournalAnalysisEngine(intelligence: mock)
        do {
            _ = try await engine.analyze(entries: entries)
            XCTFail("An aggregation that cannot compact should fail explicitly.")
        } catch {
            XCTAssertEqual(error as? AnalysisError, .contextTooLarge)
        }
        let stats = await mock.statistics()
        XCTAssertEqual(stats.analyzedSources.count, 2)
    }

    @MainActor
    private func committedSnapshots(_ bodies: [String]) throws -> [JournalEntrySnapshot] {
        let container = try PersistenceController.makeContainer(inMemory: true)
        var clock = Date(timeIntervalSince1970: 1_792_000_000)
        let store = JournalStore(context: container.mainContext, now: { clock })
        let day = try XCTUnwrap(JournalDay(key: "2026-10-11"))
        for body in bodies {
            _ = try store.create(day: day, body: body)
            clock = clock.addingTimeInterval(60)
        }
        return try store.snapshots(from: day, through: day)
    }
}

private actor WeeklyPipelineMock: JournalIntelligence {
    enum Mode: Equatable { case valid, ungroundedExtraction, unsupportedReadinessEvidence }
    private let mode: Mode
    private var extractionInputs: [String] = []
    private var compositionInputs: [String] = []

    init(mode: Mode = .valid) { self.mode = mode }

    func availability() async -> IntelligenceAvailability { .available }
    func analyze(_ text: String) async throws -> DailyAnalysisContent { throw AnalysisError.generationFailed }
    func reflect(_ text: String, kind: ReflectionKind) async throws -> ReflectionContent { throw AnalysisError.generationFailed }

    func extractWeeklySignals(_ text: String) async throws -> WeeklySignals {
        extractionInputs.append(text)
        let excerpt = mode == .ungroundedExtraction ? "Words absent from evidence" : "I planned to finish the draft."
        let signal = GroundedWeeklySignal(statement: "Finish the draft.", evidenceExcerpt: excerpt)
        return WeeklySignals(
            focusAreas: [signal],
            importantEvents: [DatedWeeklyEvent(dayKey: "2026-10-06",
                                                statement: "The writer planned to finish the draft.",
                                                evidenceExcerpt: excerpt)],
            explicitGoals: [signal], progress: [], obstacles: [], unfinishedThreads: [],
            emotionalChanges: [], precedingWeekContinuity: []
        )
    }

    func composeWeeklyReflection(_ text: String) async throws -> ReflectionContent {
        compositionInputs.append(text)
        let readiness: LessonReadiness = mode == .unsupportedReadinessEvidence
            ? .readyForNewChallenge : .insufficientEvidence
        return ReflectionContent(
            overview: "The writer planned to finish a draft.", importantEvents: [], emotionalThemes: "No emotional change was supported.",
            relationships: "", interests: "", changes: "",
            weeklyDetails: WeeklyReflectionDetails(
                workFocus: "Finishing the draft.",
                progressAndUnfinished: "The draft remained an explicit intention; progress was not documented.",
                whatHelped: "There was insufficient evidence about what helped.",
                realisticImprovement: "There is insufficient evidence for a specific improvement.",
                lessonReadiness: readiness,
                readinessEvidence: mode == .unsupportedReadinessEvidence ? ["Unsupported progress claim."] : [],
                reflectionQuestion: mode == .unsupportedReadinessEvidence
                    ? nil : "What would show that the draft is moving forward?"
            )
        )
    }

    func calls() -> (extractions: [String], compositions: [String]) {
        (extractionInputs, compositionInputs)
    }
}

private actor ZoomMockIntelligence: JournalIntelligence {
    private(set) var inputs: [String] = []

    func availability() async -> IntelligenceAvailability { .available }
    func analyze(_ text: String) async throws -> DailyAnalysisContent { throw AnalysisError.generationFailed }
    func reflect(_ text: String, kind: ReflectionKind) async throws -> ReflectionContent { throw AnalysisError.generationFailed }
    func emotionalZoom(_ text: String) async throws -> EmotionalZoomContent {
        inputs.append(text)
        let excerpt = text.contains("I feel bad") ? "I feel bad" : nil
        return EmotionalZoomContent(
            vagueExcerpt: excerpt,
            explanation: excerpt == nil ? "This segment is specific." : "The feeling and event are not yet specific.",
            probingQuestion: "What detail would make this clearer to you?"
        )
    }
}

/// Synthetic material only; this fixture exercises input plumbing, not model quality.
private enum SyntheticJournalSamples {
    static let variedDay = """
        I felt joyful when lunch with my friend reminded me of our old neighborhood.
        I felt sad after hearing that another friend was moving away.
        The crowded train annoyed me, and I was afraid I would arrive late.
        Later I called my sister, felt loved, and enjoyed a peaceful walk.
        I still felt lonely at home and uncertain about tomorrow.
        """
}

private actor EngineMockIntelligence: JournalIntelligence {
    enum Mode: Sendable {
        case normal, unavailable, invalidOutput, blockingFirst, oversizedOutput
        case contextLimit(Int)
        case delayed(UInt64)
    }

    struct Statistics: Sendable {
        let analysisAttempts: [String]
        let reflectionAttempts: [String]
        let analyzedSources: [String]
        let reflectedSources: [String]
        let sourceEvents: [String]
        let maximumConcurrentRequests: Int
    }

    private let mode: Mode
    private var analysisAttempts: [String] = []
    private var reflectionAttempts: [String] = []
    private var analyzedSources: [String] = []
    private var reflectedSources: [String] = []
    private var sourceEvents: [String] = []
    private var concurrentRequests = 0
    private var maximumConcurrentRequests = 0
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var firstRelease: CheckedContinuation<Void, Never>?
    private var hasStarted = false

    init(mode: Mode = .normal) { self.mode = mode }

    func availability() async -> IntelligenceAvailability {
        if case .unavailable = mode { return .unavailable("Synthetic device unavailable") }
        return .available
    }

    func analyze(_ text: String) async throws -> DailyAnalysisContent {
        analysisAttempts.append(text)
        beginRequest()
        defer { concurrentRequests -= 1 }
        try await prepare(text)
        let isSource = text.hasPrefix("Journal day ")
        var events = ["Merge-only event"]
        if isSource {
            analyzedSources.append(text)
            let event = "Source event \(sourceEvents.count + 1)"
            sourceEvents.append(event)
            events = [event, "A shared factual event"]
        }
        let summary: String
        switch mode {
        case .invalidOutput: summary = ""
        case .oversizedOutput: summary = String(repeating: "Unsupported verbosity. ", count: 400)
        default: summary = "A synthetic day."
        }
        return DailyAnalysisContent(summary: summary, primaryEmotion: .uncertain, secondaryEmotion: .peace,
                                    importantEvents: events, emotionalTrajectory: "Mixed, then peaceful.")
    }

    func reflect(_ text: String, kind: ReflectionKind) async throws -> ReflectionContent {
        reflectionAttempts.append(text)
        beginRequest()
        defer { concurrentRequests -= 1 }
        try await prepare(text)
        var events = ["Merge-only event"]
        if !text.hasPrefix("Combine these reflection segments.") {
            reflectedSources.append(text)
            let event = "Source event \(sourceEvents.count + 1)"
            sourceEvents.append(event)
            events = [event, "A shared factual event"]
        }
        let overview: String
        switch mode {
        case .invalidOutput: overview = ""
        case .oversizedOutput: overview = String(repeating: "Unsupported verbosity. ", count: 400)
        default: overview = "A synthetic period."
        }
        return ReflectionContent(overview: overview, importantEvents: events, emotionalThemes: "Mixed.",
                                 relationships: "A friend.", interests: "Walking.", changes: "Unclear.")
    }

    func statistics() -> Statistics {
        Statistics(analysisAttempts: analysisAttempts, reflectionAttempts: reflectionAttempts,
                   analyzedSources: analyzedSources, reflectedSources: reflectedSources,
                   sourceEvents: sourceEvents, maximumConcurrentRequests: maximumConcurrentRequests)
    }

    func waitForFirstStart() async {
        if hasStarted { return }
        await withCheckedContinuation { startWaiters.append($0) }
    }

    func releaseFirst() { firstRelease?.resume(); firstRelease = nil }

    private func beginRequest() {
        concurrentRequests += 1
        maximumConcurrentRequests = max(maximumConcurrentRequests, concurrentRequests)
        if !hasStarted {
            hasStarted = true
            startWaiters.forEach { $0.resume() }
            startWaiters.removeAll()
        }
    }

    private func prepare(_ text: String) async throws {
        switch mode {
        case .contextLimit(let bytes) where text.utf8.count > bytes:
            throw AnalysisError.contextTooLarge
        case .oversizedOutput where text.utf8.count > JournalAnalysisEngine.inputByteBudget:
            throw AnalysisError.contextTooLarge
        case .delayed(let duration):
            try await Task.sleep(nanoseconds: duration)
        case .blockingFirst where analysisAttempts.count + reflectionAttempts.count == 1:
            await withCheckedContinuation { firstRelease = $0 }
        default: break
        }
        try Task.checkCancellation()
    }
}
