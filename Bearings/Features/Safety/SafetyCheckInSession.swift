import Foundation
import Observation

@MainActor
@Observable
final class SafetyCheckInSession {
    enum Stage: Equatable { case offer, recipients, message, unavailable }
    private(set) var stage: Stage = .offer
    private(set) var contacts: [TrustedContactSnapshot] = []
    var selectedRecipientIDs = Set<UUID>()
    var message = "Could you check in with me when you can? I’d appreciate hearing from you."
    private(set) var errorMessage: String?

    @ObservationIgnored private let contactStore: TrustedContactStore
    @ObservationIgnored private let pinger: any TrustedContactPinging

    init(contactStore: TrustedContactStore, pinger: any TrustedContactPinging) {
        self.contactStore = contactStore
        self.pinger = pinger
    }

    var enabledContacts: [TrustedContactSnapshot] { contacts.filter(\.isEnabled) }
    var selectedRecipients: [TrustedContactSnapshot] { contacts.filter { selectedRecipientIDs.contains($0.id) } }

    func beginReachOut() {
        loadContacts()
        stage = .recipients
    }

    func loadContacts() {
        do { contacts = try contactStore.contacts(); errorMessage = nil }
        catch { errorMessage = "Trusted contacts couldn’t be loaded. Try again." }
    }

    func reviewMessage() {
        guard !selectedRecipients.isEmpty else { return }
        stage = .message
    }

    func returnToRecipients() { stage = .recipients }

    func finalSend() async {
        guard stage == .message, !selectedRecipients.isEmpty,
              !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        do { try await pinger.preparePing(recipients: selectedRecipients, message: message) }
        catch let error as LocalizedError {
            errorMessage = error.errorDescription ?? "Sending is not available in this build."
            stage = .unavailable
        } catch {
            errorMessage = "Sending is not available in this build."
            stage = .unavailable
        }
    }
}
