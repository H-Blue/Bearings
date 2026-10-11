import Foundation

/// A Gregorian civil date, deliberately separate from a moment in time.
/// The key remains unchanged when the device moves to another time zone.
struct JournalDay: Hashable, Comparable, Identifiable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    var key: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    var id: String { key }

    static var localCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        return calendar
    }

    init(date: Date, calendar: Calendar = JournalDay.localCalendar) {
        let gregorian = Self.gregorianCalendar(in: calendar.timeZone)
        let components = gregorian.dateComponents([.year, .month, .day], from: date)
        year = components.year!
        month = components.month!
        day = components.day!
    }

    init?(key: String) {
        let bytes = Array(key.utf8)
        guard bytes.count == 10, bytes[4] == 45, bytes[7] == 45,
              bytes.enumerated().allSatisfy({ index, byte in
                  index == 4 || index == 7 || (48...57).contains(byte)
              }),
              let year = Int(key.prefix(4)),
              let month = Int(key.dropFirst(5).prefix(2)),
              let day = Int(key.suffix(2)),
              (1...9999).contains(year), (1...12).contains(month), (1...31).contains(day)
        else { return nil }

        let utc = Self.gregorianCalendar(in: TimeZone(secondsFromGMT: 0)!)
        let components = DateComponents(year: year, month: month, day: day, hour: 12)
        guard let date = utc.date(from: components),
              utc.dateComponents([.year, .month, .day], from: date).year == year,
              utc.dateComponents([.year, .month, .day], from: date).month == month,
              utc.dateComponents([.year, .month, .day], from: date).day == day
        else { return nil }

        self.year = year
        self.month = month
        self.day = day
    }

    /// Uses noon to avoid ordinary daylight-saving transitions at midnight.
    /// Returns nil when this civil day was entirely skipped in the given zone.
    func date(calendar: Calendar = JournalDay.localCalendar) -> Date? {
        let gregorian = Self.gregorianCalendar(in: calendar.timeZone)
        let components = DateComponents(year: year, month: month, day: day, hour: 12)
        guard let date = gregorian.date(from: components),
              JournalDay(date: date, calendar: gregorian) == self
        else { return nil }
        return date
    }

    static func < (lhs: JournalDay, rhs: JournalDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    private static func gregorianCalendar(in timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}
