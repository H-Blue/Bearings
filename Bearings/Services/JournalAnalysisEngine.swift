import Foundation

/// Serializes expensive inference. Every source segment is processed; extracted
/// facts are retained separately from the lossy prose aggregation hierarchy.
actor JournalAnalysisEngine {
    private let intelligence: any JournalIntelligence
    private var busy = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    static let inputByteBudget = 2400

    init(intelligence: any JournalIntelligence) { self.intelligence = intelligence }

    func availability() async -> IntelligenceAvailability { await intelligence.availability() }

    func analyze(entries: [JournalEntrySnapshot]) async throws -> DailyAnalysisContent {
        await acquire()
        defer { release() }
        try Task.checkCancellation()
        guard await intelligence.availability() == .available else { throw AnalysisError.generationFailed }
        var pieces: [DailyAnalysisContent] = []
        for entry in entries.sorted(by: { ($0.createdAt, $0.id.uuidString) < ($1.createdAt, $1.id.uuidString) }) {
            guard !entry.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            for chunk in Self.chunks(entry.body) {
                pieces += try await analyzeText("Journal day \(entry.dayKey), \(entry.period.title). A segment of the writer's journal follows:\n\(chunk)")
            }
        }
        guard !pieces.isEmpty else { throw AnalysisError.emptySource }
        let events = Self.unique(pieces.flatMap(\.importantEvents))
        var result = try await combineDaily(pieces)
        result.importantEvents = events
        try result.validate()
        return result
    }

    func reflect(text: String, kind: ReflectionKind) async throws -> ReflectionContent {
        await acquire()
        defer { release() }
        try Task.checkCancellation()
        guard await intelligence.availability() == .available else { throw AnalysisError.generationFailed }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw AnalysisError.emptySource }
        var pieces: [ReflectionContent] = []
        for chunk in Self.chunks(text) { pieces += try await reflectText(chunk, kind: kind) }
        let events = Self.unique(pieces.flatMap(\.importantEvents))
        var rounds = 0
        while pieces.count > 1 {
            guard rounds < 16 else { throw AnalysisError.contextTooLarge }
            var next: [ReflectionContent] = []
            for index in stride(from: 0, to: pieces.count, by: 2) {
                if index + 1 == pieces.count { next.append(pieces[index]); continue }
                let text = [pieces[index], pieces[index + 1]].map(Self.reflectionText).joined(separator: "\n\n")
                // A fresh session for each pair keeps history bounded.
                next.append(try await mergeReflection(text, kind: kind))
            }
            pieces = next
            rounds += 1
        }
        var result = pieces[0]
        result.importantEvents = events
        try result.validate()
        return result
    }

    /// UTF-8 is a conservative budget, not a claim about tokenizer equivalence.
    /// Unicode scalar boundaries preserve every byte, including large graphemes.
    static func chunks(_ text: String, byteLimit: Int = inputByteBudget) -> [String] {
        precondition(byteLimit >= 4)
        var result: [String] = []
        var current = String.UnicodeScalarView()
        var bytes = 0
        for scalar in text.unicodeScalars {
            let count = scalar.utf8.count
            if bytes + count > byteLimit && !current.isEmpty {
                result.append(String(current)); current = String.UnicodeScalarView(); bytes = 0
            }
            current.append(scalar); bytes += count
        }
        if !current.isEmpty { result.append(String(current)) }
        return result
    }

    private func analyzeText(_ text: String) async throws -> [DailyAnalysisContent] {
        try Task.checkCancellation()
        do {
            let result = try await intelligence.analyze(text)
            try Task.checkCancellation()
            try result.validate()
            return [result]
        } catch AnalysisError.contextTooLarge {
            guard text.utf8.count > 256 else { throw AnalysisError.contextTooLarge }
            var result: [DailyAnalysisContent] = []
            for chunk in Self.chunks(text, byteLimit: max(128, text.utf8.count / 2)) {
                result += try await analyzeText(chunk)
            }
            return result
        }
    }

    private func combineDaily(_ initial: [DailyAnalysisContent]) async throws -> DailyAnalysisContent {
        var pieces = initial
        var rounds = 0
        while pieces.count > 1 {
            guard rounds < 16 else { throw AnalysisError.contextTooLarge }
            var next: [DailyAnalysisContent] = []
            for index in stride(from: 0, to: pieces.count, by: 2) {
                if index + 1 == pieces.count { next.append(pieces[index]); continue }
                let text = [pieces[index], pieces[index + 1]].map {
                    "Summary: \($0.summary)\nPrimary interpretation: \($0.primaryEmotion.title)\nSecondary: \($0.secondaryEmotion?.title ?? "none")\nTrajectory: \($0.emotionalTrajectory)"
                }.joined(separator: "\n\n")
                let merged = try await analyzeText("Combine these consecutive interpretations of one day. Preserve ambiguity; do not invent experiences.\n\(text)")
                // If the model's output is itself oversized, report it explicitly
                // rather than dropping a section or entering an unbounded loop.
                guard merged.count == 1 else { throw AnalysisError.contextTooLarge }
                next += merged
            }
            pieces = next; rounds += 1
        }
        return pieces[0]
    }

    private func reflectText(_ text: String, kind: ReflectionKind) async throws -> [ReflectionContent] {
        try Task.checkCancellation()
        do {
            let result = try await intelligence.reflect(text, kind: kind)
            try Task.checkCancellation()
            try result.validate()
            return [result]
        } catch AnalysisError.contextTooLarge {
            guard text.utf8.count > 256 else { throw AnalysisError.contextTooLarge }
            var result: [ReflectionContent] = []
            for chunk in Self.chunks(text, byteLimit: max(128, text.utf8.count / 2)) {
                result += try await reflectText(chunk, kind: kind)
            }
            return result
        }
    }

    private func mergeReflection(_ text: String, kind: ReflectionKind) async throws -> ReflectionContent {
        let merged = try await reflectText("Combine these reflection segments. State only supported experiences and uncertainty.\n\(text)", kind: kind)
        guard merged.count == 1 else { throw AnalysisError.contextTooLarge }
        return merged[0]
    }

    static func reflectionText(_ value: ReflectionContent) -> String {
        "Overview: \(value.overview)\nEmotions: \(value.emotionalThemes)\nRelationships: \(value.relationships)\nInterests: \(value.interests)\nChanges: \(value.changes)"
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private func acquire() async {
        if busy { await withCheckedContinuation { waiters.append($0) } }
        else { busy = true }
    }

    private func release() {
        if waiters.isEmpty { busy = false }
        else { waiters.removeFirst().resume() }
    }
}
