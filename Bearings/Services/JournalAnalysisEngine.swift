import Foundation

/// Serializes expensive inference. Every source segment is processed; extracted
/// facts are retained separately from the lossy prose aggregation hierarchy.
actor JournalAnalysisEngine {
    private let intelligence: any JournalIntelligence
    private let busyRetryDelays: [Duration]
    private var busy = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    static let inputByteBudget = 2400

    init(
        intelligence: any JournalIntelligence,
        busyRetryDelays: [Duration] = [.milliseconds(500), .seconds(2)]
    ) {
        self.intelligence = intelligence
        self.busyRetryDelays = busyRetryDelays
    }

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

    /// Weekly work is deliberately two-stage. Extraction may use multiple
    /// bounded calls, but the final writer sees one compact packet and no raw
    /// journal transcript or recursively loaded history.
    func reflectWeekly(evidence: String, period: AnalysisPeriod) async throws -> ReflectionContent {
        await acquire()
        defer { release() }
        try Task.checkCancellation()
        guard await intelligence.availability() == .available else { throw AnalysisError.generationFailed }
        guard !evidence.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AnalysisError.emptySource
        }
        var extracted: [WeeklySignals] = []
        for chunk in Self.chunks(evidence) {
            let evidenceLines = chunk.split(separator: "\n", omittingEmptySubsequences: true)
                .enumerated()
                .map { String(format: "[E%03d] %@", $0.offset + 1, String($0.element)) }
                .joined(separator: "\n")
            let boundedEvidence = """
                REQUESTED WEEK: \(period.firstDay.key) through \(period.lastDay.key)
                Each claim must cite one evidence-line ID from the evidence below.

                \(evidenceLines)
                """
            extracted += try await extractWeeklySignals(boundedEvidence, period: period)
        }
        let signals = WeeklySignals.merged(extracted)
        let packet = signals.compactPacket
        var content = try await retryWhenModelIsBusy {
            try await intelligence.composeWeeklyReflection(packet)
        }
        try Task.checkCancellation()
        guard let details = content.weeklyDetails else { throw AnalysisError.invalidOutput }
        try details.validate(supportedStatements: signals.supportedStatements)
        content.importantEvents = signals.importantEvents.map { "\($0.dayKey): \($0.statement)" }
        try content.validate()
        return content
    }

    func emotionalZoom(text: String) async throws -> EmotionalZoomContent {
        await acquire()
        defer { release() }
        try Task.checkCancellation()
        guard await intelligence.availability() == .available else { throw AnalysisError.generationFailed }
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw AnalysisError.emptySource }
        var results: [EmotionalZoomContent] = []
        for chunk in Self.chunks(text) { results += try await zoomText(chunk) }
        guard let result = results.first(where: { $0.vagueExcerpt != nil }) ?? results.first else {
            throw AnalysisError.invalidOutput
        }
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
            let result = try await retryWhenModelIsBusy {
                try await intelligence.analyze(text)
            }
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

    private func extractWeeklySignals(_ text: String, period: AnalysisPeriod) async throws -> [WeeklySignals] {
        try Task.checkCancellation()
        do {
            let result = try await retryWhenModelIsBusy {
                try await intelligence.extractWeeklySignals(text)
            }
            try Task.checkCancellation()
            try result.validate(source: text, period: period)
            return [result]
        } catch AnalysisError.contextTooLarge {
            guard text.utf8.count > 256 else { throw AnalysisError.contextTooLarge }
            var result: [WeeklySignals] = []
            for chunk in Self.chunks(text, byteLimit: max(128, text.utf8.count / 2)) {
                result += try await extractWeeklySignals(chunk, period: period)
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
                    "Day summary: \($0.summary)\nNotable emotion: \($0.primaryEmotion.title)\nSecond notable emotion: \($0.secondaryEmotion?.title ?? "none")\nTrajectory: \($0.emotionalTrajectory)"
                }.joined(separator: "\n\n")
                let merged = try await analyzeText("Combine these consecutive interpretations of one day. Summarize the day first, retain only supported writer emotions, and use uncertain when no notable emotion is supported. Preserve ambiguity; do not invent experiences.\n\(text)")
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
            let result = try await retryWhenModelIsBusy {
                try await intelligence.reflect(text, kind: kind)
            }
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

    private func zoomText(_ text: String) async throws -> [EmotionalZoomContent] {
        try Task.checkCancellation()
        do {
            let result = try await retryWhenModelIsBusy {
                try await intelligence.emotionalZoom(text)
            }
            try Task.checkCancellation()
            try result.validate(source: text)
            return [result]
        } catch AnalysisError.contextTooLarge {
            guard text.utf8.count > 256 else { throw AnalysisError.contextTooLarge }
            var result: [EmotionalZoomContent] = []
            for chunk in Self.chunks(text, byteLimit: max(128, text.utf8.count / 2)) {
                result += try await zoomText(chunk)
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
        if let weekly = value.weeklyDetails {
            return "Work focus: \(weekly.workFocus)\nWhat happened: \(value.overview)\nProgress and unfinished: \(weekly.progressAndUnfinished)\nWhat helped: \(weekly.whatHelped)\nImprovement: \(weekly.realisticImprovement)\nEmotions: \(value.emotionalThemes)\nLesson direction: \(weekly.lessonReadiness.title)\nReadiness evidence: \(weekly.readinessEvidence.joined(separator: "; "))"
        }
        return "Overview: \(value.overview)\nEmotions: \(value.emotionalThemes)\nRelationships: \(value.relationships)\nInterests: \(value.interests)\nChanges: \(value.changes)"
    }

    private static func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private func retryWhenModelIsBusy<Value>(
        _ operation: () async throws -> Value
    ) async throws -> Value {
        for delay in busyRetryDelays {
            do { return try await operation() }
            catch AnalysisError.modelBusy {
                try Task.checkCancellation()
                try await Task.sleep(for: delay)
            }
        }
        return try await operation()
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
