import Foundation

/// Committed, read-only journal values for local reflection or export features.
/// There is no networking or content transmission at this boundary.
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
    let createdTimeZoneIdentifier: String?

    init(_ entry: JournalEntry) {
        id = entry.id
        dayKey = entry.dayKey
        body = entry.body
        period = entry.period
        createdAt = entry.createdAt
        modifiedAt = entry.modifiedAt
        createdTimeZoneIdentifier = entry.createdTimeZoneIdentifier
    }
}
