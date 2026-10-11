import SwiftUI
import SwiftData

@main
struct BearingsApp: App {
    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .preferredColorScheme(.light)
        }
    }
}

private struct AppEntryView: View {
    @State private var showsOpeningScreen = true

    var body: some View {
        Group {
            if showsOpeningScreen {
                OpeningScreenView { showsOpeningScreen = false }
            } else {
                StoreBootstrapView()
            }
        }
    }
}

private struct StoreBootstrapView: View {
    @State private var container: ModelContainer?
    @State private var failed = false
    @State private var journalViewID = UUID()

    var body: some View {
        Group {
            if let container {
                BearingsRootView(container: container, onRetryRead: { journalViewID = UUID() })
                    .modelContainer(container)
                    .id(journalViewID)
            } else if failed {
                ContentUnavailableView {
                    Label("Your journal couldn’t open", systemImage: "book.closed")
                } description: {
                    Text("Bearings could not open its local storage. Your existing journal has not been replaced. Try again when your device is unlocked and has available storage.")
                } actions: {
                    Button("Try again", action: openStore)
                }
            } else {
                ProgressView("Opening your journal…")
            }
        }
        .tint(BearingsTheme.ink)
        .task { if container == nil { openStore() } }
    }

    private func openStore() {
        do {
            var storeURL: URL?
            #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("--uitesting") {
                let directory = URL.applicationSupportDirectory.appending(path: "BearingsUITests", directoryHint: .isDirectory)
                if arguments.contains("--reset-test-store"), FileManager.default.fileExists(atPath: directory.path) {
                    try FileManager.default.removeItem(at: directory)
                }
                storeURL = directory.appending(path: "ui-tests.store")
            }
            #endif
            let openedContainer = try PersistenceController.makeContainer(storeURL: storeURL)
            #if DEBUG
            try ProfessionalCaseStudyDemoSeeder.seedIfRequested(in: openedContainer)
            #endif
            container = openedContainer
            failed = false
        } catch {
            // Never log error descriptions: persistence errors may contain private values.
            failed = true
        }
    }
}

#if DEBUG
/// Loads fictional judging material only when an explicit launch argument is
/// supplied. The argument is intended to be paired with `--uitesting`, which
/// keeps the demo in the separate UI-test store instead of the personal store.
@MainActor
private enum ProfessionalCaseStudyDemoSeeder {
    private struct SeedEntry {
        let dayKey: String
        let period: JournalPeriod
        let body: String
    }

    static func seedIfRequested(in container: ModelContainer) throws {
        let arguments = ProcessInfo.processInfo.arguments
        guard arguments.contains("--uitesting"),
              arguments.contains("--seed-professional-case-study") else { return }

        let store = JournalStore(
            context: container.mainContext,
            creationTimeZone: { TimeZone(identifier: "America/New_York")! }
        )
        guard try store.daysWithEntries().isEmpty else { return }

        for entry in entries {
            guard let day = JournalDay(key: entry.dayKey) else { continue }
            try store.create(day: day, body: entry.body, period: entry.period)
        }
    }

    private static let entries: [SeedEntry] = [
        SeedEntry(dayKey: "2026-09-21", period: .evening, body: """
        Priya was walking me through why the handoff screen felt confusing. Before she finished, I opened the code and proposed changing the button labels. She paused and asked if she could finish explaining the flow first. I felt embarrassed in front of the team and immediately started defending why I had built it that way. The meeting ended without a decision. I keep replaying it as if she said I am bad at this job, but what she actually said was that the screen was confusing and she wanted to finish her explanation. The release is close, and I am worried everyone can see how inexperienced I am.
        """),
        SeedEntry(dayKey: "2026-09-22", period: .morning, body: """
        I woke up still tense about yesterday. My first impulse was to send Priya a long message explaining every constraint behind the screen. I drafted it, then stopped. I do not know that she thinks I am incompetent. I know she found the handoff confusing and that I interrupted her. Those are different facts. I am going to wait until our check-in rather than trying to repair my reputation before I understand the issue. I still feel exposed and defensive, especially because this is my first release with this team.
        """),
        SeedEntry(dayKey: "2026-09-23", period: .evening, body: """
        Most of today was ordinary release work. I fixed two small bugs, reviewed Sam's pull request, and finally wrote the missing test for the empty state. Priya and I exchanged a few normal messages about spacing, and neither of us mentioned Monday. That does not resolve the disagreement, but it is evidence that one awkward meeting has not ruined the collaboration. I noticed that I kept scanning her messages for criticism anyway. I want tomorrow's design review to be about understanding the problem, not proving that my first version was reasonable.
        """),
        SeedEntry(dayKey: "2026-09-24", period: .evening, body: """
        The same pattern happened again. Priya started describing what confused her when moving from the list into the detail screen. I jumped in with a fix before she reached the example. She looked frustrated and said the proposed fix did not address what she was showing me. I heard that as criticism of me and argued about the deadline. Afterward I wrote one sentence that feels uncomfortably accurate: I keep hearing a problem with the screen as a problem with me. I am frustrated with her, embarrassed about my reaction, and worried that slowing down will make us miss the release.
        """),
        SeedEntry(dayKey: "2026-09-25", period: .evening, body: """
        Priya sent a specific edge case this morning: returning to a saved item after its status changes. Once I saw it, the confusion made sense. We talked for ten minutes, I implemented the smaller state change, and she thanked me for turning it around quickly. That conversation does not fit the story that she rejects my work or thinks I am incapable. I still felt a little ashamed that I needed the example, but asking for details would have gotten us there faster than defending the old flow. The build passed before dinner, which was a relief.
        """),
        SeedEntry(dayKey: "2026-09-26", period: .midday, body: """
        I stayed away from the project for most of today. I went for a long walk, bought groceries, and called my brother. I expected the release anxiety to follow me all day, but it eased when I stopped checking team messages. Looking back at the week, the strongest moments were not all negative: I completed useful work, Priya gave me a concrete example, and we solved one issue together. The tense meetings still bother me. I want to find a way to respond that does not require pretending I am calm or agreeing with every suggestion.
        """),
        SeedEntry(dayKey: "2026-09-27", period: .evening, body: """
        I keep returning to the same question: am I trying to solve the problem before I understand what Priya needs? In both tense meetings, I offered an answer before she finished. Then I treated her correction as a judgment about my competence. I cannot know her intentions from that. What I can change is my part of the conversation. Tomorrow I want to ask what is confusing, repeat back what I heard, and only then suggest a fix. I am nervous that this will feel slow or scripted, but arguing has not saved us any time.
        """),
        SeedEntry(dayKey: "2026-09-28", period: .morning, body: """
        I reviewed last week and chose one thing to practice: before offering a solution, ask what Priya needs me to understand. If I feel defensive, I will try one clarifying question before explaining the implementation. I am not promising myself that I will never interrupt again. The goal is small enough to try during today's planning meeting. I still care about the deadline, and I can say when a request is too large. Listening first does not mean agreeing to everything.
        """),
        SeedEntry(dayKey: "2026-09-29", period: .evening, body: """
        Planning was rushed, but I managed to stay quiet through Priya's first example. I asked which part of the transition mattered most. She said the problem was losing context, not the wording I had focused on. We did not decide on a design today because another production issue took over the meeting. I felt impatient and wanted a quick answer. Still, the question gave me better information than my usual defense would have. I need to try it when the pressure is higher, not only when I have time to think beforehand.
        """),
        SeedEntry(dayKey: "2026-09-30", period: .evening, body: """
        Priya walked through the confusing example again. I let her finish, then said back what I thought the problem was: the person loses track of the item they were working on. She corrected one detail, and we agreed on a narrower change that keeps the context visible. I still felt pressure about the release and wanted to rush, but the conversation was productive. We left with a clear change and no argument. I do not think a single good meeting means the habit is fixed. It does show that understanding the example first can make the engineering decision smaller.
        """),
        SeedEntry(dayKey: "2026-10-01", period: .evening, body: """
        I interrupted again today. Priya raised a concern about the loading state, and I started explaining why it was unlikely before she finished. I saw her expression and realized I was doing exactly what I wrote about. I stopped, said I had jumped ahead, and asked her to continue. She showed a slow-network case I had not considered. We did not have time to solve it, but the conversation recovered. I am disappointed that the old reaction came back so quickly. I am also glad I noticed and repaired it instead of spending the rest of the meeting defending my intentions.
        """),
        SeedEntry(dayKey: "2026-10-02", period: .evening, body: """
        Late this afternoon Priya asked whether the remaining loading issue could be fixed tonight. I checked the code and said I could investigate first thing tomorrow, but I could not responsibly promise a fix before understanding the cause. She was disappointed because she wanted it in the release. I felt guilty and worried that setting a limit would look unhelpful. We still disagree about whether the release should wait. Listening better does not remove every conflict, and it does not mean saying yes to work I cannot complete safely.
        """),
        SeedEntry(dayKey: "2026-10-03", period: .midday, body: """
        I reproduced the loading issue this morning and found that it only happens after a long background pause. I sent Priya what I found and proposed documenting the limitation while I test the safer fix. She replied that the explanation helped and agreed we should not rush it. I felt relieved, but I do not want to turn her agreement into proof that every boundary will be accepted. Yesterday was still uncomfortable. The useful part was being specific about what I knew, what I did not know, and when I could investigate.
        """),
        SeedEntry(dayKey: "2026-10-04", period: .evening, body: """
        The practice partly helped. Pausing and asking a clarifying question helped in Tuesday's planning and Wednesday's design discussion. On Thursday I interrupted again, although I noticed and asked Priya to continue. Friday's boundary was still tense, and one disagreement remains unresolved. I do not need a completely new lesson yet. Next week I want to make the same practice smaller: ask one clarifying question before my first suggestion, especially when the deadline makes me want to move fast. I feel more prepared, but not magically confident.
        """)
    ]
}
#endif
