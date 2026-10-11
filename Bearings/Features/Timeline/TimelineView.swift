import SwiftUI

struct TimelineView: View {
    let entries: [JournalEntry]
    var emotions: [String: JournalEmotion] = [:]
    let selectedDay: JournalDay?
    let onSelect: (JournalDay, UnitPoint) -> Void
    let onSettings: () -> Void
    @State private var month = JournalMonth()
    @State private var pickerDate = Date()
    @State private var showsDatePicker = false
    @State private var showsMonthLabel = false
    @State private var monthLabelDismissTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
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
            timelineContent(viewport: viewport)
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
            HStack {
                Button(action: onSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 21, weight: .regular))
                        .foregroundStyle(BearingsTheme.systemControl)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Settings")
                .accessibilityHint("Open Settings")
                .accessibilityIdentifier("timeline.settings")
                Spacer()
                Button {
                    month = JournalMonth()
                    onSelect(JournalDay(date: Date()), .center)
                } label: {
                    FountainPenIcon()
                        .stroke(BearingsTheme.line, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(40))
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Write today")
                .accessibilityHint("Open today's journal")
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
                    ZStack {
                        if showsMonthLabel {
                            Text(JournalDay.format(month.displayDate, template: "MMMM yyyy"))
                                .font(.headline)
                                .transition(.opacity)
                        } else {
                            Image(systemName: "calendar")
                                .transition(.opacity)
                        }
                    }
                    .frame(minWidth: 140, minHeight: 44)
                }
                .accessibilityLabel(showsMonthLabel
                                    ? JournalDay.format(month.displayDate, template: "MMMM yyyy")
                                    : "Choose date")
                .accessibilityValue(JournalDay.format(month.displayDate, template: "MMMM yyyy"))
                .accessibilityIdentifier("timeline.datePicker")
                Spacer(minLength: 0)
                Button { moveMonth(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .accessibilityLabel("Next month").accessibilityIdentifier("timeline.nextMonth")
            }
            .padding(.horizontal, 20).padding(.top, 24)
            GeometryReader { scrollArea in
                // Center the horizontal axis in the safe-area viewport, while
                // keeping the native scroll surface reachable near the bottom.
                let headerHeight = viewport.size.height - scrollArea.size.height
                let axisOffset = markerAreaHeight + 10 + 55
                let topInset = max(24, viewport.size.height / 2 - headerHeight - axisOffset)
                ScrollViewReader { proxy in
                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(days) { day in
                                GeometryReader { tick in
                                    TimelineDayTick(day: day, count: counts[day.key, default: 0],
                                                    emotion: emotions[day.key],
                                                    cellWidth: dayCellWidth,
                                                    markerAreaHeight: markerAreaHeight,
                                                    onSelect: {
                                        let frame = tick.frame(in: .named("timelineRoot"))
                                        onSelect(day, UnitPoint(
                                            x: min(max(frame.midX / viewport.size.width, 0), 1),
                                            y: min(max((frame.minY + axisOffset) / viewport.size.height, 0), 1)
                                        ))
                                    })
                                }
                                .frame(width: dayCellWidth, height: dayCellHeight)
                                .id(day.key)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, topInset)
                        .frame(minHeight: scrollArea.size.height, alignment: .top)
                        .contentShape(Rectangle())
                    }
                    .scrollIndicators(.hidden)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 8)
                            .onChanged { value in
                                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                revealMonthLabel(scheduleDismissal: false)
                            }
                            .onEnded { value in
                                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                revealMonthLabel(scheduleDismissal: true)
                            }
                    )
                    .accessibilityIdentifier("timeline.scroll")
                    .onAppear { scrollToFocus(proxy) }
                    .onChange(of: month) { _, _ in scrollToFocus(proxy) }
                }
            }
        }
        .buttonStyle(.plain)
        .onDisappear { monthLabelDismissTask?.cancel() }
    }

    private func moveMonth(_ amount: Int) {
        if let next = month.adding(months: amount) {
            month = next
            revealMonthLabel(scheduleDismissal: true)
        }
    }

    private func revealMonthLabel(scheduleDismissal: Bool) {
        monthLabelDismissTask?.cancel()
        if !showsMonthLabel {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                showsMonthLabel = true
            }
        }
        guard scheduleDismissal else { return }
        monthLabelDismissTask = Task {
            do { try await Task.sleep(for: .seconds(5)) } catch { return }
            guard !Task.isCancelled else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                showsMonthLabel = false
            }
        }
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
    let emotion: JournalEmotion?
    let cellWidth: CGFloat
    let markerAreaHeight: CGFloat
    let onSelect: () -> Void
    private var major: Bool { AnalysisPeriod.isWeekStart(day) }

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
                    Rectangle().fill(BearingsTheme.line).frame(height: 1)
                    Rectangle().fill(BearingsTheme.line).frame(width: 1, height: major ? 110 : 56)
                }.frame(height: 110)
                Text("\(day.day)").font(.caption).monospacedDigit()
                    .fixedSize(horizontal: true, vertical: true)
                    .overlay(alignment: .topTrailing) {
                        if let emotion {
                            EmotionIndicator(emotion: emotion)
                                .offset(x: 14, y: -7)
                        }
                    }
            }
            .frame(width: cellWidth)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("\(day.longLabel), \(count) \(count == 1 ? "entry" : "entries")\(emotion.map { ", \($0.title)" } ?? "")")
        .accessibilityHint("Open this day")
        .accessibilityIdentifier("timeline.openDay.\(day.key)")
    }
}

/// A small fountain pen: capped barrel, shoulders, split nib and breather hole.
private struct FountainPenIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width / 28, y: rect.minY + y * rect.height / 28)
        }
        path.move(to: point(11, 3))
        path.addQuadCurve(to: point(17, 3), control: point(14, 0))
        path.addLine(to: point(17, 16))
        path.addLine(to: point(19, 20))
        path.addLine(to: point(14, 27))
        path.addLine(to: point(9, 20))
        path.addLine(to: point(11, 16))
        path.closeSubpath()
        path.move(to: point(11, 7))
        path.addLine(to: point(17, 7))
        path.move(to: point(11, 16))
        path.addLine(to: point(17, 16))
        path.move(to: point(14, 22))
        path.addLine(to: point(14, 27))
        path.addEllipse(in: CGRect(x: point(13, 20).x, y: point(13, 20).y,
                                  width: rect.width / 14, height: rect.height / 14))
        path.move(to: point(19, 4))
        path.addLine(to: point(19, 11))
        return path
    }
}
