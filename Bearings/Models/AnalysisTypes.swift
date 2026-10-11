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

    func validate() throws {
        guard !overview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              importantEvents.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else { throw AnalysisError.invalidOutput }
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

/// Monday–Sunday weeks and calendar months, calculated in UTC civil space.
/// A clipped week retains only the requested month's days.
struct AnalysisPeriod: Hashable, Sendable {
    let kind: ReflectionKind
    let firstDay: JournalDay
    let lastDay: JournalDay
    var key: String { "\(kind.rawValue):\(firstDay.key):\(lastDay.key)" }

    static func week(containing day: JournalDay) -> AnalysisPeriod {
        let calendar = civilCalendar
        let date = day.date(calendar: calendar)!
        let offset = (calendar.component(.weekday, from: date) + 5) % 7
        let start = calendar.date(byAdding: .day, value: -offset, to: date)!
        let end = calendar.date(byAdding: .day, value: 6, to: start)!
        let minimum = JournalDay(key: "0001-01-01")!.date(calendar: calendar)!
        let maximum = JournalDay(key: "9999-12-31")!.date(calendar: calendar)!
        return AnalysisPeriod(kind: .weekly,
                              firstDay: JournalDay(date: max(start, minimum), calendar: calendar),
                              lastDay: JournalDay(date: min(end, maximum), calendar: calendar))
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
                           period: AnalysisPeriod, version: Int) -> String {
        var parts = [period.key, self.entries(entries, version: version)]
        for key in overrides.keys.sorted() { parts += [key, overrides[key]!.rawValue] }
        return hash(parts)
    }

    private static func hash(_ parts: [String]) -> String {
        var data = Data()
        for part in parts { data.append(Data("\(part.utf8.count):".utf8)); data.append(Data(part.utf8)) }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
