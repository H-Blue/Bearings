import Foundation

enum JournalPeriod: String, CaseIterable, Codable, Identifiable, Sendable {
    case morning
    case midday
    case evening

    var id: String { rawValue }

    var title: String {
        switch self {
        case .morning: return "Morning"
        case .midday: return "Midday"
        case .evening: return "Evening"
        }
    }
}
