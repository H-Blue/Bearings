import SwiftUI

struct JournalEditorView: View {
    @State private var session: JournalEditorSession
    @State private var zoomState: EmotionalZoomState = .idle
    @State private var zoomTask: Task<Void, Never>?
    @State private var confirmsDelete = false
    @State private var showsMetadata = false
    @FocusState private var writing: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let analysisService: JournalAnalysisService

    private var usesCompactHeader: Bool { dynamicTypeSize >= .accessibility4 }

    init(day: JournalDay, entry: JournalEntry?, period: JournalPeriod, store: JournalStore,
         analysisService: JournalAnalysisService) {
        _session = State(initialValue: JournalEditorSession(day: day, entry: entry, period: period, store: store))
        self.analysisService = analysisService
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
                    Button(action: zoomIn) {
                        Image(systemName: "eyeglasses")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(BearingsTheme.line)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(session.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || zoomState == .loading)
                    .accessibilityLabel("Zoom in on this writing")
                    .accessibilityHint("Finds unclear language and suggests a question to explore")
                    .accessibilityIdentifier("editor.zoom")
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

                emotionalZoomPanel

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
        .onChange(of: session.body) {
            zoomTask?.cancel()
            zoomTask = nil
            zoomState = .idle
        }
        .onDisappear {
            zoomTask?.cancel()
            session.save()
        }
    }

    @ViewBuilder
    private var emotionalZoomPanel: some View {
        switch zoomState {
        case .idle:
            EmptyView()
        case .loading:
            HStack(spacing: 10) {
                ProgressView()
                Text("Looking more closely…")
            }
            .font(.footnote)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28).padding(.vertical, 12)
            .accessibilityIdentifier("editor.zoom.loading")
        case .result(let content):
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("A closer look").font(.headline)
                    Spacer(minLength: 0)
                    AIRefreshButton(
                        accessibilityLabel: "Refresh closer look",
                        accessibilityIdentifier: "editor.zoom.refresh",
                        isLoading: false,
                        action: zoomIn
                    )
                }
                if let excerpt = content.vagueExcerpt {
                    Text("“\(excerpt)”")
                        .font(.body.italic())
                        .accessibilityIdentifier("editor.zoom.excerpt")
                }
                Text(content.explanation)
                    .font(.footnote)
                    .foregroundStyle(BearingsTheme.quietInk)
                    .accessibilityIdentifier("editor.zoom.explanation")
                Text("A question to explore").font(.headline).padding(.top, 4)
                Text(content.probingQuestion)
                    .font(.body)
                    .accessibilityIdentifier("editor.zoom.question")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28).padding(.vertical, 12)
        case .unavailable(let message), .failed(let message):
            VStack(alignment: .leading, spacing: 8) {
                Text(message).font(.footnote).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("editor.zoom.error")
                Button("Try again", action: zoomIn)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("editor.zoom.retry")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28).padding(.vertical, 8)
        }
    }

    private func zoomIn() {
        let source = session.body
        guard !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        writing = false
        zoomTask?.cancel()
        zoomState = .loading
        zoomTask = Task {
            do {
                let content = try await analysisService.emotionalZoom(text: source)
                try Task.checkCancellation()
                guard session.body == source else { return }
                zoomState = .result(content)
            } catch is CancellationError {
                return
            } catch {
                guard session.body == source else { return }
                if case .unavailable(let message) = analysisService.availability {
                    zoomState = .unavailable(message)
                } else if let analysisError = error as? AnalysisError {
                    zoomState = .failed(analysisError.errorDescription ?? "A closer look isn’t available right now. Try again.")
                } else {
                    zoomState = .failed("A closer look isn’t available right now. Try again. Your writing is still here.")
                }
            }
        }
    }
}

private enum EmotionalZoomState: Equatable {
    case idle
    case loading
    case result(EmotionalZoomContent)
    case unavailable(String)
    case failed(String)
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
