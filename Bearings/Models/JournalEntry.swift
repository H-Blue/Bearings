import Foundation
import SwiftData

@Model
final class JournalEntry {
    @Attribute(.unique) var id: UUID
    var dayKey: String
    var body: String
    var periodRawValue: String
    var createdAt: Date
    var modifiedAt: Date
    // Legacy entries have no reliable record of their creation zone.
    var createdTimeZoneIdentifier: String? = nil

    var period: JournalPeriod {
        get { JournalPeriod(rawValue: periodRawValue) ?? .midday }
        set { periodRawValue = newValue.rawValue }
    }

    init(day: JournalDay, body: String, period: JournalPeriod = .midday, now: Date = Date(),
         createdTimeZoneIdentifier: String? = TimeZone.current.identifier) {
        id = UUID()
        dayKey = day.key
        self.body = body
        periodRawValue = period.rawValue
        createdAt = now
        modifiedAt = now
        self.createdTimeZoneIdentifier = createdTimeZoneIdentifier
    }
}
