import Foundation
import Observation
import SwiftData

enum TrustedContactStoreError: LocalizedError {
    case missingName
    case missingPhone
    case notFound

    var errorDescription: String? {
        switch self {
        case .missingName: "Enter a name for this trusted contact."
        case .missingPhone: "Enter a phone number for this trusted contact."
        case .notFound: "This trusted contact could not be found. Refresh and try again."
        }
    }
}

@MainActor
@Observable
final class TrustedContactStore {
    private(set) var revision = 0
    @ObservationIgnored private let container: ModelContainer
    @ObservationIgnored private let now: () -> Date

    init(context: ModelContext, now: @escaping () -> Date = Date.init) {
        container = context.container
        self.now = now
        context.autosaveEnabled = false
    }

    func contacts() throws -> [TrustedContactSnapshot] {
        var descriptor = FetchDescriptor<TrustedContact>(sortBy: [SortDescriptor(\.displayName)])
        descriptor.includePendingChanges = false
        return try transactionContext().fetch(descriptor).map(TrustedContactSnapshot.init)
    }

    @discardableResult
    func create(displayName: String, phoneNumber: String, isEnabled: Bool = true) throws -> TrustedContactSnapshot {
        let values = try validated(displayName: displayName, phoneNumber: phoneNumber)
        let context = transactionContext()
        let contact = TrustedContact(displayName: values.name, phoneNumber: values.phone,
                                     isEnabled: isEnabled, now: now())
        context.insert(contact)
        try save(context)
        revision += 1
        return TrustedContactSnapshot(contact)
    }

    func update(_ id: UUID, displayName: String, phoneNumber: String, isEnabled: Bool) throws {
        let values = try validated(displayName: displayName, phoneNumber: phoneNumber)
        let context = transactionContext()
        let contact = try resolve(id, in: context)
        contact.displayName = values.name
        contact.phoneNumber = values.phone
        contact.isEnabled = isEnabled
        contact.modifiedAt = max(now(), contact.modifiedAt)
        try save(context)
        revision += 1
    }

    func setEnabled(_ enabled: Bool, for id: UUID) throws {
        let context = transactionContext()
        let contact = try resolve(id, in: context)
        guard contact.isEnabled != enabled else { return }
        contact.isEnabled = enabled
        contact.modifiedAt = max(now(), contact.modifiedAt)
        try save(context)
        revision += 1
    }

    func delete(_ id: UUID) throws {
        let context = transactionContext()
        context.delete(try resolve(id, in: context))
        try save(context)
        revision += 1
    }

    private func validated(displayName: String, phoneNumber: String) throws -> (name: String, phone: String) {
        let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw TrustedContactStoreError.missingName }
        guard !phone.isEmpty else { throw TrustedContactStoreError.missingPhone }
        return (name, phone)
    }

    private func resolve(_ id: UUID, in context: ModelContext) throws -> TrustedContact {
        var descriptor = FetchDescriptor<TrustedContact>(predicate: #Predicate { $0.id == id })
        descriptor.includePendingChanges = false
        guard let contact = try context.fetch(descriptor).first else { throw TrustedContactStoreError.notFound }
        return contact
    }

    private func transactionContext() -> ModelContext {
        let context = ModelContext(container)
        context.autosaveEnabled = false
        return context
    }

    private func save(_ context: ModelContext) throws {
        do { try context.save() }
        catch { context.rollback(); throw error }
    }
}
