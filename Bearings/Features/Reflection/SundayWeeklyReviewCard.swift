import SwiftUI

/// Makes the completed prior week visible on Sunday without requiring the
/// writer to discover the period buttons below an otherwise empty day.
struct SundayWeeklyReviewCard: View {
    let day: JournalDay
    let service: JournalAnalysisService
    @State private var showsFullReflection = false

    private var period: AnalysisPeriod { .weekForReview(on: day) }
    private var stored: StoredReflection? { service.reflections[period.key] }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Label("Last week's reflection", systemImage: "book.closed")
                    .font(.headline)
                Spacer(minLength: 8)
                Text("\(period.firstDay.shortLabel) – \(period.lastDay.shortLabel)")
                    .font(.caption)
                    .foregroundStyle(BearingsTheme.quietInk)
            }

            if let stored {
                Text(stored.content.isPreparedDemo == true
                     ? "Prepared fictional demo reflection"
                     : "On-device AI interpretation")
                    .font(.footnote)
                    .foregroundStyle(BearingsTheme.quietInk)
                    .accessibilityIdentifier("reflection.sunday.provenance")
                if stored.isStale || stored.analysisVersion != JournalAnalysisService.version {
                    Text("Earlier reflection — your writing or feelings have changed.")
                        .font(.footnote.weight(.medium))
                }
                Text(stored.content.overview)
                    .accessibilityIdentifier("reflection.sunday.summary")
                if let improvement = stored.content.weeklyDetails?.realisticImprovement {
                    Text("One thing to try").font(.subheadline.weight(.medium))
                    Text(improvement)
                        .accessibilityIdentifier("reflection.sunday.improvement")
                }
                Button("Open full weekly reflection") { showsFullReflection = true }
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("reflection.sunday.open")
            } else if service.states[period.key] == .loading {
                ProgressView("Preparing last week's reflection…")
                    .accessibilityIdentifier("reflection.sunday.loading")
            } else {
                Button("Reflect on last week") {
                    Task { await service.reflect(period: period) }
                }
                .frame(minHeight: 44)
                .accessibilityIdentifier("reflection.sunday.generate")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(BearingsTheme.marker.opacity(0.28), in: RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 24)
        .task(id: period.key) { await service.reflect(period: period) }
        .sheet(isPresented: $showsFullReflection) {
            ReflectionView(period: period, service: service)
        }
    }
}
