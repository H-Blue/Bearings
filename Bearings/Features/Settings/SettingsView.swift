import SwiftUI

struct SettingsView: View {
    let contactStore: TrustedContactStore
    @AppStorage("safetyCheckInOfferSeconds") private var offerSeconds = 30
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Trusted contacts") {
                    NavigationLink("Manage trusted contacts") {
                        TrustedContactsView(store: contactStore)
                    }
                    Text("Contacts are stored only on this device. Bearings never contacts anyone without your recipient choice, message review, and final confirmation.")
                        .font(.footnote).foregroundStyle(BearingsTheme.quietInk)
                }
                Section("Safety check-in") {
                    Picker("Prominent offer", selection: $offerSeconds) {
                        Text("15 seconds").tag(15)
                        Text("30 seconds").tag(30)
                        Text("60 seconds").tag(60)
                    }
                    Text("The timer only controls how long the offer stays prominent. It never sends a message.")
                        .font(.footnote).foregroundStyle(BearingsTheme.quietInk)
                    NavigationLink("Professional and emergency support") {
                        ProfessionalSupportView()
                    }
                }
                Section("Privacy") {
                    Text("Safety phrase checks are narrow, rule-based, and run on this device only after writing is saved. They are not a diagnosis or monitoring service, and they may miss or misunderstand language.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(BearingsTheme.paper)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("settings.done")
                }
            }
        }
        .foregroundStyle(BearingsTheme.ink).tint(BearingsTheme.ink)
        .accessibilityIdentifier("settings.screen")
    }
}

struct ProfessionalSupportView: View {
    var body: some View {
        List {
            Section {
                Text("If there is immediate danger, contact local emergency services. Bearings will not place a call or send a message for you.")
            }
            Section("United States") {
                Text("Call or text 988 for the Suicide & Crisis Lifeline. Call 911 for immediate emergency help.")
            }
            Section("Canada") {
                Text("Call or text 9-8-8 for suicide crisis support. Call 9-1-1 for immediate emergency help.")
            }
            Section("Elsewhere") {
                Text("Use the crisis or emergency service for your current region. Availability and eligibility differ by location.")
            }
        }
        .scrollContentBackground(.hidden).background(BearingsTheme.paper)
        .navigationTitle("Immediate support")
        .accessibilityIdentifier("support.screen")
    }
}
