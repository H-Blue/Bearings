import SwiftUI

struct TrustedContactsView: View {
    let store: TrustedContactStore
    @State private var contacts: [TrustedContactSnapshot] = []
    @State private var route: ContactEditorRoute?
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(BearingsTheme.ink)
                    Button("Try again", action: load).frame(minHeight: 44)
                        .accessibilityIdentifier("contacts.retry")
                }
            }
            Section {
                if contacts.isEmpty && errorMessage == nil {
                    Text("No trusted contacts yet.").foregroundStyle(BearingsTheme.quietInk)
                }
                ForEach(contacts) { contact in
                    Button { route = ContactEditorRoute(contact: contact) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contact.displayName)
                                Text(contact.phoneNumber).font(.footnote).foregroundStyle(BearingsTheme.quietInk)
                            }
                            Spacer()
                            Image(systemName: contact.isEnabled ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(BearingsTheme.line)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityLabel("\(contact.displayName), \(contact.phoneNumber), \(contact.isEnabled ? "enabled" : "disabled")")
                    .accessibilityHint("Edit trusted contact")
                    .accessibilityIdentifier("contacts.row.\(contact.id.uuidString)")
                }
            } footer: {
                Text("Add contacts manually. Bearings does not request access to your Contacts app.")
            }
        }
        .scrollContentBackground(.hidden).background(BearingsTheme.paper)
        .navigationTitle("Trusted contacts")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { route = ContactEditorRoute(contact: nil) } label: {
                    Label("Add trusted contact", systemImage: "plus").frame(minWidth: 44, minHeight: 44)
                }
                .accessibilityIdentifier("contacts.add")
            }
        }
        .sheet(item: $route) { route in
            TrustedContactEditorView(store: store, contact: route.contact) { load() }
        }
        .task { load() }
        .onChange(of: store.revision) { _, _ in load() }
        .accessibilityIdentifier("contacts.screen")
    }

    private func load() {
        do { contacts = try store.contacts(); errorMessage = nil }
        catch { errorMessage = "Trusted contacts couldn’t be loaded. Try again." }
    }
}

private struct ContactEditorRoute: Identifiable {
    let id = UUID()
    let contact: TrustedContactSnapshot?
}

private struct TrustedContactEditorView: View {
    let store: TrustedContactStore
    let contact: TrustedContactSnapshot?
    let onSaved: () -> Void
    @State private var displayName: String
    @State private var phoneNumber: String
    @State private var isEnabled: Bool
    @State private var errorMessage: String?
    @State private var confirmsDelete = false
    @Environment(\.dismiss) private var dismiss

    init(store: TrustedContactStore, contact: TrustedContactSnapshot?, onSaved: @escaping () -> Void) {
        self.store = store; self.contact = contact; self.onSaved = onSaved
        _displayName = State(initialValue: contact?.displayName ?? "")
        _phoneNumber = State(initialValue: contact?.phoneNumber ?? "")
        _isEnabled = State(initialValue: contact?.isEnabled ?? true)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $displayName).textContentType(.name)
                        .accessibilityIdentifier("contact.name")
                    TextField("Phone number", text: $phoneNumber).textContentType(.telephoneNumber)
                        .keyboardType(.phonePad).accessibilityIdentifier("contact.phone")
                    Toggle("Enabled", isOn: $isEnabled).accessibilityIdentifier("contact.enabled")
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                        Button("Try again", action: save).frame(minHeight: 44)
                            .accessibilityIdentifier("contact.retry")
                    }
                }
                if contact != nil {
                    Section {
                        Button("Remove trusted contact", role: .destructive) { confirmsDelete = true }
                            .frame(minHeight: 44).accessibilityIdentifier("contact.delete")
                    }
                }
            }
            .scrollContentBackground(.hidden).background(BearingsTheme.paper)
            .navigationTitle(contact == nil ? "Add contact" : "Edit contact")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).accessibilityIdentifier("contact.save")
                }
            }
            .alert("Remove trusted contact?", isPresented: $confirmsDelete) {
                Button("Cancel", role: .cancel) {}
                Button("Remove", role: .destructive, action: remove)
            } message: { Text("This removes the contact from Bearings.") }
        }
        .foregroundStyle(BearingsTheme.ink).tint(BearingsTheme.systemControl)
    }

    private func save() {
        do {
            if let contact { try store.update(contact.id, displayName: displayName, phoneNumber: phoneNumber, isEnabled: isEnabled) }
            else { try store.create(displayName: displayName, phoneNumber: phoneNumber, isEnabled: isEnabled) }
            errorMessage = nil; onSaved(); dismiss()
        } catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "This contact couldn’t be saved. Try again."
        } catch { errorMessage = "This contact couldn’t be saved. Try again." }
    }

    private func remove() {
        guard let contact else { return }
        do { try store.delete(contact.id); errorMessage = nil; onSaved(); dismiss() }
        catch { errorMessage = "This contact couldn’t be removed. Try again." }
    }
}
