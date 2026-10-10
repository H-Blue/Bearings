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

    init(context: ModelContext, now: @escaping () -> Date = Date.init) {
        self.context = context
        self.now = now
        context.autosaveEnabled = false
    }

    func entries(for day: JournalDay) throws -> [JournalEntry] {
        let key = day.key
        var descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.dayKey == key },
            sortBy: [SortDescriptor(\JournalEntry.createdAt)]
        )
        descriptor.includePendingChanges = false
        return try context.fetch(descriptor)
    }

    func daysWithEntries() throws -> Set<String> {
        var descriptor = FetchDescriptor<JournalEntry>()
        descriptor.includePendingChanges = false
        let entries = try context.fetch(descriptor)
        return Set(entries.map(\.dayKey))
    }

    @discardableResult
    func create(day: JournalDay, body: String, period: JournalPeriod = .midday) throws -> JournalEntry {
        try validate(body)
        let entry = JournalEntry(day: day, body: body, period: period, now: now())
        let transactionContext = makeTransactionContext()
        transactionContext.insert(entry)
        try save(transactionContext)
        return entry
    }

    func update(entry: JournalEntry, body: String, period: JournalPeriod? = nil) throws {
        // Clearing existing writing is still an edit. Save it so a clear-and-
        // rewrite workflow survives termination; deletion is always explicit.
        let newPeriod = period ?? entry.period
        guard entry.body != body || entry.period != newPeriod else { return }
        let transactionContext = makeTransactionContext()
        let storedEntry = try resolve(entry.id, in: transactionContext)
        storedEntry.body = body
        storedEntry.period = newPeriod
        storedEntry.modifiedAt = max(now(), storedEntry.modifiedAt)
        try save(transactionContext)
        // The editor and @Query continue to hold the original model. Mirror
        // only confirmed writes, so an error never changes their visible data.
        entry.body = storedEntry.body
        entry.periodRawValue = storedEntry.periodRawValue
        entry.modifiedAt = storedEntry.modifiedAt
    }

    func delete(entry: JournalEntry) throws {
        // A failed SwiftData delete can leave the original context's registered
        // model hidden even after rollback/undo. Isolate the deletion so the
        // context observed by the interface is never changed on failure.
        let transactionContext = makeTransactionContext()
        let storedEntry = try resolve(entry.id, in: transactionContext)
        transactionContext.delete(storedEntry)
        try save(transactionContext)
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
        guard firstDay <= lastDay else { return [] }
        let firstKey = firstDay.key
        let lastKey = lastDay.key
        var descriptor = FetchDescriptor<JournalEntry>(
            predicate: #Predicate { $0.dayKey >= firstKey && $0.dayKey <= lastKey },
            sortBy: [SortDescriptor(\JournalEntry.dayKey), SortDescriptor(\JournalEntry.createdAt)]
        )
        descriptor.includePendingChanges = false
        return try context.fetch(descriptor).map(JournalEntrySnapshot.init)
    }
}
