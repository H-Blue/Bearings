import SwiftUI

struct DailyReflectionSection: View {
    let day: JournalDay
    let hasWriting: Bool
    let service: JournalAnalysisService
    @State private var reflection: ReflectionRoute?
    @State private var pendingEmotion: JournalEmotion?
    @State private var hasPendingCorrection = false

    private var analysis: StoredDailyAnalysis? { hasWriting ? service.daily[day.key] : nil }
    private var chosenEmotion: JournalEmotion? { service.overrides[day.key] }
    private var isCurrent: Bool { analysis?.isStale == false && analysis?.analysisVersion == JournalAnalysisService.version }
    private var displayedEmotion: JournalEmotion? {
        chosenEmotion ?? (isCurrent ? analysis?.content.primaryEmotion : nil)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Divider().overlay(BearingsTheme.line)
            Text("A reflection on this day").font(.headline)
            Text("On-device AI interpretations. Your writing is processed on this iPhone.")
                .font(.footnote).foregroundStyle(BearingsTheme.quietInk)
            if !hasWriting {
                Text("Write something to begin a daily reflection.")
                    .foregroundStyle(BearingsTheme.quietInk)
                    .accessibilityIdentifier("reflection.daily.empty")
            } else {
                emotionMenu
                if let analysis {
                    if !isCurrent {
                        Text("Earlier reflection — your writing has changed.")
                            .font(.footnote.weight(.medium))
                            .accessibilityIdentifier("reflection.daily.stale")
                    }
                    Text(analysis.content.summary).accessibilityIdentifier("reflection.daily.summary")
                    if let secondary = analysis.content.secondaryEmotion {
                        Text("AI also suggested: \(secondary.title)")
                            .font(.subheadline).foregroundStyle(BearingsTheme.quietInk)
                    }
                    if !analysis.content.importantEvents.isEmpty {
                        Text("Remembered moments").font(.subheadline.weight(.medium))
                        ForEach(Array(analysis.content.importantEvents.enumerated()), id: \.offset) { _, event in
                            Text("• \(event)")
                        }
                    }
                    Text(analysis.content.emotionalTrajectory).foregroundStyle(BearingsTheme.quietInk)
                    Text("Reflected \(analysis.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption).foregroundStyle(BearingsTheme.quietInk)
                }
                dailyStatus
            }
            HStack {
                Button { reflection = ReflectionRoute(period: .week(containing: day)) } label: {
                    Label("This week", systemImage: "book.closed")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }.accessibilityIdentifier("reflection.weekly")
            }
            HStack {
                Button { reflection = ReflectionRoute(period: .month(containing: day)) } label: {
                    Label("This month", systemImage: "book.closed")
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }.accessibilityIdentifier("reflection.monthly")
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 32)
        .sheet(item: $reflection) { route in
            ReflectionView(period: route.period, service: service)
        }
    }

    private var emotionMenu: some View {
        VStack(alignment: .leading, spacing: 2) {
            Menu {
                ForEach(JournalEmotion.allCases) { emotion in
                    Button(emotion.title) { correctEmotion(emotion) }
                }
                Button("Use AI suggestion") { correctEmotion(nil) }
            } label: {
                HStack(spacing: 10) {
                    if let emotion = displayedEmotion { EmotionIndicator(emotion: emotion) }
                    Text(displayedEmotion?.title ?? "Choose a feeling")
                        .fixedSize(horizontal: false, vertical: true)
                    Image(systemName: "chevron.down").font(.caption)
                    Spacer(minLength: 0)
                }.frame(minHeight: 44).contentShape(Rectangle())
            }
            .accessibilityLabel("Day feeling")
            .accessibilityValue(displayedEmotion?.title ?? "Not set")
            .accessibilityHint("Choose your own feeling or use the AI suggestion")
            .accessibilityIdentifier("reflection.emotionMenu")
            Text(chosenEmotion == nil ? (displayedEmotion == nil ? "No suggestion yet" : "AI suggestion") : "Your choice")
                .font(.caption).foregroundStyle(BearingsTheme.quietInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var dailyStatus: some View {
        if case .loading? = service.states[day.key] {
            ProgressView("Reflecting on this day…")
                .accessibilityIdentifier("reflection.daily.loading")
        } else if case .failed(let message)? = service.states[day.key] {
            Text(message).font(.footnote).accessibilityIdentifier("reflection.daily.error")
            Button("Try again") {
                if hasPendingCorrection { correctEmotion(pendingEmotion) }
                else { Task { await service.analyze(day: day) } }
            }
            .frame(minHeight: 44)
            .accessibilityIdentifier("reflection.daily.retry")
        } else if case .unavailable(let reason) = service.availability {
            Text(reason).font(.footnote).foregroundStyle(BearingsTheme.quietInk)
                .accessibilityIdentifier("reflection.daily.unavailable")
            Button("Check again") { Task { await service.analyze(day: day) } }
                .frame(minHeight: 44).accessibilityIdentifier("reflection.daily.checkAvailability")
        } else if !isCurrent {
            Button("Reflect on this day") { Task { await service.analyze(day: day) } }
                .frame(minHeight: 44).accessibilityIdentifier("reflection.daily.generate")
        }
    }

    private func correctEmotion(_ emotion: JournalEmotion?) {
        pendingEmotion = emotion
        hasPendingCorrection = !service.setEmotion(emotion, for: day)
    }
}

private struct ReflectionRoute: Identifiable {
    let period: AnalysisPeriod
    var id: String { period.key }
}
