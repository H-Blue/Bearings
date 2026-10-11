import Foundation

enum IntelligenceAvailability: Equatable, Sendable {
    case available
    case unavailable(String)
}

enum AnalysisError: LocalizedError, Equatable {
    case contextTooLarge, invalidOutput, generationFailed, modelBusy, sourceChanged, emptySource
    var errorDescription: String? {
        switch self {
        case .contextTooLarge: "The on-device reflection couldn’t finish this writing yet. Try again. Your journal is saved."
        case .invalidOutput: "The on-device model returned an incomplete reflection. Try again."
        case .generationFailed: "The on-device reflection couldn’t finish. Try again. Your writing is saved."
        case .modelBusy: "The on-device model is busy right now. Try again in a moment. Your writing is saved."
        case .sourceChanged: "Your writing changed during the reflection. Try again to use the latest version."
        case .emptySource: "Write something in this period to begin a reflection."
        }
    }
}

protocol JournalIntelligence: Sendable {
    func availability() async -> IntelligenceAvailability
    func analyze(_ text: String) async throws -> DailyAnalysisContent
    func reflect(_ text: String, kind: ReflectionKind) async throws -> ReflectionContent
    func extractWeeklySignals(_ text: String) async throws -> WeeklySignals
    func composeWeeklyReflection(_ text: String) async throws -> ReflectionContent
    func emotionalZoom(_ text: String) async throws -> EmotionalZoomContent
}

extension JournalIntelligence {
    func extractWeeklySignals(_ text: String) async throws -> WeeklySignals {
        throw AnalysisError.generationFailed
    }

    func composeWeeklyReflection(_ text: String) async throws -> ReflectionContent {
        throw AnalysisError.generationFailed
    }

    func emotionalZoom(_ text: String) async throws -> EmotionalZoomContent {
        throw AnalysisError.generationFailed
    }
}
