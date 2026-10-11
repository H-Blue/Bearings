import Foundation

protocol TrustedContactPinging: Sendable {
    func preparePing(recipients: [TrustedContactSnapshot], message: String) async throws
}

enum TrustedContactPingError: LocalizedError {
    case unavailable

    var errorDescription: String? { "Sending is not available in this build." }
}

struct PreviewOnlyTrustedContactPinger: TrustedContactPinging {
    func preparePing(recipients: [TrustedContactSnapshot], message: String) async throws {
        throw TrustedContactPingError.unavailable
    }
}
