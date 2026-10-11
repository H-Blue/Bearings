import Foundation
import Observation

enum AnalysisState: Equatable {
    case idle, loading, failed(String)
}

/// Coordinates committed local snapshots, cache reuse, and cancellable inference.
/// No generation is triggered by editor keystrokes or the timeline's color reads.
@MainActor
@Observable
final class JournalAnalysisService {
    static let version = 3
    private(set) var availability: IntelligenceAvailability = .unavailable("Checking on-device reflections…")
    private(set) var daily: [String: StoredDailyAnalysis] = [:]
    private(set) var reflections: [String: StoredReflection] = [:]
    private(set) var overrides: [String: JournalEmotion] = [:]
    private(set) var states: [String: AnalysisState] = [:]
    @ObservationIgnored private let store: JournalStore
    @ObservationIgnored private let engine: JournalAnalysisEngine
    @ObservationIgnored private var tasks: [String: Task<Void, Never>] = [:]
    @ObservationIgnored private var reflectionTasks: [String: Task<StoredReflection?, Error>] = [:]
    @ObservationIgnored private var pendingDays = Set<JournalDay>()

    init(store: JournalStore, intelligence: any JournalIntelligence) {
        self.store = store
        engine = JournalAnalysisEngine(intelligence: intelligence)
    }

    func loadStored() {
        let first = JournalDay(key: "0001-01-01")!
        let last = JournalDay(key: "9999-12-31")!
        var readFailed = false
        // Manual corrections have their own authoritative read. Unreadable AI
        // interpretations must not hide a successfully loaded user choice.
        do {
            overrides = try store.emotionOverrides(from: first, through: last)
        } catch {
            overrides = [:]
            readFailed = true
        }
        do {
            daily = Dictionary(uniqueKeysWithValues: try store.dailyAnalyses(from: first, through: last).map { ($0.dayKey, $0) })
            for key in Array(reflections.keys) {
                if let value = reflections[key] { reflections[key] = try store.reflection(for: value.period) }
            }
        } catch {
            // A failed authoritative read must not leave an old interpretation
            // looking current after its source changes. Saved records are untouched.
            daily = [:]; reflections = [:]
            readFailed = true
        }
        states["storage"] = readFailed
            ? .failed("Your saved reflections couldn’t load. Try again when your device is unlocked.")
            : .idle
    }

    func analyze(day: JournalDay) async {
        await analyze(day: day, reuseCache: true)
    }

    func regenerate(day: JournalDay) async {
        await analyze(day: day, reuseCache: false)
    }

    private func analyze(day: JournalDay, reuseCache: Bool) async {
        let key = day.key
        if let task = tasks[key] { await task.value; return }
        let task = Task { await runDaily(day, reuseCache: reuseCache) }
        tasks[key] = task
        await task.value
        tasks[key] = nil
    }

    func reflect(period: AnalysisPeriod) async {
        _ = try? await requestReflection(period, reuseCache: true)
    }

    func regenerate(period: AnalysisPeriod) async {
        _ = try? await requestReflection(period, reuseCache: false)
    }

    func emotionalZoom(text: String) async throws -> EmotionalZoomContent {
        availability = await engine.availability()
        guard availability == .available else { throw AnalysisError.generationFailed }
        return try await engine.emotionalZoom(text: text)
    }

    private func requestReflection(_ period: AnalysisPeriod, reuseCache: Bool = true) async throws -> StoredReflection? {
        let key = period.key
        if let task = reflectionTasks[key] { return try await task.value }
        let task = Task<StoredReflection?, Error> {
            do { return try await generateReflection(period, reuseCache: reuseCache) }
            catch is CancellationError { states[key] = .idle; throw CancellationError() }
            catch { states[key] = .failed(Self.safeMessage(error)); throw error }
        }
        reflectionTasks[key] = task
        defer { reflectionTasks[key] = nil }
        return try await task.value
    }

    @discardableResult
    func setEmotion(_ emotion: JournalEmotion?, for day: JournalDay) -> Bool {
        do {
            try store.setEmotionOverride(emotion, for: day)
            loadStored()
            states[day.key] = .idle
            return true
        } catch {
            states[day.key] = .failed("Your emotion correction couldn’t be saved. Try again.")
            return false
        }
    }

    func analyzeChangedDays() async {
        pendingDays.formUnion(store.takeChangedDays())
        for day in pendingDays.sorted() {
            guard !Task.isCancelled else { return }
            await analyze(day: day)
            guard !Task.isCancelled else { return }
            if states[day.key] == .idle && availability == .available { pendingDays.remove(day) }
        }
    }

    func cancel() {
        for task in tasks.values { task.cancel() }
        for task in reflectionTasks.values { task.cancel() }
        // Keep task identities until their callers finish, preventing replacement
        // tasks from being removed by an older completion.
    }

    private func runDaily(_ day: JournalDay, reuseCache: Bool) async {
        let key = day.key
        do {
            availability = await engine.availability()
            for attempt in 0..<2 {
                try Task.checkCancellation()
                let snapshots = try store.snapshots(from: day, through: day)
                guard snapshots.contains(where: { !$0.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
                    daily[key] = nil; states[key] = .idle; return
                }
                let fingerprint = AnalysisFingerprint.entries(snapshots, version: Self.version)
                let cached = try selectedDerivedCache { try store.dailyAnalysis(for: day) }
                if reuseCache, let cached,
                   !cached.isStale, cached.analysisVersion == Self.version, cached.sourceFingerprint == fingerprint {
                    daily[key] = cached; states[key] = .idle
                    availability = await engine.availability()
                    return
                }
                if case nil = cached { daily[key] = nil }
                availability = await engine.availability()
                guard availability == .available else { states[key] = .idle; return }
                states[key] = .loading
                let content = try await engine.analyze(entries: snapshots)
                try Task.checkCancellation()
                do {
                    try store.saveDailyAnalysis(content, for: day, sourceFingerprint: fingerprint, version: Self.version)
                    loadStored(); states[key] = .idle; return
                } catch AnalysisError.sourceChanged where attempt == 0 {
                    // One bounded retry incorporates an edit committed during inference.
                    continue
                }
            }
        } catch is CancellationError {
            pendingDays.insert(day)
            states[key] = .idle
        } catch {
            states[key] = .failed(Self.safeMessage(error))
        }
    }

    @discardableResult
    private func generateReflection(_ period: AnalysisPeriod, reuseCache: Bool) async throws -> StoredReflection? {
        let key = period.key
        try Task.checkCancellation()
        let fingerprint = try store.reflectionFingerprint(for: period, version: Self.version)
        let cached = try selectedDerivedCache { try store.reflection(for: period) }
        if reuseCache, let cached,
           !cached.isStale, cached.analysisVersion == Self.version, cached.sourceFingerprint == fingerprint {
            reflections[key] = cached; states[key] = .idle
            availability = await engine.availability()
            return cached
        }
        if case nil = cached { reflections[key] = nil }
        availability = await engine.availability()
        let snapshots = try store.snapshots(from: period.firstDay, through: period.lastDay)
        let sourceOverrides = try store.emotionOverrides(from: period.firstDay, through: period.lastDay)
        guard snapshots.contains(where: { !$0.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw AnalysisError.emptySource
        }
        availability = await engine.availability()
        guard availability == .available else { states[key] = .idle; return nil }
        states[key] = .loading
        var source = ["Requested \(period.kind.rawValue) period: \(period.firstDay.key) through \(period.lastDay.key). Only these days are included. Emotions are interpretations; a user correction takes priority."]
        var events: [String] = []
        let sourceDays = Set(snapshots.map(\.dayKey))
        for day in period.days where sourceDays.contains(day.key) {
            await analyze(day: day)
            try Task.checkCancellation()
            let daySnapshots = try store.snapshots(from: day, through: day)
            if daySnapshots.allSatisfy({ $0.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { continue }
            guard let value = try store.dailyAnalysis(for: day), !value.isStale,
                  value.analysisVersion == Self.version,
                  value.sourceFingerprint == AnalysisFingerprint.entries(daySnapshots, version: Self.version)
            else { throw AnalysisError.generationFailed }
            let emotion = sourceOverrides[day.key] ?? value.content.primaryEmotion
            let dayEvents = value.content.importantEvents.map { "\(day.key): \($0)" }
            events += dayEvents
            if period.kind == .weekly {
                source.append("\(day.key): \(value.content.summary)\nEmotion: \(emotion.title)\nTrajectory: \(value.content.emotionalTrajectory)\nEvents:\n\(dayEvents.joined(separator: "\n"))")
            } else {
                // Independent daily facts prevent repeated summaries from erasing events.
                source.append("\(day.key) emotion: \(emotion.title). Daily facts:\n\(dayEvents.joined(separator: "\n"))")
            }
        }
        if period.kind == .monthly {
            for week in period.clippedWeeks {
                guard sourceDays.contains(where: { $0 >= week.firstDay.key && $0 <= week.lastDay.key }) else { continue }
                if let value = try await requestReflection(week) {
                    source.append("Clipped week \(week.firstDay.key) through \(week.lastDay.key):\n\(JournalAnalysisEngine.reflectionText(value.content))")
                } else { throw AnalysisError.generationFailed }
            }
        }
        var content = try await engine.reflect(text: source.joined(separator: "\n\n"), kind: period.kind)
        // Retain all independently extracted daily facts, even if prose is shorter.
        var seen = Set<String>()
        content.importantEvents = events.filter { seen.insert($0).inserted }
        try Task.checkCancellation()
        try store.saveReflection(content, for: period, sourceFingerprint: fingerprint, version: Self.version)
        let value = try store.reflection(for: period)
        loadStored()
        reflections[key] = value; states[key] = .idle
        return value
    }

    /// Only malformed selected interpretations are expendable caches. Store fetch
    /// failures still propagate; no original writing or correction is removed.
    private func selectedDerivedCache<Value>(_ read: () throws -> Value?) throws -> Value? {
        do { return try read() }
        catch is DecodingError {
            states["storage"] = .failed("A saved reflection couldn’t be read. Try reflecting on the affected day or period again. Your writing is saved.")
            return nil
        } catch AnalysisError.invalidOutput {
            states["storage"] = .failed("A saved reflection couldn’t be read. Try reflecting on the affected day or period again. Your writing is saved.")
            return nil
        }
    }

    private static func safeMessage(_ error: Error) -> String {
        if let error = error as? AnalysisError { return error.errorDescription! }
        // SwiftData/provider error descriptions may contain private values.
        return "Your reflection couldn’t be saved. Try again. Your journal is still available."
    }
}
