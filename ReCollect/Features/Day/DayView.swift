import SwiftUI

struct DayView: View {
    let day: JournalDay
    let entries: [JournalEntry]
    let onBack: () -> Void
    let onEdit: (JournalEntry) -> Void
    let onNew: (JournalPeriod) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) { Label("Timeline", systemImage: "chevron.left").frame(minHeight: 44) }
                    .accessibilityIdentifier("day.back")
                Spacer()
                Button { onNew(currentPeriod) } label: { Label("Write", systemImage: "square.and.pencil").frame(minHeight: 44) }
                    .accessibilityIdentifier("day.newEntry")
            }
            .padding(.horizontal, 24).padding(.top, 12)
            Text(day.longLabel).font(.title2).multilineTextAlignment(.center).padding(.horizontal, 24).padding(.top, 20)
            ScrollView {
                VStack(spacing: 20) {
                    dayBranches
                    if entries.isEmpty {
                        Text("A place for this day.\nChoose morning, midday, or evening to begin.")
                            .font(.body).foregroundStyle(ReCollectTheme.quietInk).multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(entries) { entry in
                                Button { onEdit(entry) } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(entry.period.title).font(.caption.weight(.medium)).foregroundStyle(ReCollectTheme.quietInk)
                                        Text(excerpt(entry.body)).font(.body).lineLimit(3).multilineTextAlignment(.leading)
                                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 20).contentShape(Rectangle())
                                }
                                .accessibilityLabel(excerpt(entry.body))
                                .accessibilityHint("Edit \(entry.period.title.lowercased()) entry")
                                .accessibilityIdentifier("day.entry.\(entry.id.uuidString)")
                                Divider().overlay(ReCollectTheme.ink.opacity(0.25))
                            }
                        }.padding(.horizontal, 32)
                    }
                }.padding(.bottom, 32)
            }
        }
        .buttonStyle(.plain)
        .background(ReCollectTheme.paper)
    }

    private var dayBranches: some View {
        VStack(spacing: 0) {
            periodButton(.midday)
            HStack(alignment: .center) {
                periodButton(.morning)
                Spacer(minLength: 12)
                periodButton(.evening)
            }.padding(.top, 56)
        }
        .padding(.horizontal, 36).padding(.top, 28).padding(.bottom, 90)
        .background {
            GeometryReader { geometry in
                Path { path in
                    let center = geometry.size.width / 2
                    let branch = geometry.size.height - 32
                    path.move(to: CGPoint(x: center, y: 138))
                    path.addLine(to: CGPoint(x: center, y: geometry.size.height))
                    path.move(to: CGPoint(x: center, y: branch))
                    path.addLine(to: CGPoint(x: 115, y: branch - 75))
                    path.move(to: CGPoint(x: center, y: branch))
                    path.addLine(to: CGPoint(x: geometry.size.width - 115, y: branch - 75))
                }.stroke(ReCollectTheme.ink, lineWidth: 1)
            }.allowsHitTesting(false).accessibilityHidden(true)
        }
    }

    private func periodButton(_ period: JournalPeriod) -> some View {
        let count = entries.filter { $0.period == period }.count
        return Button {
            if let entry = entries.last(where: { $0.period == period }) { onEdit(entry) }
            else { onNew(period) }
        } label: {
            VStack(spacing: 10) {
                Circle().fill(ReCollectTheme.marker).frame(width: 80, height: 80)
                    .overlay {
                        if count > 0 { Text("\(count)").font(.title3).foregroundStyle(ReCollectTheme.ink) }
                    }
                Text(period.title).font(.subheadline)
                    .padding(.horizontal, 4)
                    .background(ReCollectTheme.paper)
            }.frame(minWidth: 80, minHeight: 110)
        }
        .accessibilityLabel("\(period.title), \(count) \(count == 1 ? "entry" : "entries")")
        .accessibilityHint(count == 0 ? "Write an entry" : "Open the latest entry")
        .accessibilityIdentifier("day.period.\(period.rawValue)")
    }

    private var currentPeriod: JournalPeriod {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour < 12 ? .morning : hour < 17 ? .midday : .evening
    }

    private func excerpt(_ body: String) -> String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled entry" : String(trimmed.prefix(180))
    }
}
