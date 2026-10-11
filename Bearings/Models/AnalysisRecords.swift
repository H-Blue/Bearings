import Foundation
import SwiftData

/// Derived interpretations stay separate from the original journal writing.
/// One daily aggregation is identified by its civil day and source fingerprint.
@Model
final class DailyAnalysisRecord {
    @Attribute(.unique) var dayKey: String
    var contentData: Data
    var sourceFingerprint: String
    var generatedAt: Date
    var analysisVersion: Int
    var isStale: Bool

    init(dayKey: String, contentData: Data, sourceFingerprint: String, generatedAt: Date,
         analysisVersion: Int, isStale: Bool = false) {
        self.dayKey = dayKey
        self.contentData = contentData
        self.sourceFingerprint = sourceFingerprint
        self.generatedAt = generatedAt
        self.analysisVersion = analysisVersion
        self.isStale = isStale
    }

    func snapshot() throws -> StoredDailyAnalysis {
        let content = try JSONDecoder().decode(DailyAnalysisContent.self, from: contentData)
        try content.validate()
        return StoredDailyAnalysis(dayKey: dayKey, content: content,
                                   sourceFingerprint: sourceFingerprint, generatedAt: generatedAt,
                                   analysisVersion: analysisVersion, isStale: isStale)
    }
}

@Model
final class ReflectionRecord {
    @Attribute(.unique) var periodKey: String
    var kindRawValue: String
    var firstDayKey: String
    var lastDayKey: String
    var contentData: Data
    var sourceFingerprint: String
    var generatedAt: Date
    var analysisVersion: Int
    var isStale: Bool

    init(period: AnalysisPeriod, contentData: Data, sourceFingerprint: String, generatedAt: Date,
         analysisVersion: Int, isStale: Bool = false) {
        periodKey = period.key
        kindRawValue = period.kind.rawValue
        firstDayKey = period.firstDay.key
        lastDayKey = period.lastDay.key
        self.contentData = contentData
        self.sourceFingerprint = sourceFingerprint
        self.generatedAt = generatedAt
        self.analysisVersion = analysisVersion
        self.isStale = isStale
    }

    func snapshot() throws -> StoredReflection {
        guard let kind = ReflectionKind(rawValue: kindRawValue),
              let first = JournalDay(key: firstDayKey),
              let last = JournalDay(key: lastDayKey), first <= last
        else { throw AnalysisError.invalidOutput }
        let period = AnalysisPeriod(kind: kind, firstDay: first, lastDay: last)
        guard period.key == periodKey else { throw AnalysisError.invalidOutput }
        let content = try JSONDecoder().decode(ReflectionContent.self, from: contentData)
        try content.validate()
        return StoredReflection(period: period, content: content,
                                sourceFingerprint: sourceFingerprint, generatedAt: generatedAt,
                                analysisVersion: analysisVersion, isStale: isStale)
    }
}

/// Corrections survive regeneration and removal of a day's last journal entry.
@Model
final class EmotionOverrideRecord {
    @Attribute(.unique) var dayKey: String
    var emotionRawValue: String
    var modifiedAt: Date

    init(dayKey: String, emotion: JournalEmotion, modifiedAt: Date) {
        self.dayKey = dayKey
        emotionRawValue = emotion.rawValue
        self.modifiedAt = modifiedAt
    }
}
