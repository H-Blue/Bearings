import SwiftUI

struct JournalEditorView: View {
    @State private var session: JournalEditorSession
    @State private var confirmsDelete = false
    @State private var showsMetadata = false
    @FocusState private var writing: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var usesCompactHeader: Bool { dynamicTypeSize >= .accessibility4 }

    init(day: JournalDay, entry: JournalEntry?, period: JournalPeriod, store: JournalStore) {
        _session = State(initialValue: JournalEditorSession(day: day, entry: entry, period: period, store: store))
    }

    var body: some View {
        @Bindable var session = session
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 24) {
                    if !usesCompactHeader {
                        Image("EditorCircle").resizable().scaledToFit().frame(width: 78, height: 66).accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(session.day.shortLabel).font(usesCompactHeader ? .caption : .title3)
                            .fixedSize(horizontal: false, vertical: true)
                        Picker("Time of day", selection: $session.period) {
                            ForEach(JournalPeriod.allCases) { period in Text(period.title).tag(period) }
                        }
                        .pickerStyle(.menu).padding(.leading, -12)
                        .font(usesCompactHeader ? .caption : .body)
                        .accessibilityIdentifier("editor.period")
                    }
                    Spacer(minLength: 0)
                }.padding(.horizontal, 32).padding(.top, 12).padding(.bottom, 20)
                Image("EditorRule").resizable().frame(height: 1).padding(.horizontal, 34).accessibilityHidden(true)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $session.body)
                        .font(.title3).lineSpacing(3)
                        .scrollContentBackground(.hidden)
                        .foregroundStyle(BearingsTheme.ink)
                        .focused($writing)
                        .accessibilityLabel("Journal entry")
                        .accessibilityIdentifier("editor.body")
                    if session.body.isEmpty {
                        Text("What would you like to remember?")
                            .font(.body).foregroundStyle(BearingsTheme.quietInk)
                            .padding(.top, 8).padding(.leading, 5)
                            .allowsHitTesting(false).accessibilityHidden(true)
                    }
                }.padding(.horizontal, 28).padding(.top, 24)

                if session.saveState == .failed || session.deleteFailed {
                    HStack(alignment: .center, spacing: 12) {
                        Text(session.deleteFailed ? "Your entry couldn’t be deleted. Try again." : "Your changes couldn’t be saved. Keep this page open and try again.")
                            .font(.footnote).fixedSize(horizontal: false, vertical: true)
                        Button("Try again") {
                            if session.deleteFailed {
                                if session.delete() { writing = false; dismiss() }
                            } else { session.save() }
                        }
                            .frame(minHeight: 44).accessibilityIdentifier("editor.retry")
                    }.padding(.horizontal, 28).padding(.vertical, 8)
                }
                HStack(spacing: 12) {
                    Text(session.status).font(.caption).foregroundStyle(BearingsTheme.quietInk)
                        .accessibilityIdentifier("editor.saved")
                    Spacer()
                    if writing {
                        Button { writing = false } label: {
                            Label("Hide keyboard", systemImage: "keyboard.chevron.compact.down")
                                .labelStyle(.iconOnly)
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("editor.hideKeyboard")
                    }
                }
                .padding(.horizontal, 28).padding(.vertical, 12)
            }
            .background(BearingsTheme.paper)
            .navigationTitle("Your journal").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BearingsTheme.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        if session.save() { writing = false; dismiss() }
                    }.accessibilityIdentifier("editor.done")
                }
                ToolbarItem(placement: .topBarLeading) {
                    if session.entry != nil {
                        Button(role: .destructive) { confirmsDelete = true } label: { Image(systemName: "trash") }
                            .accessibilityLabel("Delete entry").accessibilityIdentifier("editor.delete")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        writing = false
                        showsMetadata = true
                    } label: {
                        Image(systemName: "calendar.badge.clock")
                    }
                    .accessibilityLabel("Entry date and details")
                    .accessibilityIdentifier("editor.metadata")
                }
            }
            .sheet(isPresented: $showsMetadata) {
                EntryMetadataView(session: session)
            }
            .alert("Delete Entry", isPresented: $confirmsDelete) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if session.delete() { writing = false; dismiss() }
                }
            } message: { Text("This removes this entry from your journal.") }
        }
        .foregroundStyle(BearingsTheme.ink).tint(BearingsTheme.ink)
        .interactiveDismissDisabled(session.hasUnsavedChanges)
        .task(id: EditRevision(body: session.body, period: session.period, day: session.day)) {
            guard session.hasUnsavedChanges else { return }
            do { try await Task.sleep(for: .milliseconds(350)) } catch { return }
            guard !Task.isCancelled else { return }
            session.save()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { session.save() }
        }
        .onDisappear { session.save() }
    }
}

private struct EditRevision: Equatable {
    let body: String
    let period: JournalPeriod
    let day: JournalDay
}

private struct EntryMetadataView: View {
    @Bindable var session: JournalEditorSession
    @Environment(\.dismiss) private var dismiss

    // A civil date picker stays Gregorian even when the system calendar or
    // time zone changes. Its Date is only a presentation value, never identity.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private var selectedDate: Binding<Date> {
        Binding(get: { session.day.displayDate }, set: { session.day = JournalDay(date: $0, calendar: calendar) })
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Journal day", selection: selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .environment(\.calendar, calendar)
                        .environment(\.timeZone, calendar.timeZone)
                        .accessibilityIdentifier("editor.journalDay")
                    Text("Choose the day this memory belongs to. Its creation time stays the same.")
                        .font(.footnote).foregroundStyle(BearingsTheme.quietInk)
                } header: { Text("Journal day") }
                Section("Saved details") {
                    if let entry = session.entry {
                        LabeledContent("Created") {
                            Text(timestamp(entry.createdAt, zone: entry.createdTimeZoneIdentifier))
                                .accessibilityIdentifier("editor.createdAt")
                        }
                        if let identifier = entry.createdTimeZoneIdentifier {
                            LabeledContent("Creation time zone") {
                                Text(identifier).accessibilityIdentifier("editor.creationTimeZone")
                            }
                        } else {
                            Text("Original time zone is unknown for this earlier entry.")
                                .font(.footnote).foregroundStyle(BearingsTheme.quietInk)
                        }
                        LabeledContent("Last edited") {
                            Text(timestamp(entry.modifiedAt)).accessibilityIdentifier("editor.modifiedAt")
                        }
                    } else {
                        Text("Creation details appear after this entry is saved.")
                            .foregroundStyle(BearingsTheme.quietInk)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(BearingsTheme.paper)
            .navigationTitle("Entry details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("editor.metadataDone")
                }
            }
        }
        .foregroundStyle(BearingsTheme.ink).tint(BearingsTheme.ink)
    }

    private func timestamp(_ date: Date, zone: String? = nil) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.timeZone = zone.flatMap(TimeZone.init(identifier:)) ?? .current
        return formatter.string(from: date)
    }
}
