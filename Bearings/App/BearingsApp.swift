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
            if arguments.contains("--seed-finn-sophie-demo") {
                UserDefaults.standard.set(true, forKey: FinnSophieDemoSeeder.activeDefaultsKey)
            } else if arguments.contains("--leave-finn-sophie-demo") {
                UserDefaults.standard.removeObject(forKey: FinnSophieDemoSeeder.activeDefaultsKey)
            }
            let finnSophieDemoActive = UserDefaults.standard.bool(forKey: FinnSophieDemoSeeder.activeDefaultsKey)
            if arguments.contains("--uitesting") {
                let directory = URL.applicationSupportDirectory.appending(path: "BearingsUITests", directoryHint: .isDirectory)
                if arguments.contains("--reset-test-store"), FileManager.default.fileExists(atPath: directory.path) {
                    try FileManager.default.removeItem(at: directory)
                }
                storeURL = directory.appending(path: "ui-tests.store")
            } else if finnSophieDemoActive {
                let directory = URL.applicationSupportDirectory
                    .appending(path: "BearingsDemos", directoryHint: .isDirectory)
                    .appending(path: "FinnSophie", directoryHint: .isDirectory)
                if arguments.contains("--reset-finn-sophie-demo"), FileManager.default.fileExists(atPath: directory.path) {
                    try FileManager.default.removeItem(at: directory)
                }
                storeURL = directory.appending(path: "FinnSophie.store")
            }
            #endif
            let openedContainer = try PersistenceController.makeContainer(storeURL: storeURL)
            #if DEBUG
            try FinnSophieDemoSeeder.seedIfRequested(in: openedContainer)
            if finnSophieDemoActive {
                try FinnSophieDemoSeeder.repairPreparedReflectionIfNeeded(in: openedContainer)
            }
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
/// Activates a persistent Debug-only fictional demo store without touching the
/// owner's ordinary journal. Once activated, normal home-screen launches keep
/// using the demo store until `--leave-finn-sophie-demo` is supplied.
@MainActor
enum FinnSophieDemoSeeder {
    static let activeDefaultsKey = "BearingsFinnSophieDemoActive"

    struct SeedEntry {
        let dayKey: String
        let hour: Int
        let minute: Int
        let period: JournalPeriod
        let body: String
    }

    static func seedIfRequested(in container: ModelContainer) throws {
        guard ProcessInfo.processInfo.arguments.contains("--seed-finn-sophie-demo") else { return }
        try seed(in: container)
    }

    static func seed(in container: ModelContainer) throws {
        var seedNow = date(dayKey: "2026-10-04", hour: 9, minute: 10)
        let store = JournalStore(
            context: container.mainContext,
            now: { seedNow },
            creationTimeZone: { TimeZone(identifier: "America/New_York")! }
        )
        guard try store.daysWithEntries().isEmpty else { return }

        for entry in entries {
            guard let day = JournalDay(key: entry.dayKey) else { continue }
            seedNow = date(dayKey: entry.dayKey, hour: entry.hour, minute: entry.minute)
            try store.create(day: day, body: entry.body, period: entry.period)
        }

        let reviewDay = JournalDay(key: "2026-10-11")!
        let reviewedWeek = AnalysisPeriod.weekForReview(on: reviewDay)
        seedNow = date(dayKey: reviewDay.key, hour: 9, minute: 0)
        let fingerprint = try store.reflectionFingerprint(
            for: reviewedWeek,
            version: JournalAnalysisService.version
        )
        try store.saveReflection(
            preparedReflection,
            for: reviewedWeek,
            sourceFingerprint: fingerprint,
            version: JournalAnalysisService.version
        )
    }

    /// Daily analysis records are legitimate fingerprint inputs and therefore
    /// make an older prepared fixture stale. Keep the authored demo available
    /// against those current local inputs, while never replacing a reflection
    /// that the writer refreshed through the real on-device model.
    static func repairPreparedReflectionIfNeeded(in container: ModelContainer) throws {
        let store = JournalStore(context: container.mainContext)
        let reviewDay = JournalDay(key: "2026-10-11")!
        let reviewedWeek = AnalysisPeriod.weekForReview(on: reviewDay)
        guard let existing = try store.reflection(for: reviewedWeek),
              existing.content.isPreparedDemo == true else { return }
        let fingerprint = try store.reflectionFingerprint(
            for: reviewedWeek,
            version: JournalAnalysisService.version
        )
        guard existing.isStale
                || existing.analysisVersion != JournalAnalysisService.version
                || existing.sourceFingerprint != fingerprint else { return }
        try store.saveReflection(
            preparedReflection,
            for: reviewedWeek,
            sourceFingerprint: fingerprint,
            version: JournalAnalysisService.version
        )
    }

    private static func date(dayKey: String, hour: Int, minute: Int) -> Date {
        let components = dayKey.split(separator: "-").compactMap { Int($0) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        return calendar.date(from: DateComponents(
            timeZone: calendar.timeZone,
            year: components[0], month: components[1], day: components[2],
            hour: hour, minute: minute
        ))!
    }

    static let preparedReflection = ReflectionContent(
        overview: "Finn spent the week trying to support Sophie when she talked about painful moments with her friend, her sister, and work. His entries became much clearer: he moved from saying conversations simply felt strange to noticing that he often interrupted, corrected her interpretation, or offered instructions before she had finished. Sophie directly asked to be heard, and she repeatedly became quieter after advice arrived too quickly. Finn's care is consistent, but the way he responds is still leaving part of her experience unheard.",
        importantEvents: [
            "Oct 4: Sophie asked Finn to let her finish after he began explaining what she should do about a canceled plan.",
            "Oct 6: Finn corrected Sophie's interpretation of an argument with her sister, and Sophie said she wanted him to hear why it hurt.",
            "Oct 8: Sophie asked whether Finn could listen before giving her steps for handling a work problem.",
            "Oct 10: Finn recognized that his quick solutions come from care and discomfort with feeling helpless, but he still planned to improve the advice rather than first ask what Sophie needed."
        ],
        emotionalThemes: "Concern and tenderness are present throughout the week, alongside helplessness, defensiveness, regret, and growing self-awareness. Finn's language becomes more precise even though his response pattern remains unresolved.",
        relationships: "Finn wants Sophie to feel supported and takes her pain seriously. The tension appears when he treats support as fixing, explaining, or correcting before making room for her experience.",
        interests: "The writing repeatedly focuses on becoming a kinder and more useful partner during difficult conversations.",
        changes: "Finn moved from vague discomfort to a coherent description of his intention, his urge to solve problems, and Sophie's response. He has identified the pattern but has not yet tried listening first or asking what kind of support she wants.",
        weeklyDetails: WeeklyReflectionDetails(
            workFocus: "Finn was trying to understand why his attempts to help Sophie often ended with her becoming quiet or asking to finish speaking.",
            progressAndUnfinished: "His reflection became more specific and honest across the week. By Saturday he could connect his advice-giving to care and to his discomfort with feeling helpless. What remains unresolved is the response itself: he is still considering how to give better instructions rather than whether instruction is what Sophie wants in that moment.",
            whatHelped: "Writing down Sophie's exact words and revisiting several conversations helped Finn see a repeated pattern instead of treating each moment as a separate misunderstanding.",
            realisticImprovement: "When Sophie shares something painful, listen without instructing or correcting first. Before offering an answer, ask what she needs: for example, whether she wants Finn to listen, help her think it through, or help with something practical.",
            lessonReadiness: .continueCurrentLesson,
            readinessEvidence: [
                "Sophie directly asked Finn to let her finish and later asked him to hear why an experience hurt.",
                "Finn noticed that Sophie repeatedly became quieter after he offered instructions or corrected her interpretation.",
                "Finn identified his urge to solve the problem, but he had not yet asked Sophie what kind of response she wanted."
            ],
            reflectionQuestion: nil
        ),
        isPreparedDemo: true
    )

    static let entries: [SeedEntry] = [
        SeedEntry(dayKey: "2026-10-04", hour: 20, minute: 20, period: .evening, body: """
        Weird talk with Sophie. She was sad. I tried to help. It got quiet.
        """),
        SeedEntry(dayKey: "2026-10-05", hour: 8, minute: 15, period: .morning, body: """
        Still thinking about last night. Sophie was upset because a friend canceled on her. I told her the friend was probably just busy. She said that was not really the point. I meant to make it feel less bad.
        """),
        SeedEntry(dayKey: "2026-10-05", hour: 21, minute: 5, period: .evening, body: """
        I brought Sophie tea after class because she looked tired. She smiled, which was nice. When she started talking about the canceled plan again, I gave her ideas for what to text. She asked if she could finish first. I said of course, but then I explained one more thing. I do not think I handled that well.
        """),
        SeedEntry(dayKey: "2026-10-06", hour: 12, minute: 35, period: .midday, body: """
        Sophie argued with her sister this morning. She said her sister made her feel small. I told her that was probably not what her sister meant and that she should call back when everyone was calmer. Sophie looked hurt and said, "I know you are trying to help. I want you to hear why it hurt." I felt confused because listening without doing anything seems unhelpful.
        """),
        SeedEntry(dayKey: "2026-10-06", hour: 22, minute: 10, period: .evening, body: """
        I keep replaying what Sophie said. I care about her, and when she is hurting I want the hurt to have an answer. Maybe I rush because silence feels like leaving her alone with it. I still think calling her sister calmly would help, but saying that immediately made Sophie defend the fact that she was hurt instead of letting her talk about it.
        """),
        SeedEntry(dayKey: "2026-10-07", hour: 9, minute: 0, period: .morning, body: """
        Sent Sophie a kind message before her meeting and told her I believed in her. She said thank you. That felt simple and good. I did not need to tell her how to prepare because she had not asked. I wonder why that is easier before a problem than when she is already upset.
        """),
        SeedEntry(dayKey: "2026-10-07", hour: 20, minute: 45, period: .evening, body: """
        Her meeting went badly. I started listing the three things she should do tomorrow. Sophie went quiet after the second one. I asked whether I had said something wrong, and she said she did not have energy to be coached tonight. I felt defensive because I had spent time thinking of useful steps, but I also felt sad that my effort made her feel more tired.
        """),
        SeedEntry(dayKey: "2026-10-08", hour: 13, minute: 20, period: .midday, body: """
        Lunch was warm and easy until Sophie mentioned work. I corrected one detail because I thought it changed the situation. She stopped and said, "Can you listen before we turn this into a plan?" I let her finish after that. I noticed how much more there was to the story than the first problem she mentioned, although I still spent the walk home thinking about what she should say to her manager.
        """),
        SeedEntry(dayKey: "2026-10-08", hour: 22, minute: 30, period: .evening, body: """
        I am beginning to see that I answer the first solvable part of Sophie's story. She may still be describing what happened, but I am already sorting it into causes and next steps. In my head that is care. From her side it might feel like I am grading how she handled the day. I do not want that. Maybe I need to wait until I understand the whole problem before giving advice.
        """),
        SeedEntry(dayKey: "2026-10-09", hour: 8, minute: 40, period: .morning, body: """
        I want tonight to go better. If Sophie brings up the meeting, I will try to hear the full timeline before responding. I can ask a clarifying question and avoid telling her that she is overthinking. My goal is to be useful without making her prove that the pain is reasonable.
        """),
        SeedEntry(dayKey: "2026-10-09", hour: 21, minute: 50, period: .evening, body: """
        I waited longer tonight, but as soon as there was a pause I explained what I thought Sophie should do. She sighed and said she wished I would stay with her feelings for a minute instead of moving her past them. That sentence stung because I am not trying to rush her. Still, I can see that my response was aimed at ending the problem, while she was trying to show me what the problem felt like.
        """),
        SeedEntry(dayKey: "2026-10-10", hour: 19, minute: 40, period: .evening, body: """
        This week I kept trying to protect Sophie from pain by explaining it, correcting the part that seemed unfair, or giving her a next step. The intention is loving, but the pattern is clearer now: she starts with an experience, I turn it into a task, and then she becomes quieter or asks to finish. I think feeling helpless makes me reach for instructions because advice proves I am doing something. I want to support her more patiently. My current thought is that I should wait until she finishes, understand the whole situation, and then give gentler advice that fits better. I am not sure what else being helpful would look like yet.
        """)
    ]
}

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
        SeedEntry(dayKey: "2026-09-27", period: .evening, body: """
        Priya was walking me through why the handoff screen felt confusing. Before she finished, I opened the code and proposed changing the button labels. She paused and asked if she could finish explaining the flow first. I felt embarrassed in front of the team and immediately started defending why I had built it that way. The meeting ended without a decision. I keep replaying it as if she said I am bad at this job, but what she actually said was that the screen was confusing and she wanted to finish her explanation. The release is close, and I am worried everyone can see how inexperienced I am.
        """),
        SeedEntry(dayKey: "2026-09-28", period: .morning, body: """
        I woke up still tense about yesterday. My first impulse was to send Priya a long message explaining every constraint behind the screen. I drafted it, then stopped. I do not know that she thinks I am incompetent. I know she found the handoff confusing and that I interrupted her. Those are different facts. I am going to wait until our check-in rather than trying to repair my reputation before I understand the issue. I still feel exposed and defensive, especially because this is my first release with this team.
        """),
        SeedEntry(dayKey: "2026-09-28", period: .evening, body: """
        Our check-in was moved because Priya had another meeting. Part of me was relieved because I did not have to face the awkward conversation yet, and part of me stayed restless all afternoon. I noticed how quickly I filled the silence with guesses about what she might think. Nothing new actually happened between us today. I want to remember that uncertainty is uncomfortable, but it is not evidence that the worst explanation is true.
        """),
        SeedEntry(dayKey: "2026-09-29", period: .evening, body: """
        Most of today was ordinary release work. I fixed two small bugs, reviewed Sam's pull request, and finally wrote the missing test for the empty state. Priya and I exchanged a few normal messages about spacing, and neither of us mentioned Monday. That does not resolve the disagreement, but it is evidence that one awkward meeting has not ruined the collaboration. I noticed that I kept scanning her messages for criticism anyway. I want tomorrow's design review to be about understanding the problem, not proving that my first version was reasonable.
        """),
        SeedEntry(dayKey: "2026-09-30", period: .morning, body: """
        The design review is this afternoon. I feel anxious and already want to prepare a defense of every decision. I wrote down two facts instead: Priya has found the flow confusing, and I still do not understand the exact moment where she loses context. My goal is to ask for the example before I open the code. I am afraid that pausing will make me look unprepared, even though jumping to a solution has not helped.
        """),
        SeedEntry(dayKey: "2026-09-30", period: .midday, body: """
        The review went badly. I asked one question, but while Priya answered I saw what I thought was the fix and interrupted her. When she said I had missed the point, I felt a rush of embarrassment and anger. I argued that the deadline did not leave room for redesign. Right after the meeting I felt regret because I had repeated the exact behavior I meant to avoid. I need some distance before deciding what to say next.
        """),
        SeedEntry(dayKey: "2026-09-30", period: .evening, body: """
        The same pattern happened again. Priya started describing what confused her when moving from the list into the detail screen. I jumped in with a fix before she reached the example. She looked frustrated and said the proposed fix did not address what she was showing me. I heard that as criticism of me and argued about the deadline. Afterward I wrote one sentence that feels uncomfortably accurate: I keep hearing a problem with the screen as a problem with me. I am frustrated with her, embarrassed about my reaction, and worried that slowing down will make us miss the release.
        """),
        SeedEntry(dayKey: "2026-10-01", period: .midday, body: """
        Priya sent a screen recording of the saved-item edge case. Watching it made the problem obvious in a way our earlier discussion had not. I felt relieved to understand it and embarrassed that I had argued before seeing the full example. I replied with what I thought was happening and asked her to confirm before I changed anything. She confirmed it. The solution now looks smaller than the one I kept defending.
        """),
        SeedEntry(dayKey: "2026-10-01", period: .evening, body: """
        Priya sent a specific edge case this morning: returning to a saved item after its status changes. Once I saw it, the confusion made sense. We talked for ten minutes, I implemented the smaller state change, and she thanked me for turning it around quickly. That conversation does not fit the story that she rejects my work or thinks I am incapable. I still felt a little ashamed that I needed the example, but asking for details would have gotten us there faster than defending the old flow. The build passed before dinner, which was a relief.
        """),
        SeedEntry(dayKey: "2026-10-02", period: .midday, body: """
        I stayed away from the project for most of today. I went for a long walk, bought groceries, and called my brother. I expected the release anxiety to follow me all day, but it eased when I stopped checking team messages. Looking back at the week, the strongest moments were not all negative: I completed useful work, Priya gave me a concrete example, and we solved one issue together. The tense meetings still bother me. I want to find a way to respond that does not require pretending I am calm or agreeing with every suggestion.
        """),
        SeedEntry(dayKey: "2026-10-03", period: .evening, body: """
        I keep returning to the same question: am I trying to solve the problem before I understand what Priya needs? In both tense meetings, I offered an answer before she finished. Then I treated her correction as a judgment about my competence. I cannot know her intentions from that. What I can change is my part of the conversation. Tomorrow I want to ask what is confusing, repeat back what I heard, and only then suggest a fix. I am nervous that this will feel slow or scripted, but arguing has not saved us any time.
        """),
        SeedEntry(dayKey: "2026-10-04", period: .morning, body: """
        I reviewed last week and chose one thing to practice: before offering a solution, ask what Priya needs me to understand. If I feel defensive, I will try one clarifying question before explaining the implementation. I am not promising myself that I will never interrupt again. The goal is small enough to try during today's planning meeting. I still care about the deadline, and I can say when a request is too large. Listening first does not mean agreeing to everything.
        """),
        SeedEntry(dayKey: "2026-10-05", period: .evening, body: """
        Planning was rushed, but I managed to stay quiet through Priya's first example. I asked which part of the transition mattered most. She said the problem was losing context, not the wording I had focused on. We did not decide on a design today because another production issue took over the meeting. I felt impatient and wanted a quick answer. Still, the question gave me better information than my usual defense would have. I need to try it when the pressure is higher, not only when I have time to think beforehand.
        """),
        SeedEntry(dayKey: "2026-10-06", period: .morning, body: """
        We are revisiting the transition today. I feel nervous because the release clock is louder now, and I can already hear myself wanting to say we do not have time. I put one reminder beside my laptop: ask what context is being lost. If the requested change is too large, I can say that after I understand it. I want to find out whether the clarifying-question practice still works when I feel rushed.
        """),
        SeedEntry(dayKey: "2026-10-06", period: .midday, body: """
        The discussion was calmer than I expected. I asked Priya to finish the example, then repeated back that the person loses track of the item after returning from detail. She corrected one part without the conversation turning into an argument. I felt relief and a little pride that I stayed with the question. We found a narrower change, although I still need to test it before calling the issue solved.
        """),
        SeedEntry(dayKey: "2026-10-06", period: .evening, body: """
        Priya walked through the confusing example again. I let her finish, then said back what I thought the problem was: the person loses track of the item they were working on. She corrected one detail, and we agreed on a narrower change that keeps the context visible. I still felt pressure about the release and wanted to rush, but the conversation was productive. We left with a clear change and no argument. I do not think a single good meeting means the habit is fixed. It does show that understanding the example first can make the engineering decision smaller.
        """),
        SeedEntry(dayKey: "2026-10-07", period: .morning, body: """
        Yesterday's meeting went well, and I caught myself wanting to declare the problem fixed. This morning I feel more confident, but also wary of turning one success into a new story about myself. The loading-state review is later today. I want to use the same pause even if the concern sounds unlikely at first. The real test is whether I can recover when I do react too quickly.
        """),
        SeedEntry(dayKey: "2026-10-07", period: .evening, body: """
        I interrupted again today. Priya raised a concern about the loading state, and I started explaining why it was unlikely before she finished. I saw her expression and realized I was doing exactly what I wrote about. I stopped, said I had jumped ahead, and asked her to continue. She showed a slow-network case I had not considered. We did not have time to solve it, but the conversation recovered. I am disappointed that the old reaction came back so quickly. I am also glad I noticed and repaired it instead of spending the rest of the meeting defending my intentions.
        """),
        SeedEntry(dayKey: "2026-10-08", period: .evening, body: """
        Late this afternoon Priya asked whether the remaining loading issue could be fixed tonight. I checked the code and said I could investigate first thing tomorrow, but I could not responsibly promise a fix before understanding the cause. She was disappointed because she wanted it in the release. I felt guilty and worried that setting a limit would look unhelpful. We still disagree about whether the release should wait. Listening better does not remove every conflict, and it does not mean saying yes to work I cannot complete safely.
        """),
        SeedEntry(dayKey: "2026-10-09", period: .midday, body: """
        I reproduced the loading issue this morning and found that it only happens after a long background pause. I sent Priya what I found and proposed documenting the limitation while I test the safer fix. She replied that the explanation helped and agreed we should not rush it. I felt relieved, but I do not want to turn her agreement into proof that every boundary will be accepted. Yesterday was still uncomfortable. The useful part was being specific about what I knew, what I did not know, and when I could investigate.
        """),
        SeedEntry(dayKey: "2026-10-09", period: .evening, body: """
        I am tired after testing the background case, but the plan feels responsible. Priya agreeing not to rush the fix brought relief. I also know the disagreement yesterday was real, and I am still uneasy about how the release conversation will go. Being specific helped us decide what to do today; it did not erase the pressure or guarantee that the next boundary will be easy.
        """),
        SeedEntry(dayKey: "2026-10-10", period: .evening, body: """
        The practice partly helped. Pausing and asking a clarifying question helped in Tuesday's planning and Wednesday's design discussion. On Thursday I interrupted again, although I noticed and asked Priya to continue. Friday's boundary was still tense, and one disagreement remains unresolved. I do not need a completely new lesson yet. Next week I want to make the same practice smaller: ask one clarifying question before my first suggestion, especially when the deadline makes me want to move fast. I feel more prepared, but not magically confident.
        """)
    ]
}
#endif
