import SwiftUI

enum BearingsTheme {
    static let paper = Color("Paper")
    static let ink = Color("Ink")
    static let line = Color("Line")
    static let marker = Color("Marker")
    static let systemControl = marker
    static let quietInk = Color("Ink").opacity(0.65)
    static let transition = Animation.spring(response: 0.55, dampingFraction: 0.88)
}

struct PaperBackground: View {
    var body: some View {
        BearingsTheme.paper.ignoresSafeArea()
    }
}

struct AIRefreshButton: View {
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SextantSymbol()
                .stroke(BearingsTheme.line, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                .frame(width: 24, height: 24)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Generate a new on-device AI interpretation")
        .accessibilityIdentifier(accessibilityIdentifier)
    }
}

private struct SextantSymbol: Shape {
    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 24
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * scale, y: y * scale) }
        var path = Path()
        path.move(to: point(4, 4))
        path.addLine(to: point(20, 4))
        path.move(to: point(4, 4))
        path.addLine(to: point(4, 20))
        path.addArc(center: point(4, 4), radius: 16 * scale,
                    startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.move(to: point(2, 20))
        path.addLine(to: point(20, 2))
        path.move(to: point(11, 11))
        path.addLine(to: point(18, 20))
        path.addEllipse(in: CGRect(x: 2.5 * scale, y: 2.5 * scale, width: 3 * scale, height: 3 * scale))
        return path
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
