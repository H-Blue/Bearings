import SwiftUI

struct ReflectionView: View {
    let period: AnalysisPeriod
    let service: JournalAnalysisService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    private var stored: StoredReflection? { service.reflections[period.key] }
    private var title: String { period.kind == .weekly ? "Weekly reflection" : "Monthly reflection" }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("\(period.firstDay.shortLabel) – \(period.lastDay.shortLabel)")
                        .font(.headline).accessibilityIdentifier("reflection.period")
                    Text("On-device AI interpretation. You can return to your original writing at any time.")
                        .font(.footnote).foregroundStyle(BearingsTheme.quietInk)
                    if let stored {
                        if stored.isStale || stored.analysisVersion != JournalAnalysisService.version {
                            Text("Earlier reflection — your writing or feelings have changed.")
                                .font(.footnote.weight(.medium))
                                .accessibilityIdentifier("reflection.period.stale")
                        }
                        Text(stored.content.overview).accessibilityIdentifier("reflection.period.summary")
                        if !stored.content.importantEvents.isEmpty {
                            Text("Remembered moments").font(.headline)
                            ForEach(Array(stored.content.importantEvents.enumerated()), id: \.offset) { _, event in
                                Text("• \(event)")
                            }
                        }
                        detail("Emotional themes", stored.content.emotionalThemes)
                        detail("Relationships", stored.content.relationships)
                        detail("Interests and aspirations", stored.content.interests)
                        detail("Changes", stored.content.changes)
                        Text("Reflected \(stored.generatedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption).foregroundStyle(BearingsTheme.quietInk)
                    }
                    status
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(28)
            }
            .background(BearingsTheme.paper)
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(BearingsTheme.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("reflection.done")
                }
            }
        }
        .foregroundStyle(BearingsTheme.ink).tint(BearingsTheme.ink)
        .task(id: scenePhase) {
            if scenePhase == .active { await service.reflect(period: period) }
        }
        .onDisappear { service.cancel() }
    }

    @ViewBuilder
    private var status: some View {
        if case .loading? = service.states[period.key] {
            ProgressView("Reflecting…").accessibilityIdentifier("reflection.period.loading")
        } else if case .failed(let message)? = service.states[period.key] {
            if message == AnalysisError.emptySource.errorDescription {
                Text(message).foregroundStyle(BearingsTheme.quietInk)
                    .accessibilityIdentifier("reflection.period.empty")
            } else {
                Text(message).font(.footnote).accessibilityIdentifier("reflection.period.error")
                Button("Try again") { Task { await service.reflect(period: period) } }
                    .frame(minHeight: 44).accessibilityIdentifier("reflection.period.retry")
            }
        } else if case .unavailable(let reason) = service.availability {
            Text(reason).font(.footnote).foregroundStyle(BearingsTheme.quietInk)
                .accessibilityIdentifier("reflection.period.unavailable")
            Button("Check again") { Task { await service.reflect(period: period) } }
                .frame(minHeight: 44).accessibilityIdentifier("reflection.period.checkAvailability")
        } else if stored == nil {
            Text("Write something in this period to begin a reflection.")
                .foregroundStyle(BearingsTheme.quietInk).accessibilityIdentifier("reflection.period.empty")
        }
    }

    @ViewBuilder
    private func detail(_ heading: String, _ text: String) -> some View {
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(heading).font(.headline)
                Text(text)
            }
        }
    }
}
