import Foundation
import SwiftData

@Model
final class TrustedContact {
    @Attribute(.unique) var id: UUID
    var displayName: String
    var phoneNumber: String
    var isEnabled: Bool
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID = UUID(), displayName: String, phoneNumber: String,
         isEnabled: Bool = true, now: Date = Date()) {
        self.id = id
        self.displayName = displayName
        self.phoneNumber = phoneNumber
        self.isEnabled = isEnabled
        self.createdAt = now
        self.modifiedAt = now
    }
}

struct TrustedContactSnapshot: Identifiable, Equatable, Sendable {
    let id: UUID
    let displayName: String
    let phoneNumber: String
    let isEnabled: Bool

    init(_ contact: TrustedContact) {
        id = contact.id
        displayName = contact.displayName
        phoneNumber = contact.phoneNumber
        isEnabled = contact.isEnabled
    }
}
