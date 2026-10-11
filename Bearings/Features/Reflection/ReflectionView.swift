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
                    HStack(spacing: 8) {
                        Text("\(period.firstDay.shortLabel) – \(period.lastDay.shortLabel)")
                            .font(.headline).accessibilityIdentifier("reflection.period")
                        Spacer(minLength: 0)
                        if stored != nil {
                            AIRefreshButton(
                                accessibilityLabel: "Refresh \(period.kind == .weekly ? "weekly" : "monthly") reflection",
                                accessibilityIdentifier: "reflection.period.refresh",
                                isLoading: service.states[period.key] == .loading
                            ) { Task { await service.regenerate(period: period) } }
                        }
                    }
                    Text("On-device AI interpretation. You can return to your original writing at any time.")
                        .font(.footnote).foregroundStyle(BearingsTheme.quietInk)
                    if let stored {
                        if stored.isStale || stored.analysisVersion != JournalAnalysisService.version {
                            Text("Earlier reflection — your writing or feelings have changed.")
                                .font(.footnote.weight(.medium))
                                .accessibilityIdentifier("reflection.period.stale")
                        }
                        if period.kind == .weekly, let weekly = stored.content.weeklyDetails {
                            detail("What you worked on", weekly.workFocus,
                                   identifier: "reflection.weekly.focus")
                            detail("What happened", stored.content.overview,
                                   identifier: "reflection.period.summary")
                            events(stored.content.importantEvents)
                            detail("Progress and unfinished threads", weekly.progressAndUnfinished,
                                   identifier: "reflection.weekly.progress")
                            detail("Emotional changes", stored.content.emotionalThemes,
                                   identifier: "reflection.weekly.emotions")
                            detail("What appeared to help", weekly.whatHelped,
                                   identifier: "reflection.weekly.helped")
                            detail("One thing to try", weekly.realisticImprovement,
                                   identifier: "reflection.weekly.improvement")
                            detail("Lesson direction", weekly.lessonReadiness.title,
                                   identifier: "reflection.weekly.readiness")
                            if !weekly.readinessEvidence.isEmpty {
                                Text("Evidence for this direction").font(.headline)
                                ForEach(Array(weekly.readinessEvidence.enumerated()), id: \.offset) { _, evidence in
                                    Text("• \(evidence)")
                                }
                            }
                            if let question = weekly.reflectionQuestion {
                                detail("A question to consider", question,
                                       identifier: "reflection.weekly.question")
                            }
                        } else {
                            Text(stored.content.overview).accessibilityIdentifier("reflection.period.summary")
                            events(stored.content.importantEvents)
                            detail("Emotional themes", stored.content.emotionalThemes)
                            detail("Relationships", stored.content.relationships)
                            detail("Interests and aspirations", stored.content.interests)
                            detail("Changes", stored.content.changes)
                        }
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
    private func detail(_ heading: String, _ text: String, identifier: String? = nil) -> some View {
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(heading).font(.headline)
                Text(text).accessibilityIdentifier(identifier ?? "reflection.detail.\(heading)")
            }
        }
    }

    @ViewBuilder
    private func events(_ values: [String]) -> some View {
        if !values.isEmpty {
            Text("Important dated events").font(.headline)
            ForEach(Array(values.enumerated()), id: \.offset) { _, event in
                Text("• \(event)")
            }
        }
    }
}
