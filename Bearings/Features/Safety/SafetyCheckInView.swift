import SwiftUI

struct SafetyCheckInView: View {
    @State private var session: SafetyCheckInSession
    @State private var secondsRemaining: Int
    @State private var timerTask: Task<Void, Never>?
    @State private var showsContactCreation = false
    @State private var showsSupport = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    init(contactStore: TrustedContactStore, pinger: any TrustedContactPinging, offerSeconds: Int) {
        self.contactStore = contactStore
        _session = State(initialValue: SafetyCheckInSession(contactStore: contactStore, pinger: pinger))
        _secondsRemaining = State(initialValue: max(1, offerSeconds))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch session.stage {
                case .offer: offer
                case .recipients: recipients
                case .message: messageReview
                case .unavailable: unavailable
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(BearingsTheme.paper)
            .navigationTitle("A private check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }.accessibilityIdentifier("safety.notNow")
                }
            }
            .navigationDestination(isPresented: $showsContactCreation) {
                TrustedContactsView(store: contactStore)
            }
            .navigationDestination(isPresented: $showsSupport) { ProfessionalSupportView() }
        }
        .foregroundStyle(BearingsTheme.ink).tint(BearingsTheme.ink)
        .interactiveDismissDisabled(false)
        .task { startTimer() }
        .onChange(of: session.stage) { _, stage in if stage != .offer { timerTask?.cancel() } }
        .onChange(of: contactStore.revision) { _, _ in
            if session.stage == .recipients { session.loadContacts() }
        }
        .onChange(of: scenePhase) { _, phase in if phase != .active { dismiss() } }
        .onDisappear { timerTask?.cancel() }
        .accessibilityIdentifier("safety.screen")
    }

    private let contactStore: TrustedContactStore

    private var offer: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "person.2.circle").font(.largeTitle).foregroundStyle(BearingsTheme.line)
                .accessibilityHidden(true)
            Text("Some of your words describe hurting yourself or someone else. Bearings may be misunderstanding them. Would you like to reach out to someone you trust?")
                .font(.title3).fixedSize(horizontal: false, vertical: true)
            Text("This offer closes in \(secondsRemaining) seconds. Nothing will be sent automatically.")
                .font(.footnote).foregroundStyle(BearingsTheme.quietInk)
                .accessibilityIdentifier("safety.timer")
            Button("Reach out") { session.beginReachOut() }
                .buttonStyle(.borderedProminent).tint(BearingsTheme.line)
                .frame(minHeight: 44).accessibilityIdentifier("safety.reachOut")
            Button("Professional or emergency support") { showsSupport = true }
                .frame(minHeight: 44).accessibilityIdentifier("safety.support")
            Spacer()
        }
    }

    private var recipients: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose who you want to contact").font(.title3.weight(.semibold))
            if let error = session.errorMessage {
                Text(error).font(.footnote)
                Button("Try again") { session.loadContacts() }.frame(minHeight: 44)
            } else if session.enabledContacts.isEmpty {
                Text("You do not have an enabled trusted contact yet.").foregroundStyle(BearingsTheme.quietInk)
                Button("Add a trusted contact") { showsContactCreation = true }
                    .frame(minHeight: 44).accessibilityIdentifier("safety.addContact")
            } else {
                ForEach(session.enabledContacts) { contact in
                    Toggle(isOn: recipientBinding(contact.id)) {
                        VStack(alignment: .leading) {
                            Text(contact.displayName)
                            Text(contact.phoneNumber).font(.footnote).foregroundStyle(BearingsTheme.quietInk)
                        }
                    }
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("safety.recipient.\(contact.id.uuidString)")
                }
                Button("Review message") { session.reviewMessage() }
                    .buttonStyle(.borderedProminent).tint(BearingsTheme.line)
                    .disabled(session.selectedRecipients.isEmpty)
                    .frame(minHeight: 44).accessibilityIdentifier("safety.reviewMessage")
            }
            Button("Professional or emergency support") { showsSupport = true }
                .frame(minHeight: 44).accessibilityIdentifier("safety.support")
            Spacer()
        }
    }

    private var messageReview: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review the exact message").font(.title3.weight(.semibold))
            Text("To: \(session.selectedRecipients.map(\.displayName).joined(separator: ", "))")
                .accessibilityIdentifier("safety.selectedRecipients")
            TextEditor(text: $session.message)
                .frame(minHeight: 150).padding(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(BearingsTheme.line, lineWidth: 1))
                .accessibilityLabel("Message to trusted contacts")
                .accessibilityIdentifier("safety.message")
            Text("Your journal writing and Bearings’ interpretations are not attached.")
                .font(.footnote).foregroundStyle(BearingsTheme.quietInk)
            Button("Send") { Task { await session.finalSend() } }
                .buttonStyle(.borderedProminent).tint(BearingsTheme.line)
                .disabled(session.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .frame(minHeight: 44).accessibilityIdentifier("safety.finalSend")
            Button("Change recipients") { session.returnToRecipients() }.frame(minHeight: 44)
            Spacer()
        }
    }

    private var unavailable: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(session.errorMessage ?? "Sending is not available in this build.").font(.title3)
                .accessibilityIdentifier("safety.unavailable")
            Text("No message was sent.").foregroundStyle(BearingsTheme.quietInk)
            Button("Review again") { session.returnToRecipients() }.frame(minHeight: 44)
            Button("Done") { dismiss() }.frame(minHeight: 44)
            Spacer()
        }
    }

    private func recipientBinding(_ id: UUID) -> Binding<Bool> {
        Binding(get: { session.selectedRecipientIDs.contains(id) }, set: { selected in
            if selected { session.selectedRecipientIDs.insert(id) }
            else { session.selectedRecipientIDs.remove(id) }
        })
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while secondsRemaining > 0 {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                guard !Task.isCancelled, session.stage == .offer else { return }
                secondsRemaining -= 1
            }
            dismiss()
        }
    }
}
