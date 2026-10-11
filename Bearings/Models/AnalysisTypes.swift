import Foundation
import CryptoKit

enum JournalEmotion: String, CaseIterable, Codable, Identifiable, Sendable {
    case joy, peace, sadness, anger, fear, loneliness, love, uncertain
    var id: String { rawValue }
    var title: String { self == .uncertain ? "Mixed / uncertain" : rawValue.capitalized }
}

struct DailyAnalysisContent: Codable, Equatable, Sendable {
    var summary: String
    var primaryEmotion: JournalEmotion
    var secondaryEmotion: JournalEmotion?
    var importantEvents: [String]
    var emotionalTrajectory: String

    /// Only emotions specific enough to present as notable findings. An
    /// uncertain classification still remains in the stored interpretation,
    /// but does not become a claimed emotion in the reflection UI.
    var notableEmotions: [JournalEmotion] {
        var emotions: [JournalEmotion] = []
        if primaryEmotion != .uncertain { emotions.append(primaryEmotion) }
        if let secondaryEmotion,
           secondaryEmotion != .uncertain,
           !emotions.contains(secondaryEmotion) {
            emotions.append(secondaryEmotion)
        }
        return emotions
    }

    func validate() throws {
        guard !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !emotionalTrajectory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              importantEvents.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else { throw AnalysisError.invalidOutput }
    }
}

struct ReflectionContent: Codable, Equatable, Sendable {
    var overview: String
    var importantEvents: [String]
    var emotionalThemes: String
    var relationships: String
    var interests: String
    var changes: String
    var weeklyDetails: WeeklyReflectionDetails? = nil
    /// Prepared fictional reflections are labeled in the interface and may be
    /// replaced by the ordinary on-device regeneration path.
    var isPreparedDemo: Bool? = nil

    func validate() throws {
        guard !overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              importantEvents.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else { throw AnalysisError.invalidOutput }
        try weeklyDetails?.validate()
    }
}

struct GroundedWeeklySignal: Codable, Equatable, Hashable, Sendable {
    var statement: String
    var evidenceExcerpt: String

    func validate(source: String) throws {
        let statement = statement.trimmingCharacters(in: .whitespacesAndNewlines)
        let excerpt = evidenceExcerpt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !statement.isEmpty, !excerpt.isEmpty, source.contains(excerpt) else {
            throw AnalysisError.invalidOutput
        }
    }
}

struct DatedWeeklyEvent: Codable, Equatable, Hashable, Sendable {
    var dayKey: String
    var statement: String
    var evidenceExcerpt: String

    func validate(source: String, period: AnalysisPeriod) throws {
        guard let day = JournalDay(key: dayKey), period.days.contains(day) else {
            throw AnalysisError.invalidOutput
        }
        try GroundedWeeklySignal(statement: statement, evidenceExcerpt: evidenceExcerpt).validate(source: source)
    }
}

struct WeeklySignals: Codable, Equatable, Sendable {
    var focusAreas: [GroundedWeeklySignal]
    var importantEvents: [DatedWeeklyEvent]
    var explicitGoals: [GroundedWeeklySignal]
    var progress: [GroundedWeeklySignal]
    var obstacles: [GroundedWeeklySignal]
    var unfinishedThreads: [GroundedWeeklySignal]
    var emotionalChanges: [GroundedWeeklySignal]
    var precedingWeekContinuity: [GroundedWeeklySignal]

    func validate(source: String, period: AnalysisPeriod) throws {
        for signal in focusAreas + explicitGoals + progress + obstacles + unfinishedThreads
            + emotionalChanges + precedingWeekContinuity {
            try signal.validate(source: source)
        }
        for event in importantEvents { try event.validate(source: source, period: period) }
    }

    var compactPacket: String {
        func section(_ title: String, _ values: [GroundedWeeklySignal]) -> String {
            let lines = values.map { "- \($0.statement) [evidence: \($0.evidenceExcerpt)]" }
            return "\(title):\n\(lines.isEmpty ? "- none supported" : lines.joined(separator: "\n"))"
        }
        let events = importantEvents.map {
            "- \($0.dayKey): \($0.statement) [evidence: \($0.evidenceExcerpt)]"
        }
        return [
            section("Repeated focus or work", focusAreas),
            "Important dated events:\n\(events.isEmpty ? "- none supported" : events.joined(separator: "\n"))",
            section("Explicit goals or intentions", explicitGoals),
            section("Progress", progress),
            section("Obstacles", obstacles),
            section("Unfinished threads", unfinishedThreads),
            section("Supported emotional changes", emotionalChanges),
            section("Relevant preceding-week continuity", precedingWeekContinuity)
        ].joined(separator: "\n\n")
    }

    var supportedStatements: Set<String> {
        Set((focusAreas + explicitGoals + progress + obstacles + unfinishedThreads
             + emotionalChanges + precedingWeekContinuity).map(\.statement)
            + importantEvents.map(\.statement))
    }

    static func merged(_ values: [WeeklySignals]) -> WeeklySignals {
        func unique<T: Hashable>(_ values: [T]) -> [T] {
            var seen = Set<T>()
            return values.filter { seen.insert($0).inserted }
        }
        return WeeklySignals(
            focusAreas: unique(values.flatMap(\.focusAreas)),
            importantEvents: unique(values.flatMap(\.importantEvents)),
            explicitGoals: unique(values.flatMap(\.explicitGoals)),
            progress: unique(values.flatMap(\.progress)),
            obstacles: unique(values.flatMap(\.obstacles)),
            unfinishedThreads: unique(values.flatMap(\.unfinishedThreads)),
            emotionalChanges: unique(values.flatMap(\.emotionalChanges)),
            precedingWeekContinuity: unique(values.flatMap(\.precedingWeekContinuity))
        )
    }
}

enum LessonReadiness: String, Codable, Equatable, Sendable {
    case continueCurrentLesson
    case readyForNewChallenge
    case insufficientEvidence

    var title: String {
        switch self {
        case .continueCurrentLesson: "Continue the current lesson"
        case .readyForNewChallenge: "Ready for a new lesson or challenge"
        case .insufficientEvidence: "Insufficient evidence"
        }
    }
}

struct WeeklyReflectionDetails: Codable, Equatable, Sendable {
    var workFocus: String
    var progressAndUnfinished: String
    var whatHelped: String
    var realisticImprovement: String
    var lessonReadiness: LessonReadiness
    var readinessEvidence: [String]
    var reflectionQuestion: String?

    func validate(supportedStatements: Set<String>? = nil) throws {
        let required = [workFocus, progressAndUnfinished, whatHelped, realisticImprovement]
        guard required.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
              readinessEvidence.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else { throw AnalysisError.invalidOutput }
        if let supportedStatements,
           !readinessEvidence.allSatisfy({ supportedStatements.contains($0) }) {
            throw AnalysisError.invalidOutput
        }
        switch lessonReadiness {
        case .insufficientEvidence:
            guard let reflectionQuestion,
                  !reflectionQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AnalysisError.invalidOutput
            }
        case .continueCurrentLesson, .readyForNewChallenge:
            guard !readinessEvidence.isEmpty else { throw AnalysisError.invalidOutput }
        }
    }
}

struct EmotionalZoomContent: Equatable, Sendable {
    var vagueExcerpt: String?
    var explanation: String
    var probingQuestion: String

    func validate(source: String) throws {
        let excerpt = vagueExcerpt?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !probingQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              excerpt.map({ !$0.isEmpty && source.contains($0) }) ?? true
        else { throw AnalysisError.invalidOutput }
    }
}

enum ReflectionKind: String, Codable, Sendable { case weekly, monthly }

/// Sunday–Saturday weeks and calendar months, calculated in UTC civil space.
/// A clipped week retains only the requested month's days.
struct AnalysisPeriod: Hashable, Sendable {
    let kind: ReflectionKind
    let firstDay: JournalDay
    let lastDay: JournalDay
    var key: String { "\(kind.rawValue):\(firstDay.key):\(lastDay.key)" }

    static func week(containing day: JournalDay) -> AnalysisPeriod {
        let calendar = civilCalendar
        let date = day.date(calendar: calendar)!
        let offset = calendar.component(.weekday, from: date) - 1
        let start = calendar.date(byAdding: .day, value: -offset, to: date)!
        let end = calendar.date(byAdding: .day, value: 6, to: start)!
        let minimum = JournalDay(key: "0001-01-01")!.date(calendar: calendar)!
        let maximum = JournalDay(key: "9999-12-31")!.date(calendar: calendar)!
        return AnalysisPeriod(kind: .weekly,
                              firstDay: JournalDay(date: max(start, minimum), calendar: calendar),
                              lastDay: JournalDay(date: min(end, maximum), calendar: calendar))
    }

    /// On the first day of a new week, the weekly review covers the completed
    /// Sunday–Saturday period. During the rest of a week it covers that week.
    static func weekForReview(on day: JournalDay) -> AnalysisPeriod {
        let current = week(containing: day)
        guard current.firstDay == day,
              let date = day.date(calendar: civilCalendar),
              let previousDate = civilCalendar.date(byAdding: .day, value: -1, to: date),
              previousDate >= JournalDay(key: "0001-01-01")!.date(calendar: civilCalendar)!
        else { return current }
        return week(containing: JournalDay(date: previousDate, calendar: civilCalendar))
    }

    static func isWeekStart(_ day: JournalDay) -> Bool {
        week(containing: day).firstDay == day
    }

    static func month(containing day: JournalDay) -> AnalysisPeriod {
        let days = JournalMonth(day: day).days
        return AnalysisPeriod(kind: .monthly, firstDay: days.first!, lastDay: days.last!)
    }

    var days: [JournalDay] {
        let calendar = Self.civilCalendar
        var date = firstDay.date(calendar: calendar)!
        let end = lastDay.date(calendar: calendar)!
        var result: [JournalDay] = []
        while date <= end {
            result.append(JournalDay(date: date, calendar: calendar))
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return result
    }

    var clippedWeeks: [AnalysisPeriod] {
        var result: [AnalysisPeriod] = []
        for day in days {
            let week = Self.week(containing: day)
            let clipped = AnalysisPeriod(kind: .weekly, firstDay: max(firstDay, week.firstDay),
                                         lastDay: min(lastDay, week.lastDay))
            if result.last != clipped { result.append(clipped) }
        }
        return result
    }

    var precedingFullWeek: AnalysisPeriod? {
        guard kind == .weekly, days.count == 7, Self.week(containing: firstDay) == self,
              let start = firstDay.date(calendar: Self.civilCalendar),
              let previous = Self.civilCalendar.date(byAdding: .day, value: -1, to: start),
              previous >= JournalDay(key: "0001-01-01")!.date(calendar: Self.civilCalendar)!
        else { return nil }
        return Self.week(containing: JournalDay(date: previous, calendar: Self.civilCalendar))
    }

    private static var civilCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}

struct StoredDailyAnalysis: Sendable {
    let dayKey: String
    let content: DailyAnalysisContent
    let sourceFingerprint: String
    let generatedAt: Date
    let analysisVersion: Int
    let isStale: Bool
}

struct StoredReflection: Sendable {
    let period: AnalysisPeriod
    let content: ReflectionContent
    let sourceFingerprint: String
    let generatedAt: Date
    let analysisVersion: Int
    let isStale: Bool
}

enum AnalysisFingerprint {
    static func entries(_ entries: [JournalEntrySnapshot], version: Int) -> String {
        // Length-prefixed values avoid ambiguous concatenation; content is never logged.
        var parts = [String(version)]
        for entry in entries.sorted(by: { $0.id.uuidString < $1.id.uuidString }) {
            parts += [entry.id.uuidString, entry.dayKey, entry.body, entry.period.rawValue,
                      String(entry.createdAt.timeIntervalSince1970), String(entry.modifiedAt.timeIntervalSince1970)]
        }
        return hash(parts)
    }

    static func reflection(entries: [JournalEntrySnapshot], overrides: [String: JournalEmotion],
                           period: AnalysisPeriod, version: Int, derivedInputs: [String] = []) -> String {
        var parts = [period.key, self.entries(entries, version: version)]
        for key in overrides.keys.sorted() { parts += [key, overrides[key]!.rawValue] }
        parts += derivedInputs
        return hash(parts)
    }

    private static func hash(_ parts: [String]) -> String {
        var data = Data()
        for part in parts { data.append(Data("\(part.utf8.count):".utf8)); data.append(Data(part.utf8)) }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
