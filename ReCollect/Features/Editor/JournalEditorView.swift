import SwiftUI

struct JournalEditorView: View {
    @State private var session: JournalEditorSession
    @State private var confirmsDelete = false
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
                        .foregroundStyle(ReCollectTheme.ink)
                        .focused($writing)
                        .accessibilityLabel("Journal entry")
                        .accessibilityIdentifier("editor.body")
                    if session.body.isEmpty {
                        Text("What would you like to remember?")
                            .font(.body).foregroundStyle(ReCollectTheme.quietInk)
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
                    Text(session.status).font(.caption).foregroundStyle(ReCollectTheme.quietInk)
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
            .background(ReCollectTheme.paper)
            .navigationTitle("Your journal").navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(ReCollectTheme.paper, for: .navigationBar)
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
            }
            .alert("Delete Entry", isPresented: $confirmsDelete) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if session.delete() { writing = false; dismiss() }
                }
            } message: { Text("This removes this entry from your journal.") }
        }
        .foregroundStyle(ReCollectTheme.ink).tint(ReCollectTheme.ink)
        .interactiveDismissDisabled(session.hasUnsavedChanges)
        .task(id: EditRevision(body: session.body, period: session.period)) {
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
}
