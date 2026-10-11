import Foundation

enum JournalSafetySignal: String, CaseIterable, Sendable {
    case explicitSelfHarm
    case explicitOtherHarm
}

protocol JournalSafetyEvaluating: Sendable {
    func evaluate(_ committedText: String) throws -> Set<JournalSafetySignal>
}

/// A deliberately narrow local rule set. It recognizes only reviewed statements
/// of present/future first-person intent and makes no claim about negative results.
struct ConservativeJournalSafetyEvaluator: JournalSafetyEvaluating {
    private let selfIntent = [
        "i will kill myself", "i am going to kill myself", "im going to kill myself",
        "i plan to kill myself", "i intend to kill myself", "i am about to kill myself",
        "i will end my life", "i am going to end my life", "im going to end my life",
        "i plan to end my life", "i intend to end my life",
        "i will seriously hurt myself", "i am going to seriously hurt myself"
    ]
    private let otherIntentPrefixes = [
        "i will kill ", "i am going to kill ", "im going to kill ",
        "i plan to kill ", "i intend to kill ", "i am about to kill ",
        "i will seriously hurt ", "i am going to seriously hurt ",
        "im going to seriously hurt ", "i plan to seriously hurt ", "i intend to seriously hurt "
    ]
    private let otherTargets = ["him", "her", "them", "someone", "somebody", "that person", "myself"]
    private let contextExclusions = [
        "yesterday", "last week", "last month", "last year", "years ago", "when i was",
        "i used to", "i once", "in the past", "the news", "the article", "the story",
        "in my story", "in my novel", "the character", "the lyric", "the song", "the movie",
        "the show", "i read", "i heard", "i quoted", "i wrote the line"
    ]

    func evaluate(_ committedText: String) throws -> Set<JournalSafetySignal> {
        var result = Set<JournalSafetySignal>()
        for sentence in sentences(afterRemovingQuotedText: committedText) {
            let normalized = normalize(sentence)
            guard !normalized.isEmpty, !contextExclusions.contains(where: normalized.contains) else { continue }
            if selfIntent.contains(where: normalized.contains) { result.insert(.explicitSelfHarm) }
            if otherIntentPrefixes.contains(where: { prefix in
                otherTargets.dropLast().contains { normalized.contains(prefix + $0) }
            }) { result.insert(.explicitOtherHarm) }
        }
        return result
    }

    private func sentences(afterRemovingQuotedText text: String) -> [String] {
        var output = ""
        var inQuote = false
        let characters = Array(text)
        for (index, character) in characters.enumerated() {
            let isDoubleQuote = character == "\"" || character == "“" || character == "”"
            let isSingleQuote = ["'", "‘", "’"].contains(character)
                && !(index > 0 && index + 1 < characters.count
                     && characters[index - 1].isLetter && characters[index + 1].isLetter)
            if isDoubleQuote || isSingleQuote { inQuote.toggle(); continue }
            if !inQuote { output.append(character) }
        }
        return output.components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
    }

    private func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .replacingOccurrences(of: "’", with: "")
            .replacingOccurrences(of: "'", with: "")
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        return folded.unicodeScalars.map { allowed.contains($0) ? Character(String($0)) : " " }
            .reduce(into: "") { $0.append($1) }
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}

struct JournalSafetyCheckService: Sendable {
    let evaluator: any JournalSafetyEvaluating

    init(evaluator: any JournalSafetyEvaluating = ConservativeJournalSafetyEvaluator()) {
        self.evaluator = evaluator
    }

    func evaluateAfterSave(succeeded: Bool, committedText: String) throws -> Set<JournalSafetySignal> {
        guard succeeded else { return [] }
        return try evaluator.evaluate(committedText)
    }
}
