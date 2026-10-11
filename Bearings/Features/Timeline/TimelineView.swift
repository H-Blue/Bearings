import SwiftUI

struct TimelineView: View {
    let entries: [JournalEntry]
    let selectedDay: JournalDay?
    let onSelect: (JournalDay, UnitPoint) -> Void
    @State private var month = JournalMonth()
    @State private var pickerDate = Date()
    @State private var showsDatePicker = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var dateCaptionAllowance: CGFloat = 20
    @ScaledMetric(relativeTo: .caption2) private var markerCaptionAllowance: CGFloat = 16

    private var days: [JournalDay] { month.days }
    private var counts: [String: Int] { Dictionary(grouping: entries, by: \.dayKey).mapValues(\.count) }
    // Keep the reference spacing at regular sizes while reserving enough room
    // for a native, single-line two-digit caption at accessibility sizes.
    private var dayCellWidth: CGFloat { max(44, dateCaptionAllowance + 12) }
    private var markerAreaHeight: CGFloat {
        let largestCount = days.map { counts[$0.key, default: 0] }.max() ?? 0
        // Minor ticks reserve 26 points below their markers. Three dots plus
        // gaps need 75 points; an extra-count caption adds its native allowance.
        if largestCount > 3 { return 80 + markerCaptionAllowance }
        return largestCount == 3 ? 75 : 70
    }
    // Use one marker height for the entire month so every tick stays aligned.
    private var dayCellHeight: CGFloat { markerAreaHeight + 130 + max(35, dateCaptionAllowance + 12) }

    var body: some View {
        GeometryReader { viewport in
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView(.vertical) {
                    timelineContent(viewport: viewport)
                        .frame(minHeight: viewport.size.height)
                }
                .scrollIndicators(.hidden)
            } else {
                timelineContent(viewport: viewport)
            }
        }
        .sheet(isPresented: $showsDatePicker) {
            NavigationStack {
                DatePicker("Choose a day", selection: $pickerDate, displayedComponents: .date)
                    .datePickerStyle(.graphical).padding()
                    .environment(\.calendar, JournalDay.localCalendar)
                    .navigationTitle("Return to a day").navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showsDatePicker = false } }
                        ToolbarItem(placement: .confirmationAction) { Button("Open") {
                            month = JournalMonth(date: pickerDate)
                            showsDatePicker = false
                            onSelect(JournalDay(date: pickerDate), .center)
                        } }
                    }
            }.presentationDetents([.medium, .large])
        }
    }

    private func timelineContent(viewport: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bearings").font(.largeTitle.weight(.medium))
                    Text("Find what’s been lost inside.").font(.subheadline).foregroundStyle(BearingsTheme.quietInk)
                }
                Spacer(minLength: 10)
                Button("Today") {
                    month = JournalMonth()
                    onSelect(JournalDay(date: Date()), .center)
                }
                .font(.body)
                .frame(minHeight: 44)
                .accessibilityIdentifier("timeline.today")
            }
            .padding(.horizontal, 24).padding(.top, 24)

            HStack(spacing: 12) {
                Button { moveMonth(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .accessibilityLabel("Previous month").accessibilityIdentifier("timeline.previousMonth")
                Spacer(minLength: 0)
                Button {
                    pickerDate = month.days.first?.date() ?? month.displayDate
                    showsDatePicker = true
                } label: {
                    Text(JournalDay.format(month.displayDate, template: "MMMM yyyy")).font(.headline).frame(minHeight: 44)
                }
                .accessibilityLabel("Choose date").accessibilityIdentifier("timeline.datePicker")
                Spacer(minLength: 0)
                Button { moveMonth(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .accessibilityLabel("Next month").accessibilityIdentifier("timeline.nextMonth")
            }
            .padding(.horizontal, 20).padding(.top, 24)
            Spacer(minLength: 24)
            ScrollViewReader { proxy in
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(days) { day in
                            GeometryReader { tick in
                                TimelineDayTick(day: day, count: counts[day.key, default: 0],
                                                cellWidth: dayCellWidth,
                                                markerAreaHeight: markerAreaHeight,
                                                onSelect: {
                                    let frame = tick.frame(in: .named("timelineRoot"))
                                    onSelect(day, UnitPoint(
                                        x: min(max(frame.midX / viewport.size.width, 0), 1),
                                        y: min(max((frame.minY + 80) / viewport.size.height, 0), 1)
                                    ))
                                })
                            }
                            .frame(width: dayCellWidth, height: dayCellHeight)
                            .id(day.key)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .scrollIndicators(.hidden)
                .frame(height: dayCellHeight)
                .onAppear { scrollToFocus(proxy) }
                .onChange(of: month) { _, _ in scrollToFocus(proxy) }
            }
            Spacer(minLength: 24)
            Text(entries.isEmpty ? "Your story begins with a day." : "Choose a day to return to your story.")
                .font(.subheadline).foregroundStyle(BearingsTheme.quietInk)
                .multilineTextAlignment(.center).padding(.horizontal, 24).padding(.bottom, 28)
        }
        .buttonStyle(.plain)
    }

    private func moveMonth(_ amount: Int) {
        if let next = month.adding(months: amount) { month = next }
    }

    private func scrollToFocus(_ proxy: ScrollViewProxy) {
        let today = JournalDay(date: Date())
        let focus = selectedDay?.key ?? (days.contains(today) ? today.key : days.first?.key)
        if let focus { proxy.scrollTo(focus, anchor: .center) }
    }
}

private struct TimelineDayTick: View {
    let day: JournalDay
    let count: Int
    let cellWidth: CGFloat
    let markerAreaHeight: CGFloat
    let onSelect: () -> Void
    private var major: Bool { (day.day - 1) % 7 == 0 }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 10) {
                ZStack(alignment: .bottom) {
                    VStack(spacing: 5) {
                        if count > 3 {
                            Text("+\(count - 3)").font(.caption2).foregroundStyle(BearingsTheme.ink)
                                .fixedSize(horizontal: true, vertical: true)
                        }
                        ForEach(0..<min(count, 3), id: \.self) { _ in
                            Circle().fill(BearingsTheme.marker).frame(width: 13, height: 13)
                        }
                        if count == 0 {
                            Color.clear.frame(width: 13, height: 13)
                        }
                    }
                    .padding(.bottom, major ? 0 : 26)
                }.frame(height: markerAreaHeight)
                ZStack {
                    Rectangle().fill(BearingsTheme.ink).frame(height: 1)
                    Rectangle().fill(BearingsTheme.ink).frame(width: 1, height: major ? 110 : 56)
                }.frame(height: 110)
                Text("\(day.day)").font(.caption).monospacedDigit()
                    .fixedSize(horizontal: true, vertical: true)
            }
            .frame(width: cellWidth)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("\(day.longLabel), \(count) \(count == 1 ? "entry" : "entries")")
        .accessibilityHint("Open this day")
        .accessibilityIdentifier("timeline.openDay.\(day.key)")
    }
}
