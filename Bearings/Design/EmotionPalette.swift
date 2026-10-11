import SwiftUI

/// Only emotion indicators use this palette. Journal markers and decorative
/// linework retain their existing Marker and Line colors.
enum EmotionPalette {
    static func color(for emotion: JournalEmotion) -> Color {
        switch emotion {
        case .joy: Color(red: 0.76, green: 0.59, blue: 0.19)
        case .peace: Color(red: 0.45, green: 0.57, blue: 0.43)
        case .sadness: Color(red: 0.36, green: 0.50, blue: 0.64)
        case .anger: Color(red: 0.69, green: 0.36, blue: 0.28)
        case .fear: Color(red: 0.54, green: 0.44, blue: 0.64)
        case .loneliness: Color(red: 0.47, green: 0.45, blue: 0.42)
        case .love: Color(red: 0.68, green: 0.44, blue: 0.49)
        case .uncertain: Color(red: 0.57, green: 0.54, blue: 0.49)
        }
    }
}

struct EmotionIndicator: View {
    let emotion: JournalEmotion

    var body: some View {
        Circle()
            .stroke(EmotionPalette.color(for: emotion), lineWidth: 3)
            .frame(width: 12, height: 12)
            .accessibilityHidden(true)
    }
}
