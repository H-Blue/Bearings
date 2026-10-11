import Foundation

enum IntelligenceAvailability: Equatable, Sendable {
    case available
    case unavailable(String)
}

enum AnalysisError: LocalizedError, Equatable {
    case contextTooLarge, invalidOutput, generationFailed, sourceChanged, emptySource
    var errorDescription: String? {
        switch self {
        case .contextTooLarge: "The on-device reflection couldn’t finish this writing yet. Try again. Your journal is saved."
        case .invalidOutput: "The on-device model returned an incomplete reflection. Try again."
        case .generationFailed: "The on-device reflection couldn’t finish. Try again. Your writing is saved."
        case .sourceChanged: "Your writing changed during the reflection. Try again to use the latest version."
        case .emptySource: "Write something in this period to begin a reflection."
        }
    }
}

protocol JournalIntelligence: Sendable {
    func availability() async -> IntelligenceAvailability
    func analyze(_ text: String) async throws -> DailyAnalysisContent
    func reflect(_ text: String, kind: ReflectionKind) async throws -> ReflectionContent
}
