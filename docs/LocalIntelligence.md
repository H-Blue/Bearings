# Bearings local intelligence

Implementation reference, October 11, 2026. This document describes the current source; executed checks and remaining verification are recorded in [Testing.md](Testing.md). The approved scope is [BEARINGS_AI_IMPLEMENTATION.md](BEARINGS_AI_IMPLEMENTATION.md). Older documents describing AI as future work describe the earlier journaling foundation.

## Components and boundaries

| Component | Responsibility |
| --- | --- |
| `JournalStore` | Fresh committed reads, isolated journal/derived writes, explicit saves, invalidation and fingerprint checks. |
| `JournalEntrySnapshot` / `LocalJournalRetrieving` | Immutable journal values passed into local analysis. |
| `JournalIntelligence` | Replaceable asynchronous provider interface with availability, daily analysis, period reflection and editor Emotional Zoom operations. |
| `AppleJournalIntelligence` | Apple on-device availability checks, trusted instructions, fresh sessions and guided output. |
| `JournalAnalysisEngine` | Serial inference, complete source segmentation, adaptive context retries and hierarchical combination. |
| `JournalAnalysisService` | Observable availability/results, cache reuse, task coordination, cancellation and completion triggers. |
| `AnalysisTypes` / `AnalysisRecords` | Framework-independent values, civil periods, fingerprints and separate SwiftData derived records. |
| `DailyReflectionSection` / `ReflectionView` / `EmotionPalette` | Daily and period results, correction/retry controls and accessible timeline indicators. |
| `JournalEditorView` | A user-triggered, transient Emotional Zoom over the current draft; the result is discarded when the draft changes. |

Original journal writing remains authoritative. Summaries and emotion suggestions are interpretations, stored separately and labeled in the interface. The broader assistant, book retrieval, cloud inference, sync and progressive design reveal are outside this milestone.

## Journal metadata and additive storage

`JournalEntry` retains its existing UUID, `body`, `periodRawValue`, `createdAt`, `modifiedAt` and Gregorian civil `dayKey`. It adds optional `createdTimeZoneIdentifier`. New entries receive the current creation zone; existing entries retain `nil` because their original zone is unknown. Creation time and creation zone are preserved during edits and moves. `modifiedAt` advances on body, period or day changes, with a nondecreasing policy if the device clock moves backward. Unchanged saves do not alter it.

The selected day describes the experience rather than the saving instant. A backdated entry can be created today, retain today's exact creation timestamp and zone, and belong to yesterday's `dayKey`. Travel never reinterprets that key. The editor maintains a separate selected-day draft and explicitly saves it with the writing and period.

The SwiftData schema contains `JournalEntry`, `DailyAnalysisRecord`, `ReflectionRecord` and `EmotionOverrideRecord`. Daily records have a unique day key; period records have a unique kind/start/end key. They store validated Codable content as JSON `Data`, source fingerprints, generation timestamps, analysis versions and stale flags. Corrections are separate records with an emotion and modification timestamp. Removing a day's last entry or regenerating its analysis preserves its correction.

The optional journal addition and new empty tables permit SwiftData's inferred additive migration. No historical timestamp or zone is fabricated. `JournalMigrationTests` writes the frozen pre-AI `JournalEntry` shape into a real file store, then opens it through the current schema and verifies journal identity/content/timestamps, unknown legacy zones, new correction storage and a further reopen. Its executed result belongs in Testing.md.

The bundle identifier, configuration name `ReCollect`, and Application Support `ReCollect/Journal.store` path remain compatibility values. Initialization failures reach the existing visible retry screen; production never substitutes an empty temporary store.

## Transaction and cache correctness

Every mutation uses a fresh transaction context with autosave disabled. Journal changes and the invalidation of their dependent daily/weekly/monthly results share one explicit save. Failed saves roll back only that context. Visible entries are mirrored only after a successful commit; independent editor drafts remain available to retry. All store reads use fresh contexts and exclude pending changes, preventing an observed model's unsaved edit or insertion from becoming analysis input.

Entry creation, editing, deletion and reassignment mark affected daily records stale and mark every stored overlapping period stale, including clipped weeks. A move affects both civil days. Correction changes invalidate overlapping reflections while preserving the original AI classification. Successful journal writes enqueue changed days; derived saves update the UI revision without enqueueing another journal-analysis cycle.

SHA-256 fingerprints use length-prefixed values, source UUIDs, day keys, complete bodies, periods and creation/modification instants, plus the analysis version. A reflection fingerprint also includes the requested period and applicable corrections. Fingerprints are cache identities, never logs or exported journal data. This detects content changes even when two edits share the same modification timestamp.

Daily and reflection caches are reused only when the stale flag is clear, the version matches and the current source fingerprint matches. Analysis version 3 marks the Sunday–Saturday reporting change so monthly caches generated under the earlier Monday boundary are not reused. Before persisting generated output, `JournalStore` compares the fingerprint again in the isolated transaction. A changed source throws `AnalysisError.sourceChanged`; an old result cannot overwrite current content. Daily coordination makes one bounded retry from the latest committed source. Period failures remain visible and retryable. Malformed selected derived payloads or period metadata are treated as unusable caches: an available model can regenerate and replace only that interpretation through the same source-checked transaction. Fetch errors still propagate. Valid manual corrections load independently of derived records, so damaged interpretations cannot hide a committed choice. Without an available model, corrupt derived bytes remain saved and the read failure stays visible.

## Civil reporting periods

Weeks begin Sunday and end Saturday. On a Sunday, the weekly review targets the completed prior Sunday–Saturday period; during the rest of a week it targets the containing week. Calendar months run from their first through last civil day. `AnalysisPeriod` calculates these boundaries using a Gregorian calendar in UTC civil space; timestamps and the device's current zone do not decide membership. The journal's representable years remain 1–9999. Boundary weeks clamp their date values before conversion back to civil components, preserving the correct era at the earliest supported year.

Daily analysis combines all nonblank committed entries with the same day key. Weekly reflection uses current daily summaries, dated important events, trajectories and the user's chosen emotion when present. Monthly reflection combines weekly reflections clipped to that month and a separate collection of that month's dated daily facts. For example, a September 28–October 4 week contributes only October 1–4 to October's monthly reflection. A cached full week spanning another month is never substituted for that clipped period.

Important events are preserved independently from prose combination. Period results use the dated daily event collection rather than accepting a shorter model-produced event list. This preserves extracted facts through the hierarchy; it does not establish that a model extracted every real event correctly. Original journal entries remain available for review.

## Local model support

The app continues targeting iOS 17. `canImport(FoundationModels)` gates the framework at compilation, and an iOS 26 availability check creates the Apple provider only on supported operating systems. Earlier systems receive an unavailable provider while retaining journaling and manual emotion choices. Only `SystemLanguageModel.default` is used. Apple's documentation identifies this model as on-device and requires availability checks and a fallback experience. [Apple: generating content](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models)

The provider checks device eligibility, disabled Apple Intelligence, a model that is still preparing, other unavailability and the current locale. It rechecks before generation. Useful unavailable messages preserve access to the saved journal; no remote fallback is implemented. The installed Xcode 27 SDK exposes the core APIs from iOS 26, exact token counting from iOS 26.4, and the newer `LanguageModelError` from iOS 27. The source gates each optional API independently and recognizes the older context-window error as well. [Apple: tokenCount](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/tokencount(for:))

Guided generation uses `@Generable` output structures and an enum containing only the eight supported emotions. `@Guide` descriptions request concise, grounded fields. The adapter trims and validates output before use. Emotional Zoom requires any identified vague passage to be an exact excerpt from the submitted draft, a tentative explanation and one non-diagnostic open-ended question. Instructions treat journal material as data, preserve ambiguity, distinguish the writer's emotions from other people's and prohibit invented events or diagnoses. These instructions reduce errors; they do not make semantic accuracy guaranteed. [Apple: guided generation](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation)

## Context size, scheduling and interruption

Each provider request creates a new session. The engine serializes expensive operations and splits every source entry into Unicode-scalar-safe segments with a 2,400 UTF-8 byte budget. Joined segments reproduce the complete input; byte budgeting is a conservative policy rather than an exact tokenizer count. Context errors recursively split the failed segment, with a lower bound that produces a visible error rather than dropping content. Pairwise combination reduces intermediates with a bounded number of rounds.

On iOS 26.4 and later, the provider counts prompt, instruction and generated-schema tokens, reserves 1,200 tokens for output/framework overhead, and compares the total with `model.contextSize`. Earlier supported runtimes rely on segmentation and adaptive handling of the framework's context error. Each request caps generated response tokens at 650. Apple's context guidance explains that prompts, instructions, schemas and responses share the session budget and recommends processing smaller pieces separately. [Apple: managing context](https://developer.apple.com/documentation/foundationmodels/managing-the-context-window)

Analysis begins from successfully saved entries after editor completion, when a day opens, or when the app resumes with queued changes. Editor keystrokes and timeline color reads do not trigger inference. The editor's navy magnifying-glass control is the explicit exception: when pressed, it submits the draft exactly as displayed, then shows one grounded clarity note and probing question below the writing. This output is transient, is never inserted into the entry or persisted as analysis, and is canceled and removed when the draft changes or the editor closes. Its navy sextant requests another interpretation of the same visible draft. Opening a period reflection requests generation or reuses its cache. Every displayed daily, weekly and monthly output has the same accessible navy sextant button, which explicitly bypasses the selected result's valid cache and requests a new on-device interpretation. The previous stored result remains visible during generation or failure; the replacement still passes the committed-source fingerprint check and saves through the same isolated derived transaction. Refreshing never removes a separate emotion correction. The service maintains task identities so a duplicate request awaits ongoing work, including a month and an independently opened clipped week sharing the same period. App inactivity and entry editing cancel active service tasks; cancellation is checked around inference and before a derived save. No guaranteed background execution is assumed. Tasks waiting for serialized inference may finish cancellation only after earlier work releases the slot.

## Emotion presentation and corrections

The taxonomy is joy, peace, sadness, anger, fear, loneliness, love and mixed/uncertain. A fixed palette maps these values to gold, sage, muted blue, terracotta, dusty purple, gray-brown, rose and neutral. The new outlined day indicator uses this palette; decorative `Line` remains opaque `#323575`, journal markers remain gray and text/control tint remains Ink.

The selected correction takes precedence over an AI primary emotion. Choosing “Use AI suggestion” removes only the correction. A stale AI result remains labeled as earlier analysis, and stale AI emotion suggestions do not color the timeline. Timeline accessibility includes the emotion in text; color alone is not the meaning. Cached stored values render the indicators without another model request. At the two largest accessibility sizes, the day header uses native icons with complete accessible names and 44-point targets; its full date uses an uncapped scalable caption. Reflection content and native metadata controls remain scrollable.

## Privacy and verification limits

The implementation has no network client, cloud AI provider, analytics SDK, CloudKit store or journal export path. Journals, corrections and generated results stay in the local SwiftData store. Provider/framework error payloads and transcripts are neither logged nor shown; unknown errors receive content-free messages. Synthetic UI and unit fixtures contain invented journal writing.

The directory and SQLite store/companions retain native iOS `completeUntilFirstUserAuthentication` protection. This supports use after the first unlock; it is not a claim that the store becomes inaccessible whenever the screen locks. Local persistence is separate from a user's OS-managed device backup: app data can be included in device backups according to system settings. Bearings does not implement cloud sync or send journal content for inference. Backup exclusion, encryption beyond platform protection and synchronization policy require a separate decision.

Ordinary tests inject deterministic intelligence and need no real model. The physical iPhone availability check returned modelNotReady; that unavailable state was verified. Model-ready generation, summary quality, semantic emotional accuracy, energy/latency, locked-device behavior and offline execution remain unverified. A successful simulator build or synthetic response is not evidence of real Foundation Models generation. [Deployment.md](Deployment.md) describes device and distribution preparation; [Testing.md](Testing.md) records what actually ran.
