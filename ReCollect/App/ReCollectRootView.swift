import SwiftUI
import SwiftData

struct ReCollectRootView: View {
    @Query private var entries: [JournalEntry]
    @State private var store: JournalStore
    @State private var selectedDay: JournalDay?
    @State private var zoomAnchor = UnitPoint.center
    @State private var editor: EditorRoute?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private let onRetryRead: () -> Void

    private var reduceMotion: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--reduce-motion") { return true }
        #endif
        return systemReduceMotion
    }

    init(container: ModelContainer, onRetryRead: @escaping () -> Void) {
        var descriptor = FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\JournalEntry.createdAt)])
        descriptor.includePendingChanges = false
        _entries = Query(descriptor)
        _store = State(initialValue: JournalStore(context: container.mainContext))
        self.onRetryRead = onRetryRead
    }

    var body: some View {
        ZStack {
            PaperBackground()
                .zIndex(0)
            if _entries.fetchError != nil {
                ContentUnavailableView {
                    Label("Your journal couldn’t load", systemImage: "book.closed")
                } description: {
                    Text("ReCollect couldn’t read its local entries. Try again when your device is unlocked. Your saved journal has not been replaced.")
                } actions: {
                    Button("Try again", action: onRetryRead)
                }
            } else {
            TimelineView(entries: entries, selectedDay: selectedDay, onSelect: openDay)
                .scaleEffect(selectedDay == nil || reduceMotion ? 1 : 1.8, anchor: zoomAnchor)
                .offset(y: selectedDay == nil || reduceMotion ? 0 : -180)
                .opacity(selectedDay == nil ? 1 : 0)
                .allowsHitTesting(selectedDay == nil)
                .accessibilityHidden(selectedDay != nil)
                .zIndex(1)

            if let day = selectedDay {
                DayView(day: day, entries: entries.filter { $0.dayKey == day.key },
                        onBack: closeDay, onEdit: { entry in
                    editor = EditorRoute(day: day, entry: entry, period: entry.period)
                }, onNew: { period in
                    editor = EditorRoute(day: day, entry: nil, period: period)
                })
                .transition(reduceMotion ? .opacity : .offset(y: 160).combined(with: .opacity))
                .zIndex(2)
            }
            }
        }
        .coordinateSpace(name: "timelineRoot")
        .foregroundStyle(ReCollectTheme.ink)
        .sheet(item: $editor) { route in
            JournalEditorView(day: route.day, entry: route.entry, period: route.period, store: store)
        }
    }

    private func openDay(_ day: JournalDay, anchor: UnitPoint) {
        zoomAnchor = anchor
        withAnimation(reduceMotion ? .easeInOut(duration: 0.18) : ReCollectTheme.transition) {
            selectedDay = day
        }
    }

    private func closeDay() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.18) : ReCollectTheme.transition) {
            selectedDay = nil
        }
    }
}

private struct EditorRoute: Identifiable {
    let id = UUID()
    let day: JournalDay
    let entry: JournalEntry?
    let period: JournalPeriod
}
