import Foundation
import Observation
import SwiftData

enum JournalStoreError: LocalizedError {
    case emptyEntry
    case entryNotFound

    var errorDescription: String? {
        switch self {
        case .emptyEntry:
            return "Write something before saving a new entry."
        case .entryNotFound:
            return "This entry could not be found. Close the editor and open the day again."
        }
    }
}

/// All journal mutations pass through this store and are explicitly saved.
/// Editor drafts stay in view state so a failed save cannot discard the writing.
@MainActor
@Observable
final class JournalStore {
    private(set) var revision = 0

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let creationTimeZone: () -> TimeZone
    @ObservationIgnored private var changedDays = Set<JournalDay>()

    init(context: ModelContext, now: @escaping () -> Date = Date.init,
         creationTimeZone: @escaping () -> TimeZone = { .current }) {
        self.context = context
        self.now = now
        self.creationTimeZone = creationTimeZone
        context.autosaveEnabled = false
    }

    func entries(for day: JournalDay) throws -> [JournalEntry] {
        let key = day.key
        var descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.dayKey == key },
            sortBy: [SortDescriptor(\JournalEntry.createdAt)]
        )
        descriptor.includePendingChanges = false
        return try makeTransactionContext().fetch(descriptor)
    }

    func daysWithEntries() throws -> Set<String> {
        var descriptor = FetchDescriptor<JournalEntry>()
        descriptor.includePendingChanges = false
        let entries = try makeTransactionContext().fetch(descriptor)
        return Set(entries.map(\.dayKey))
    }

    @discardableResult
    func create(day: JournalDay, body: String, period: JournalPeriod = .midday) throws -> JournalEntry {
        try validate(body)
        let entry = JournalEntry(day: day, body: body, period: period, now: now(),
                                 createdTimeZoneIdentifier: creationTimeZone().identifier)
        let transactionContext = makeTransactionContext()
        transactionContext.insert(entry)
        try invalidate(dayKeys: [day.key], in: transactionContext)
        try save(transactionContext)
        changedDays.insert(day)
        return entry
    }

    func update(entry: JournalEntry, body: String, period: JournalPeriod? = nil,
                day: JournalDay? = nil) throws {
        // Clearing existing writing is still an edit. Save it so a clear-and-
        // rewrite workflow survives termination; deletion is always explicit.
        let newPeriod = period ?? entry.period
        let transactionContext = makeTransactionContext()
        let storedEntry = try resolve(entry.id, in: transactionContext)
        let oldDayKey = storedEntry.dayKey
        let newDayKey = day?.key ?? storedEntry.dayKey
        guard storedEntry.body != body || storedEntry.period != newPeriod || oldDayKey != newDayKey else { return }
        storedEntry.body = body
        storedEntry.period = newPeriod
        storedEntry.dayKey = newDayKey
        storedEntry.modifiedAt = max(now(), storedEntry.modifiedAt)
        try invalidate(dayKeys: [oldDayKey, newDayKey], in: transactionContext)
        try save(transactionContext)
        // The editor and @Query continue to hold the original model. Mirror
        // only confirmed writes, so an error never changes their visible data.
        entry.body = storedEntry.body
        entry.periodRawValue = storedEntry.periodRawValue
        entry.dayKey = storedEntry.dayKey
        entry.modifiedAt = storedEntry.modifiedAt
        for key in [oldDayKey, newDayKey] {
            if let affectedDay = JournalDay(key: key) { changedDays.insert(affectedDay) }
        }
    }

    func delete(entry: JournalEntry) throws {
        // A failed SwiftData delete can leave the original context's registered
        // model hidden even after rollback/undo. Isolate the deletion so the
        // context observed by the interface is never changed on failure.
        let transactionContext = makeTransactionContext()
        let storedEntry = try resolve(entry.id, in: transactionContext)
        let dayKey = storedEntry.dayKey
        transactionContext.delete(storedEntry)
        try invalidate(dayKeys: [dayKey], in: transactionContext)
        try save(transactionContext)
        if let day = JournalDay(key: dayKey) { changedDays.insert(day) }
    }

    /// Completion triggers drain only successfully saved journal changes.
    /// Derived saves increment the UI revision but never enqueue journal work.
    func takeChangedDays() -> [JournalDay] {
        let result = changedDays.sorted()
        changedDays.removeAll()
        return result
    }

    private func validate(_ body: String) throws {
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw JournalStoreError.emptyEntry
        }
    }

    private func makeTransactionContext() -> ModelContext {
        let transactionContext = ModelContext(context.container)
        transactionContext.autosaveEnabled = false
        return transactionContext
    }

    private func resolve(_ id: UUID, in transactionContext: ModelContext) throws -> JournalEntry {
        var descriptor = FetchDescriptor<JournalEntry>(predicate: #Predicate { $0.id == id })
        descriptor.includePendingChanges = false
        descriptor.fetchLimit = 1
        guard let entry = try transactionContext.fetch(descriptor).first else {
            throw JournalStoreError.entryNotFound
        }
        return entry
    }

    private func invalidate(dayKeys: Set<String>, in transactionContext: ModelContext) throws {
        for key in dayKeys {
            var descriptor = FetchDescriptor<DailyAnalysisRecord>(predicate: #Predicate { $0.dayKey == key })
            descriptor.includePendingChanges = false
            for record in try transactionContext.fetch(descriptor) { record.isStale = true }
            try invalidateReflections(for: key, in: transactionContext)
        }
    }

    private func invalidateReflections(for dayKey: String, in transactionContext: ModelContext) throws {
        // Range overlap also catches clipped weeks used by monthly reflections.
        var descriptor = FetchDescriptor<ReflectionRecord>(
            predicate: #Predicate { $0.firstDayKey <= dayKey && $0.lastDayKey >= dayKey }
        )
        descriptor.includePendingChanges = false
        for record in try transactionContext.fetch(descriptor) { record.isStale = true }
        // A full weekly reflection may depend on exactly one preceding week.
        // Invalidate that direct dependent without walking farther back or forward.
        if let day = JournalDay(key: dayKey) {
            let containingWeek = AnalysisPeriod.week(containing: day)
            if let end = containingWeek.lastDay.date(calendar: Self.civilCalendar),
               let nextDate = Self.civilCalendar.date(byAdding: .day, value: 1, to: end),
               nextDate <= JournalDay(key: "9999-12-31")!.date(calendar: Self.civilCalendar)! {
                let dependent = AnalysisPeriod.week(containing: JournalDay(date: nextDate, calendar: Self.civilCalendar))
                if let record = try reflectionRecord(for: dependent.key, in: transactionContext) {
                    record.isStale = true
                }
            }
        }
    }

    private static var civilCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func save(_ transactionContext: ModelContext) throws {
        transactionContext.processPendingChanges()
        do {
            try transactionContext.save()
            revision += 1
        } catch {
            // Failed managed changes are confined to this short-lived context.
            // The observed context and the editor's independent draft survive.
            transactionContext.rollback()
            throw error
        }
    }
}

extension JournalStore: LocalJournalRetrieving {
    func snapshots(from firstDay: JournalDay, through lastDay: JournalDay) throws -> [JournalEntrySnapshot] {
        try snapshots(from: firstDay, through: lastDay, in: makeTransactionContext())
    }

    private func snapshots(from firstDay: JournalDay, through lastDay: JournalDay,
                           in transactionContext: ModelContext) throws -> [JournalEntrySnapshot] {
        guard firstDay <= lastDay else { return [] }
        let firstKey = firstDay.key
        let lastKey = lastDay.key
        var descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.dayKey >= firstKey && $0.dayKey <= lastKey },
            sortBy: [SortDescriptor(\JournalEntry.dayKey), SortDescriptor(\JournalEntry.createdAt)]
        )
        descriptor.includePendingChanges = false
        return try transactionContext.fetch(descriptor).map(JournalEntrySnapshot.init)
    }
}

extension JournalStore {
    func dailyAnalysis(for day: JournalDay) throws -> StoredDailyAnalysis? {
        try dailyRecord(for: day.key, in: makeTransactionContext())?.snapshot()
    }

    func dailyAnalyses(from firstDay: JournalDay, through lastDay: JournalDay) throws -> [StoredDailyAnalysis] {
        guard firstDay <= lastDay else { return [] }
        let firstKey = firstDay.key
        let lastKey = lastDay.key
        var descriptor = FetchDescriptor<DailyAnalysisRecord>(
            predicate: #Predicate { $0.dayKey >= firstKey && $0.dayKey <= lastKey },
            sortBy: [SortDescriptor(\DailyAnalysisRecord.dayKey)]
        )
        descriptor.includePendingChanges = false
        return try makeTransactionContext().fetch(descriptor).map { try $0.snapshot() }
    }

    func reflection(for period: AnalysisPeriod) throws -> StoredReflection? {
        try reflectionRecord(for: period.key, in: makeTransactionContext())?.snapshot()
    }

    func currentPrecedingWeeklyReflection(for period: AnalysisPeriod, version: Int) throws -> StoredReflection? {
        guard let preceding = period.precedingFullWeek,
              let record = try reflectionRecord(for: preceding.key, in: makeTransactionContext()),
              !record.isStale, record.analysisVersion == version else { return nil }
        return try record.snapshot()
    }

    func emotionOverrides(from firstDay: JournalDay, through lastDay: JournalDay) throws -> [String: JournalEmotion] {
        try emotionOverrides(from: firstDay, through: lastDay, in: makeTransactionContext())
    }

    func setEmotionOverride(_ emotion: JournalEmotion?, for day: JournalDay) throws {
        let transactionContext = makeTransactionContext()
        let record = try overrideRecord(for: day.key, in: transactionContext)
        guard record?.emotionRawValue != emotion?.rawValue else { return }
        if let emotion {
            if let record {
                record.emotionRawValue = emotion.rawValue
                record.modifiedAt = max(now(), record.modifiedAt)
            } else {
                transactionContext.insert(EmotionOverrideRecord(dayKey: day.key, emotion: emotion, modifiedAt: now()))
            }
        } else if let record {
            transactionContext.delete(record)
        }
        try invalidateReflections(for: day.key, in: transactionContext)
        try save(transactionContext)
    }

    func saveDailyAnalysis(_ content: DailyAnalysisContent, for day: JournalDay,
                           sourceFingerprint: String, version: Int) throws {
        try content.validate()
        let data = try JSONEncoder().encode(content)
        let transactionContext = makeTransactionContext()
        let source = try snapshots(from: day, through: day, in: transactionContext)
        guard AnalysisFingerprint.entries(source, version: version) == sourceFingerprint else {
            throw AnalysisError.sourceChanged
        }
        if let record = try dailyRecord(for: day.key, in: transactionContext) {
            record.contentData = data
            record.sourceFingerprint = sourceFingerprint
            record.generatedAt = now()
            record.analysisVersion = version
            record.isStale = false
        } else {
            transactionContext.insert(DailyAnalysisRecord(dayKey: day.key, contentData: data,
                                                         sourceFingerprint: sourceFingerprint, generatedAt: now(),
                                                         analysisVersion: version))
        }
        try invalidateReflections(for: day.key, in: transactionContext)
        try save(transactionContext)
    }

    func reflectionFingerprint(for period: AnalysisPeriod, version: Int) throws -> String {
        try reflectionFingerprint(for: period, version: version, in: makeTransactionContext())
    }

    func saveReflection(_ content: ReflectionContent, for period: AnalysisPeriod,
                        sourceFingerprint: String, version: Int) throws {
        try content.validate()
        let data = try JSONEncoder().encode(content)
        let transactionContext = makeTransactionContext()
        guard try reflectionFingerprint(for: period, version: version, in: transactionContext) == sourceFingerprint else {
            throw AnalysisError.sourceChanged
        }
        if let record = try reflectionRecord(for: period.key, in: transactionContext) {
            record.kindRawValue = period.kind.rawValue
            record.firstDayKey = period.firstDay.key
            record.lastDayKey = period.lastDay.key
            record.contentData = data
            record.sourceFingerprint = sourceFingerprint
            record.generatedAt = now()
            record.analysisVersion = version
            record.isStale = false
        } else {
            transactionContext.insert(ReflectionRecord(period: period, contentData: data,
                                                      sourceFingerprint: sourceFingerprint, generatedAt: now(),
                                                      analysisVersion: version))
        }
        if period.precedingFullWeek != nil { try invalidateDependentWeek(after: period, in: transactionContext) }
        try save(transactionContext)
    }

    private func reflectionFingerprint(for period: AnalysisPeriod, version: Int,
                                       in transactionContext: ModelContext) throws -> String {
        let entries = try snapshots(from: period.firstDay, through: period.lastDay, in: transactionContext)
        let overrides = try emotionOverrides(from: period.firstDay, through: period.lastDay, in: transactionContext)
        var derivedInputs = try dailyRecords(from: period.firstDay, through: period.lastDay,
                                             in: transactionContext).map(derivedFingerprint)
        if let preceding = period.precedingFullWeek,
           let record = try reflectionRecord(for: preceding.key, in: transactionContext),
           !record.isStale, record.analysisVersion == version {
            derivedInputs.append(derivedFingerprint(record))
        }
        if period.kind == .monthly {
            for week in period.clippedWeeks {
                if let record = try reflectionRecord(for: week.key, in: transactionContext),
                   !record.isStale, record.analysisVersion == version {
                    derivedInputs.append(derivedFingerprint(record))
                }
            }
        }
        return AnalysisFingerprint.reflection(entries: entries, overrides: overrides, period: period,
                                              version: version, derivedInputs: derivedInputs.sorted())
    }

    private func dailyRecords(from firstDay: JournalDay, through lastDay: JournalDay,
                              in transactionContext: ModelContext) throws -> [DailyAnalysisRecord] {
        let firstKey = firstDay.key
        let lastKey = lastDay.key
        var descriptor = FetchDescriptor<DailyAnalysisRecord>(
            predicate: #Predicate { $0.dayKey >= firstKey && $0.dayKey <= lastKey },
            sortBy: [SortDescriptor(\DailyAnalysisRecord.dayKey)]
        )
        descriptor.includePendingChanges = false
        return try transactionContext.fetch(descriptor)
    }

    private func derivedFingerprint(_ record: DailyAnalysisRecord) -> String {
        ["daily", record.dayKey, record.contentData.base64EncodedString(), record.sourceFingerprint,
         String(record.generatedAt.timeIntervalSince1970), String(record.analysisVersion), String(record.isStale)]
            .joined(separator: "|")
    }

    private func derivedFingerprint(_ record: ReflectionRecord) -> String {
        ["reflection", record.periodKey, record.contentData.base64EncodedString(), record.sourceFingerprint,
         String(record.generatedAt.timeIntervalSince1970), String(record.analysisVersion), String(record.isStale)]
            .joined(separator: "|")
    }

    private func invalidateDependentWeek(after period: AnalysisPeriod,
                                         in transactionContext: ModelContext) throws {
        guard period.days.count == 7, AnalysisPeriod.week(containing: period.firstDay) == period,
              let end = period.lastDay.date(calendar: Self.civilCalendar),
              let nextDate = Self.civilCalendar.date(byAdding: .day, value: 1, to: end),
              nextDate <= JournalDay(key: "9999-12-31")!.date(calendar: Self.civilCalendar)!
        else { return }
        let dependent = AnalysisPeriod.week(containing: JournalDay(date: nextDate, calendar: Self.civilCalendar))
        if let record = try reflectionRecord(for: dependent.key, in: transactionContext) {
            record.isStale = true
        }
    }

    private func dailyRecord(for key: String, in transactionContext: ModelContext) throws -> DailyAnalysisRecord? {
        var descriptor = FetchDescriptor<DailyAnalysisRecord>(predicate: #Predicate { $0.dayKey == key })
        descriptor.includePendingChanges = false
        descriptor.fetchLimit = 1
        return try transactionContext.fetch(descriptor).first
    }

    private func reflectionRecord(for key: String, in transactionContext: ModelContext) throws -> ReflectionRecord? {
        var descriptor = FetchDescriptor<ReflectionRecord>(predicate: #Predicate { $0.periodKey == key })
        descriptor.includePendingChanges = false
        descriptor.fetchLimit = 1
        return try transactionContext.fetch(descriptor).first
    }

    private func overrideRecord(for key: String, in transactionContext: ModelContext) throws -> EmotionOverrideRecord? {
        var descriptor = FetchDescriptor<EmotionOverrideRecord>(predicate: #Predicate { $0.dayKey == key })
        descriptor.includePendingChanges = false
        descriptor.fetchLimit = 1
        return try transactionContext.fetch(descriptor).first
    }

    private func emotionOverrides(from firstDay: JournalDay, through lastDay: JournalDay,
                                 in transactionContext: ModelContext) throws -> [String: JournalEmotion] {
        guard firstDay <= lastDay else { return [:] }
        let firstKey = firstDay.key
        let lastKey = lastDay.key
        var descriptor = FetchDescriptor<EmotionOverrideRecord>(
            predicate: #Predicate { $0.dayKey >= firstKey && $0.dayKey <= lastKey }
        )
        descriptor.includePendingChanges = false
        var result: [String: JournalEmotion] = [:]
        for record in try transactionContext.fetch(descriptor) {
            guard let emotion = JournalEmotion(rawValue: record.emotionRawValue) else {
                throw AnalysisError.invalidOutput
            }
            result[record.dayKey] = emotion
        }
        return result
    }
}
