import SwiftUI
import SwiftData

struct BearingsRootView: View {
    @Query private var entries: [JournalEntry]
    @State private var store: JournalStore
    @State private var analysisService: JournalAnalysisService
    @State private var contactStore: TrustedContactStore
    @State private var selectedDay: JournalDay?
    @State private var zoomAnchor = UnitPoint.center
    @State private var editor: EditorRoute?
    @State private var showsSettings = false
    @State private var pendingSafetyCheckIn = false
    @State private var showsSafetyCheckIn = false
    @AppStorage("safetyCheckInOfferSeconds") private var safetyOfferSeconds = 30
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.scenePhase) private var scenePhase
    private let onRetryRead: () -> Void
    private let safetyService: JournalSafetyCheckService
    private let contactPinger: any TrustedContactPinging

    private var reduceMotion: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--reduce-motion") { return true }
        #endif
        return systemReduceMotion
    }

    init(container: ModelContainer, onRetryRead: @escaping () -> Void,
         safetyEvaluator: any JournalSafetyEvaluating = ConservativeJournalSafetyEvaluator(),
         contactPinger: any TrustedContactPinging = PreviewOnlyTrustedContactPinger()) {
        var descriptor = FetchDescriptor<JournalEntry>(sortBy: [SortDescriptor(\JournalEntry.createdAt)])
        descriptor.includePendingChanges = false
        _entries = Query(descriptor)
        let store = JournalStore(context: container.mainContext)
        _store = State(initialValue: store)
        _analysisService = State(initialValue: JournalAnalysisService(store: store, intelligence: Self.intelligence()))
        _contactStore = State(initialValue: TrustedContactStore(context: container.mainContext))
        safetyService = JournalSafetyCheckService(evaluator: safetyEvaluator)
        self.contactPinger = contactPinger
        self.onRetryRead = onRetryRead
    }

    var body: some View {
        ZStack {
            PaperBackground()
                .zIndex(0)
            if _entries.fetchError != nil {
                ContentUnavailableView {
                    Label("Your journal couldn’t load", systemImage: "book.closed")
                } description: {
                    Text("Bearings couldn’t read its local entries. Try again when your device is unlocked. Your saved journal has not been replaced.")
                } actions: {
                    Button("Try again", action: onRetryRead)
                }
            } else {
            TimelineView(entries: entries, emotions: timelineEmotions, selectedDay: selectedDay,
                         onSelect: openDay, onSettings: openSettings)
                .scaleEffect(selectedDay == nil || reduceMotion ? 1 : 1.8, anchor: zoomAnchor)
                .offset(y: selectedDay == nil || reduceMotion ? 0 : -180)
                .opacity(selectedDay == nil ? 1 : 0)
                .allowsHitTesting(selectedDay == nil)
                .accessibilityHidden(selectedDay != nil)
                .zIndex(1)

            if let day = selectedDay {
                DayView(day: day, entries: entries.filter { $0.dayKey == day.key }, analysisService: analysisService,
                        onBack: closeDay, onEdit: { entry in
                    analysisService.cancel()
                    editor = EditorRoute(day: day, entry: entry, period: entry.period)
                }, onNew: { period in
                    analysisService.cancel()
                    editor = EditorRoute(day: day, entry: nil, period: period)
                })
                .transition(reduceMotion ? .opacity : .offset(y: 160).combined(with: .opacity))
                .zIndex(2)
            }
            }
        }
        .coordinateSpace(name: "timelineRoot")
        .foregroundStyle(BearingsTheme.ink)
        .sheet(item: $editor, onDismiss: presentPendingSafetyCheckIn) { route in
            JournalEditorView(day: route.day, entry: route.entry, period: route.period, store: store,
                              analysisService: analysisService, onCommittedSave: evaluateCommittedWriting,
                              onSafetyReset: { pendingSafetyCheckIn = false })
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView(contactStore: contactStore)
        }
        .sheet(isPresented: $showsSafetyCheckIn) {
            SafetyCheckInView(contactStore: contactStore, pinger: contactPinger,
                              offerSeconds: safetyOfferSeconds)
        }
        .safeAreaInset(edge: .bottom) {
            if case .failed(let message)? = analysisService.states["storage"] {
                VStack(alignment: .leading, spacing: 8) {
                    Text(message).font(.footnote)
                    Button("Try again") { analysisService.loadStored() }
                        .frame(minHeight: 44).accessibilityIdentifier("reflection.storage.retry")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24).padding(.vertical, 8)
                .background(BearingsTheme.paper)
            }
        }
        .task(id: RootAnalysisTrigger(day: selectedDay, writing: editor != nil, active: scenePhase == .active)) {
            analysisService.loadStored()
            await resumeAnalysis()
        }
        .onChange(of: store.revision) { _, _ in analysisService.loadStored() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { analysisService.cancel() }
            else { presentPendingSafetyCheckIn() }
        }
    }

    private var timelineEmotions: [String: JournalEmotion] {
        let writtenDays = Set(entries.filter { !$0.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.map(\.dayKey))
        var emotions = analysisService.daily.filter {
            writtenDays.contains($0.key) && !$0.value.isStale && $0.value.analysisVersion == JournalAnalysisService.version
        }.mapValues { $0.content.primaryEmotion }
        for (key, emotion) in analysisService.overrides where writtenDays.contains(key) { emotions[key] = emotion }
        return emotions
    }

    private func resumeAnalysis() async {
        guard !Task.isCancelled, editor == nil, scenePhase == .active, _entries.fetchError == nil else { return }
        await analysisService.analyzeChangedDays()
        guard !Task.isCancelled, editor == nil, scenePhase == .active else { return }
        if let selectedDay { await analysisService.analyze(day: selectedDay) }
    }

    private static func intelligence() -> any JournalIntelligence {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--uitesting") {
            if arguments.contains("--ai-unavailable") { return SyntheticJournalIntelligence(isAvailable: false) }
            if arguments.contains("--ai-fixture") { return SyntheticJournalIntelligence(isAvailable: true) }
        }
        #endif
        return JournalIntelligenceFactory.make()
    }

    private func openDay(_ day: JournalDay, anchor: UnitPoint) {
        zoomAnchor = anchor
        withAnimation(reduceMotion ? .easeInOut(duration: 0.18) : BearingsTheme.transition) {
            selectedDay = day
        }
    }

    private func closeDay() {
        withAnimation(reduceMotion ? .easeInOut(duration: 0.18) : BearingsTheme.transition) {
            selectedDay = nil
        }
    }

    private func openSettings() {
        guard editor == nil, !showsSafetyCheckIn else { return }
        showsSettings = true
    }

    private func evaluateCommittedWriting(_ committedText: String) {
        do {
            let signals = try safetyService.evaluateAfterSave(succeeded: true, committedText: committedText)
            pendingSafetyCheckIn = !signals.isEmpty
        } catch {
            // Evaluation failure never changes or blocks the committed journal.
            pendingSafetyCheckIn = false
        }
    }

    private func presentPendingSafetyCheckIn() {
        guard pendingSafetyCheckIn, editor == nil, !showsSettings, scenePhase == .active else { return }
        pendingSafetyCheckIn = false
        showsSafetyCheckIn = true
    }
}

private struct RootAnalysisTrigger: Equatable {
    let day: JournalDay?
    let writing: Bool
    let active: Bool
}

#if DEBUG
/// Synthetic local responses for UI verification; never used by a release build.
private struct SyntheticJournalIntelligence: JournalIntelligence {
    let isAvailable: Bool

    func availability() async -> IntelligenceAvailability {
        isAvailable ? .available : .unavailable("On-device reflections are unavailable on this test device. You can keep writing and choose your own feeling.")
    }

    func analyze(_ text: String) async throws -> DailyAnalysisContent {
        guard isAvailable else { throw AnalysisError.generationFailed }
        return DailyAnalysisContent(summary: "A quiet day by the river brought a moment of peace.", primaryEmotion: .peace,
                                    secondaryEmotion: .joy, importantEvents: ["A walk by the river"],
                                    emotionalTrajectory: "The writing moves toward peace.")
    }

    func reflect(_ text: String, kind: ReflectionKind) async throws -> ReflectionContent {
        guard isAvailable else { throw AnalysisError.generationFailed }
        return ReflectionContent(overview: "This \(kind.rawValue) reflection remembers a quiet walk by the river.",
                                 importantEvents: ["A walk by the river"], emotionalThemes: "Peace and joy appear in the writing.",
                                 relationships: "The writing provides insufficient information about relationships.",
                                 interests: "Walking outdoors appears in the writing.", changes: "The writing moves toward peace.")
    }

    func extractWeeklySignals(_ text: String) async throws -> WeeklySignals {
        guard isAvailable else { throw AnalysisError.generationFailed }
        let evidenceLines = text.split(separator: "\n").compactMap { line -> String? in
            guard line.hasPrefix("[E"), let separator = line.firstIndex(of: " ") else { return nil }
            return String(line[line.index(after: separator)...])
        }
        guard let excerpt = evidenceLines.first(where: {
            let value = $0.lowercased()
            return value.contains("walk") || value.contains("journal entry")
        }) ?? evidenceLines.first else { throw AnalysisError.invalidOutput }
        // Prefer the journal day's evidence line. The requested-week header
        // remains a valid in-period fallback when a long packet is split in
        // the middle of an entry and the chunk has no day heading.
        let currentDayLine = evidenceLines.first { $0.hasPrefix("CURRENT DAY ") }
        let daySource = currentDayLine ?? text
        let dayKey = daySource.range(of: #"\d{4}-\d{2}-\d{2}"#, options: .regularExpression)
            .map { String(daySource[$0]) } ?? "2026-10-05"
        let focus = GroundedWeeklySignal(statement: "The writer repeatedly focused on a walk with a friend.",
                                         evidenceExcerpt: excerpt)
        return WeeklySignals(focusAreas: [focus],
                             importantEvents: [DatedWeeklyEvent(dayKey: dayKey,
                                                                 statement: "The writer took a walk with a friend.",
                                                                 evidenceExcerpt: excerpt)],
                             explicitGoals: [], progress: [], obstacles: [], unfinishedThreads: [],
                             emotionalChanges: [], precedingWeekContinuity: [])
    }

    func composeWeeklyReflection(_ text: String) async throws -> ReflectionContent {
        guard isAvailable else { throw AnalysisError.generationFailed }
        return ReflectionContent(
            overview: "This weekly reflection remembers a quiet walk with a friend.",
            importantEvents: [],
            emotionalThemes: "The evidence is insufficient to describe a change in emotion.",
            relationships: "", interests: "", changes: "",
            weeklyDetails: WeeklyReflectionDetails(
                workFocus: "The writer focused on a walk with a friend.",
                progressAndUnfinished: "The evidence is insufficient to identify progress or unfinished work.",
                whatHelped: "The evidence is insufficient to identify what helped.",
                realisticImprovement: "There is insufficient evidence for a specific improvement.",
                lessonReadiness: .insufficientEvidence,
                readinessEvidence: [],
                reflectionQuestion: "What would you want to notice if a similar moment happens next week?"
            )
        )
    }

    func emotionalZoom(_ text: String) async throws -> EmotionalZoomContent {
        guard isAvailable else { throw AnalysisError.generationFailed }
        let excerpt = text.localizedStandardContains("I feel bad") ? "I feel bad" : nil
        return EmotionalZoomContent(
            vagueExcerpt: excerpt,
            explanation: excerpt == nil
                ? "This writing is specific enough to follow."
                : "This phrase does not yet show what felt difficult or what happened.",
            probingQuestion: excerpt == nil
                ? "What detail feels most important to remember?"
                : "What happened that made this feel difficult?"
        )
    }
}
#endif

private struct EditorRoute: Identifiable {
    let id = UUID()
    let day: JournalDay
    let entry: JournalEntry?
    let period: JournalPeriod
}
