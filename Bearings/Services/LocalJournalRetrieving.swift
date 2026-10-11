import Foundation

/// A read-only, on-device boundary for future reflection or export features.
/// There is no networking, AI client, or automatic content transmission here.
@MainActor
protocol LocalJournalRetrieving {
    func snapshots(from firstDay: JournalDay, through lastDay: JournalDay) throws -> [JournalEntrySnapshot]
}

struct JournalEntrySnapshot: Identifiable, Sendable {
    let id: UUID
    let dayKey: String
    let body: String
    let period: JournalPeriod
    let createdAt: Date
    let modifiedAt: Date

    init(_ entry: JournalEntry) {
        id = entry.id
        dayKey = entry.dayKey
        body = entry.body
        period = entry.period
        createdAt = entry.createdAt
        modifiedAt = entry.modifiedAt
    }
}
