import Foundation
import XCTest
@testable import ReCollect

final class JournalMonthTests: XCTestCase {
    func testDecemberIncludesEveryCivilDayDespiteSamoaSkippingADate() throws {
        let month = JournalMonth(day: try XCTUnwrap(JournalDay(key: "2011-12-01")))
        XCTAssertEqual(month.days.count, 31)
        XCTAssertEqual(month.days.map(\.day), Array(1...31))
        XCTAssertEqual(month.days.first?.key, "2011-12-01")
        XCTAssertEqual(month.days.last?.key, "2011-12-31")
        let skippedDay = try XCTUnwrap(month.days.first { $0.day == 30 })
        var samoa = Calendar(identifier: .gregorian)
        samoa.timeZone = try XCTUnwrap(TimeZone(identifier: "Pacific/Apia"))
        XCTAssertNil(skippedDay.date(calendar: samoa))
        XCTAssertEqual(skippedDay.key, "2011-12-30")
    }

    func testGregorianLeapFebruaryIncludesCorrectNumberOfDays() throws {
        for (year, count) in [(2024, 29), (2026, 28), (2000, 29), (1900, 28)] {
            let firstDay = try XCTUnwrap(JournalDay(key: "\(year)-02-01"))
            let month = JournalMonth(day: firstDay)
            XCTAssertEqual(month.days.count, count)
            XCTAssertEqual(month.days.last?.day, count)
        }
    }

    func testMonthNavigationAcrossYearsPreservesCivilIdentity() throws {
        let december = JournalMonth(day: try XCTUnwrap(JournalDay(key: "2026-12-31")))
        let january = try XCTUnwrap(december.adding(months: 1))
        XCTAssertEqual(january.year, 2027)
        XCTAssertEqual(january.month, 1)
        XCTAssertEqual(january.adding(months: -1), december)
        XCTAssertEqual(december.adding(months: 12)?.year, 2027)
        XCTAssertEqual(december.adding(months: 12)?.month, 12)
        XCTAssertEqual(december.adding(months: 0), december)
    }

    func testMonthDisplayUsesUTCNoonAndDoesNotDependOnTravel() throws {
        let month = JournalMonth(day: try XCTUnwrap(JournalDay(key: "2026-11-01")))
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        let components = utc.dateComponents([.year, .month, .day, .hour], from: month.displayDate)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 11)
        XCTAssertEqual(components.day, 1)
        XCTAssertEqual(components.hour, 12)

        var newYork = Calendar(identifier: .gregorian)
        newYork.timeZone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        let localFirst = try XCTUnwrap(newYork.date(from: DateComponents(
            year: 2026, month: 11, day: 1, hour: 0
        )))
        let selectedInNewYork = JournalMonth(date: localFirst, calendar: newYork)
        XCTAssertEqual(selectedInNewYork, month)
        // Once selected, its year/month and all keys contain no time-zone state.
        XCTAssertEqual(selectedInNewYork.days.first?.key, "2026-11-01")
        XCTAssertEqual(selectedInNewYork.days.last?.key, "2026-11-30")
    }

    func testOutOfRangeMonthNavigationReturnsNil() throws {
        let first = JournalMonth(day: try XCTUnwrap(JournalDay(key: "0001-01-01")))
        let last = JournalMonth(day: try XCTUnwrap(JournalDay(key: "9999-12-31")))
        XCTAssertNil(first.adding(months: -1))
        XCTAssertNil(last.adding(months: 1))
        XCTAssertNil(last.adding(months: Int.max))
        XCTAssertNil(first.adding(months: Int.min))
    }
}
