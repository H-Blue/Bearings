import SwiftUI

enum BearingsTheme {
    static let paper = Color("Paper")
    static let ink = Color("Ink")
    static let marker = Color("Marker")
    static let quietInk = Color("Ink").opacity(0.65)
    static let transition = Animation.spring(response: 0.55, dampingFraction: 0.88)
}

struct PaperBackground: View {
    var body: some View {
        BearingsTheme.paper.ignoresSafeArea()
    }
}

extension JournalDay {
    var displayDate: Date {
        // Format civil components in UTC so travel never changes the displayed date.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return date(calendar: calendar) ?? .distantPast
    }

    var longLabel: String {
        Self.format(displayDate, template: "EEEE MMMM d yyyy")
    }

    var shortLabel: String {
        Self.format(displayDate, template: "EEE MMM d")
    }

    static func format(_ date: Date, template: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }
}
