import XCTest
@testable import Bearings

final class JournalDayTests: XCTestCase {
    func testStrictGregorianKeyValidation() throws {
        let leapDay = try XCTUnwrap(JournalDay(key: "2024-02-29"))
        XCTAssertEqual(leapDay.year, 2024)
        XCTAssertEqual(leapDay.month, 2)
        XCTAssertEqual(leapDay.day, 29)
        XCTAssertEqual(leapDay.id, "2024-02-29")
        for invalid in ["2023-02-29", "2024-04-31", "2024-13-01", "2024-00-01",
                        "0000-01-01", "2024-01-00", "24-01-01", "2024-1-01",
                        " 2024-01-01", "2024-01-01 ", "２０２４-01-01"] {
            XCTAssertNil(JournalDay(key: invalid), "Accepted invalid civil date: \(invalid)")
        }
    }

    func testDayIdentitySurvivesDifferentTimeZones() throws {
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        for zone in ["America/New_York", "America/Los_Angeles", "Asia/Tokyo", "Pacific/Auckland"] {
            let calendar = try calendar(in: zone)
            let date = try XCTUnwrap(day.date(calendar: calendar))
            XCTAssertEqual(JournalDay(date: date, calendar: calendar).key, "2026-10-10")
            XCTAssertEqual(calendar.component(.hour, from: date), 12)
        }
        XCTAssertEqual(day.key, "2026-10-10")
    }

    func testCreationUsesLocalDayAtMidnightBoundary() throws {
        let utc = try calendar(in: "UTC")
        let newYork = try calendar(in: "America/New_York")
        let instant = try XCTUnwrap(utc.date(from: DateComponents(
            year: 2026, month: 10, day: 10, hour: 2, minute: 30
        )))
        XCTAssertEqual(JournalDay(date: instant, calendar: utc).key, "2026-10-10")
        XCTAssertEqual(JournalDay(date: instant, calendar: newYork).key, "2026-10-09")
    }

    func testDSTDaysUseCivilDatesInsteadOfTwentyFourHourIncrements() throws {
        let calendar = try calendar(in: "America/New_York")
        let beforeSpring = try XCTUnwrap(JournalDay(key: "2026-03-07"))
        let spring = try XCTUnwrap(JournalDay(key: "2026-03-08"))
        let beforeFall = try XCTUnwrap(JournalDay(key: "2026-10-31"))
        let fall = try XCTUnwrap(JournalDay(key: "2026-11-01"))
        let springDifference = try XCTUnwrap(spring.date(calendar: calendar))
            .timeIntervalSince(try XCTUnwrap(beforeSpring.date(calendar: calendar)))
        let fallDifference = try XCTUnwrap(fall.date(calendar: calendar))
            .timeIntervalSince(try XCTUnwrap(beforeFall.date(calendar: calendar)))
        XCTAssertEqual(springDifference, 23 * 60 * 60)
        XCTAssertEqual(fallDifference, 25 * 60 * 60)
        XCTAssertLessThan(beforeSpring, spring)
        XCTAssertLessThan(beforeFall, fall)
    }

    func testNonGregorianUserCalendarStillCreatesGregorianIdentity() throws {
        var buddhist = Calendar(identifier: .buddhist)
        buddhist.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Bangkok"))
        let gregorian = try calendar(in: "Asia/Bangkok")
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let instant = try XCTUnwrap(day.date(calendar: gregorian))
        XCTAssertEqual(JournalDay(date: instant, calendar: buddhist), day)
    }

    func testSkippedCivilDayDoesNotSilentlyBecomeAnotherDay() throws {
        let samoa = try calendar(in: "Pacific/Apia")
        let skippedDay = try XCTUnwrap(JournalDay(key: "2011-12-30"))
        XCTAssertNil(skippedDay.date(calendar: samoa))
        XCTAssertEqual(skippedDay.key, "2011-12-30")
    }

    private func calendar(in identifier: String) throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: identifier))
        return calendar
    }
}
