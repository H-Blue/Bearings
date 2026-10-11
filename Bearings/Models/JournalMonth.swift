import Foundation

/// The month being browsed is a civil identity, so travel cannot move it to
/// the preceding month by reinterpreting an absolute midnight timestamp.
struct JournalMonth: Hashable, Sendable {
    let year: Int
    let month: Int

    init(day: JournalDay) {
        year = day.year
        month = day.month
    }

    init(date: Date = Date(), calendar: Calendar = JournalDay.localCalendar) {
        self.init(day: JournalDay(date: date, calendar: calendar))
    }

    var days: [JournalDay] {
        let dayCount: Int
        switch month {
        case 2:
            let isLeapYear = year.isMultiple(of: 4)
                && (!year.isMultiple(of: 100) || year.isMultiple(of: 400))
            dayCount = isLeapYear ? 29 : 28
        case 4, 6, 9, 11:
            dayCount = 30
        default:
            dayCount = 31
        }
        // Build civil dates directly. Calendar date arithmetic in a time zone
        // can skip a date entirely (Samoa skipped December 30, 2011).
        return (1...dayCount).compactMap {
            JournalDay(key: String(format: "%04d-%02d-%02d", year, month, $0))
        }
    }

    var displayDate: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar.date(from: DateComponents(year: year, month: month, day: 1, hour: 12))!
    }

    func adding(months: Int) -> JournalMonth? {
        let currentIndex = (year - 1) * 12 + month - 1
        let (newIndex, overflow) = currentIndex.addingReportingOverflow(months)
        guard !overflow, (0..<(9999 * 12)).contains(newIndex),
              let firstDay = JournalDay(key: String(
                format: "%04d-%02d-01", newIndex / 12 + 1, newIndex % 12 + 1
              ))
        else { return nil }
        return JournalMonth(day: firstDay)
    }
}
