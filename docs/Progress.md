# Bearings development progress

Milestones: native journaling foundation, owner-directed Bearings rename/app icon, blue app linework, GitHub setup, map opening screen, and centered timeline, October 10–11, 2026.

## Emotional Zoom clarity pass — October 11, 2026

Added a 44-point navy magnifying-glass button to the editor header, below Done and above the rule. The owner-selected traditional magnifying-glass reference replaces the initial eyeglasses symbol with a clean system icon while preserving the control's placement and behavior. On demand, the on-device analysis boundary evaluates the visible draft, returns one exact vague excerpt when supported, explains what is difficult to understand and asks one open-ended question below the writing. Its shared navy sextant requests another interpretation. The result is transient, disappears when the draft changes, never rewrites or persists into the journal, and exposes unavailable/retry states. The analysis version is now 2 because the provider schema and instructions changed. This is the first clarity slice of Emotional Zoom; finer feeling choices and persisted accept/edit/reject remain unimplemented.

The generic iOS Simulator build passed. The complete 64-test unit suite passed with zero failures and one expected physical-model skip; one end-to-end UI test also passed and covered the result's sextant refresh. Its screenshot was reviewed and shows the intended icon placement, grounded excerpt and question. Real Apple-model generation for this new schema, physical-device layout, maximum Dynamic Type and Notion synchronization remain unverified. Exact commands and limits are in Testing.md. No publishing or pushing occurred.

## AI sextant refresh controls — October 11, 2026

Daily, weekly and monthly generated outputs now show a shared 44-point navy sextant control. It requests a fresh on-device interpretation by bypassing the selected valid cache, preserves the prior output through loading/failure and leaves user emotion corrections intact. All 14 analysis-service tests and two synthetic-provider UI flows passed, covering daily, weekly and monthly refresh plus correction preservation; the three output screenshots were reviewed. The complete app unit/UI suites, physical-device model generation and iOS 17 runtime were not rerun. Notion synchronization is pending. No publishing or push was performed.

## Single-entry day marker — October 11, 2026

The morning, midday and evening circles now show a centered 13-point navy `#323575` dot when that period has exactly one saved entry, replacing the numeral 1. Counts above one remain numeric, and VoiceOver continues to announce the exact entry count. A Debug simulator build and the focused period-save/reassignment/relaunch UI test passed; its saved-entry screenshot was reviewed and shows the centered navy dot. The full test suites, physical device and iOS 17 runtime were not rerun for this view-only change. Notion synchronization is pending. No publishing or push was performed.

## Implemented

- Existing Git repository preserved; local `codex/recollect-foundation` branch created.
- Native Xcode project, shared app/unit/UI-test scheme, deterministic project generator, privacy manifest, asset catalog and iOS 17 deployment target.
- Root `AGENTS.md`, scoped `.gitignore`, launch/run instructions and architecture/product/design/decision documentation.
- SwiftData local store, isolated explicit write transactions, stable UUIDs, civil Gregorian day/month identity, creation/modification timestamps, multiple entries, explicit morning/midday/evening periods, no CloudKit.
- Protected Application Support store, visible store-open recovery, and read-only local snapshots for future approved integration.
- Horizontal month timeline with date selection, entry markers, month navigation, date chooser and Today shortcut.
- Morning-left/midday-top/evening-right day branches, latest-period access, full entry list and additional-entry creation.
- Native editor with approved system font, period selection, long text, debounce/lifecycle/Done saving, explicit errors and retries, deletion confirmation and protection against deleted-entry resurrection.
- Native selected-date zoom/upward transition with reverse movement; true fade when Reduce Motion is enabled.
- Native Dynamic Type with scalable date cells and entry markers, a full-height horizontal timeline scroll surface, readable period labels, a keyboard/save footer, and compact metadata at the largest text sizes.

## Reference and owner decisions

All supplied Bearings Notion sources were reviewed, along with metadata, design context and screenshots for the three Reconnect Figma frames. The owner clarified the circles and approved the system font. Figma paper/ink/marker colors and the editor's oval/rule geometry are retained. The subsequent owner instruction changes decorative strokes to opaque `#323575`, as recorded below. The graphs are dynamic SwiftUI drawings; date labels, controls and entry lists are necessary functional adaptations of the preliminary prototype.

## Verification

Debug compilation and all 24 data/editor tests passed, including repeated real read-only write failures. Eight core UI workflow tests passed. Focused final checks passed for normal/Reduce Motion navigation, keyboard use, accessibility-extra-large and maximum-size writing/period assignment, maximum-size date selection, normal month navigation, and four-entry marker/persistence behavior at normal and maximum text sizes. Screenshots show complete metadata, writing, dates and remaining-count markers. The final unsigned device Release build passed. Native-frame review verified reverse layering without the observed blank frame. The final app was launched using its normal journal store in the iPhone 18 Pro simulator; a preview is saved locally as `docs/evidence/Bearings-Preview.png`. Existing screenshots, test logs and captured manifests remain historical evidence from before the rename. See `Testing.md` for exact evidence and device-level limits.

## Documentation synchronization

The original foundation product, architecture, references, decisions, tests and progress were synchronized to [iOS Development](https://app.notion.com/p/3f5076d4a2e181619c8bff6109e7ba69?pvs=204) under the existing Bearings Notion home. Saved content and parent hierarchy were fetched and verified; all six sections matched the final local documentation after native formatting normalization. At that milestone, no external GitHub repository had been created or pushed; the later GitHub setup is recorded below.

## Bearings rename and app icon

The owner explicitly renamed ReCollect to **Bearings** and requested the compass/map app icon. Current app branding, Xcode project/scheme/target names, source folders and brand-specific types, repository documentation, and the local development brief use Bearings. Existing bundle identity and the SwiftData `ReCollect` configuration / `ReCollect/Journal.store` location are retained to preserve saved writing. Historical evidence and source reference names remain intact.

The owner supplied and explicitly accepted `appIcon.png` for the app icon. Its artwork is preserved without recoloring or redrawing and resized only to 1024 × 1024 at `Bearings/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`; the root source remains untouched. The original flush-background, circular-compass and simplified-topographic-map request specified `#C8AB89` / `#323575` as design targets. Exact two-color enforcement is not claimed for the accepted image. The supplied-icon decision retained the approved paper/ink/marker palette; the subsequent blue-linework instruction is recorded below.

The renamed app passed all 24 data/editor tests, two focused UI tests covering saved edits/relaunch and Reduce Motion navigation, and an unsigned generic iOS Release build. The simulator Home Screen shows Bearings with the accepted compass icon. At the rename milestone, the local branch became `codex/bearings-foundation`; original signing configuration and journal identities are preserved. Exact checks and limits are recorded in `docs/Testing.md`.

The Bearings milestone's complete product, architecture, references, decisions, tests and progress were synchronized to [iOS Development](https://app.notion.com/p/3f5076d4a2e181619c8bff6109e7ba69) under the existing Bearings Notion home on October 10, 2026. The saved six-document content and parent hierarchy were fetched and verified; `docs/NotionSync.md` records the final source hashes.

## Blue app linework

The latest owner request changes decorative app line colors to opaque `#323575`. A shared `Line` colorset and `BearingsTheme.line` apply to the timeline horizontal line/ticks, day branches and entry dividers; the editor rule SVG uses the same blue stroke. Existing geometry is preserved. Text/control tint stays black Ink, period and entry marker fills stay grey, and Paper remains unchanged. The historical Figma black linework is retained in the original reference files.

Debug simulator compilation and two existing UI tests passed with zero failures. Timeline, day and editor screenshots were reviewed and show the navy linework. Source audit confirms the opaque sRGB token and complete coverage of custom line primitives. Exact checks and remaining verification limits are recorded in `docs/Testing.md`.

This linework milestone was synchronized to [iOS Development](https://app.notion.com/p/3f5076d4a2e181619c8bff6109e7ba69) under the existing Bearings home on October 10, 2026. The complete six-document saved snapshot and parent hierarchy were fetched and verified; `docs/NotionSync.md` records the final source hashes.

## Public GitHub setup

The owner requested GitHub setup for later Hacklanta submission, selected public visibility, and explicitly instructed that the project must not be submitted. The public [H-Blue/Bearings](https://github.com/H-Blue/Bearings) repository contains the committed app, icon, tests and documentation on its default `main` branch. Local `main` tracks `origin/main`; the prior local coding branch remains available. The README includes download/clone instructions, simulator setup, features, accurate test limits, and Codex/icon provenance. No hackathon submission has been made.

An unsigned Debug simulator build passed from a clean export of the committed source, without local signing changes or owner working materials. The published source was cloned without credentials and matched the local source commit; its README was fetched anonymously and matched the committed file. Only `main` was pushed. Local journal stores, credentials, build evidence, untracked working materials and Codex checkpoint refs were excluded. Exact evidence and remaining test limits are in `docs/Testing.md` and `docs/GitHub.md`.

The [Hacklanta guide](https://aluminum-soprano-222.notion.site/Hacklanta-2026-Hacker-Guide-3b81ccc4ed5c80f4b717c0ccc4b5df54#c5e8ee29f2bf4d9d954266fce5486f5c) requires public project code and a useful README; its submission checklist accepts clear run instructions as an alternative to a working demo link. GitHub setup covers those repository materials. Submission forms and a demo video remain separate owner work.

This GitHub setup milestone was synchronized to [iOS Development](https://app.notion.com/p/3f5076d4a2e181619c8bff6109e7ba69) under the existing Bearings home on October 10, 2026. The saved Decisions, Testing and Progress updates and the complete six-document snapshot were fetched and verified; `docs/NotionSync.md` records the final source hashes. No hackathon submission was made.

## Map opening screen

On October 11, 2026, the owner selected the right-curving river/ridge map for a minimum two-second opening screen, with Bearings at the top right and “Find what’s been lost inside.” beneath it. The accepted 1206 × 2622 artwork is bundled unchanged as `OpeningMap`. Native navy text respects safe areas and Dynamic Type. A scene-phase keyed task waits two uninterrupted active seconds; interrupted waits restart, and completed openings do not replay on ordinary background returns. Store initialization follows the opening and preserves its existing visible error/retry behavior. No persistence behavior, store identity or app icon changed.

Final Debug simulator compilation and both selected existing UI tests passed with zero failures in 82.880 seconds, covering saved edits across process relaunch and forward/reverse Reduce Motion navigation. iPhone 16 Pro screenshots were reviewed at normal and maximum text size. A warm-launch native recording has monotonic frame timestamps and shows approximately 2.13 seconds between the first fully rendered map frame and the first timeline frame. Exact evidence and remaining limits are in Testing.

This opening-screen milestone was synchronized to the existing iOS Development handoff on October 11, 2026. The saved Product, Architecture, Decisions, Testing and Progress additions and status updates were fetched and verified, preserving the previous handoff content. Verification evidence is in `docs/NotionSync.md`. The implementation is local; the GitHub repository remains at the prior owner-authorized setup commit.

## Centered timeline and pen shortcut

On October 11, 2026, the owner requested removal of the timeline branding/slogan and bottom helper text, a centered horizontal axis, scrolling with a thumb near the bottom, and a small navy ink pen in place of the Today label. The native horizontal scroll surface now fills the area below the controls. The pen is a thin SwiftUI fountain-pen outline in `#323575`, with an accessible 44-point button that opens today’s journal. Date cells, entry markers, month navigation and the native date chooser remain available; the selected-date transition now anchors at the actual timeline axis. Opening-screen branding and journal storage are unchanged.

Debug simulator compilation and all six selected UI test executions passed with zero failures: three at normal text size and three at the maximum accessibility size. They cover bottom swipes in both directions, preserved horizontal position after Back, earlier-month navigation/writing, Reduce Motion, large calendar dates, and four-entry markers with disk relaunch. iPhone 16 Pro and compact iPhone screenshots were reviewed; complete dates and remaining counts are visible. Exact evidence and device/runtime limits are in Testing. This timeline milestone was synchronized to the existing iOS Development handoff on October 11, 2026; saved source-derived updates and the unchanged parent hierarchy were fetched and verified. Evidence is recorded in `docs/NotionSync.md`. The implementation is local; the public GitHub source remains at the prior authorized setup milestone.

## Next work and boundaries

The native journaling foundation is ready for simulator review. Owner/device review of animation feel and real iPhone behavior follows. The broader assistant, cloud sync, export/backup, progressive reveal, subscriptions, analytics, social features and gamification remain outside scope. The approved local reflection milestone is described below.

## Approved local intelligence implementation — October 11, 2026

Implemented separate daily/period analyses and emotion corrections, additive creation-zone metadata, journal-day reassignment, an iOS 26-gated on-device Foundation Models adapter, complete Unicode-safe source segmentation, serialized generation, source-checked caching/invalidation and native reflection controls. The final simulator unit suite passed 59 tests, with one real-model check skipped. All 15 normal-size UI tests passed. The earlier physical suite passed 53 tests with one modelNotReady skip; signed development installation and Release compilation succeeded. All five final largest-text-size reflection flows passed, and their screenshots were reviewed. The real old-schema migration, repeated failed saves/retries, cache repair and correction recovery are verified with synthetic writing. Real Apple-model generation and quality remain unverified. Exact evidence is recorded in Testing.md. See LocalIntelligence.md and Deployment.md. The approved scope, implementation notes, deployment preparation and exact verification evidence were synchronized to the existing Bearings Notion hierarchy and fetched for saved-content verification. The AI task remains In progress and unchecked pending real-model acceptance; NotionSync.md records the scope and source hashes. No implementation push or TestFlight distribution is authorized.

## Emotional-learning roadmap and pitch notes — October 11, 2026

The owner requested an ordered plan before implementing the new direction. [HacklantaPlan.md](HacklantaPlan.md) sequences specs/demo stories, actual-model acceptance, story data/editable assumptions, Emotional Zoom, adaptive weekly lessons, difficult-moment help, reviewed support requests, testing/freeze, pitch, video, submission and practice. [EmotionalLearningSpec.md](EmotionalLearningSpec.md) defines feature acceptance and two invented stories; [PitchResearch.md](PitchResearch.md) preserves need statistics, Yale/RULER research, granularity findings, empathy/creativity claim limits and the AI/ML explanation. These are planned additions, not new implemented features or app efficacy evidence.

The two new plan/spec pages were created under the existing Bearings Notion home. The existing Pitch page was expanded without removing its earlier brainstorming. Nine new unchecked implementation/testing/pitch/practice tasks were added to the existing database; daily AI, Weekly Summaries, Demo Video, Submit Project and UI Improvements were reused and annotated. Weekly Summaries now accurately reads In progress because the feature is implemented but real-model acceptance remains outstanding. Saved page contents, task statuses, source links and parent hierarchy were fetched and checked. NotionSync.md records the exact destinations.

The official deadline is October 11, 2026 at 9:00 AM EDT. The plan prioritizes a coherent core story and a public 2–3 minute video before optional polish; final judging permits a 3-minute pitch and 2-minute Q&A. Existing source publication does not include later local changes. No new app code, AI/device run, Xcode test, publication, message to contacts or hackathon submission was performed for this planning request. Existing project/asset changes were preserved.

## Expanded emotional-learning research — October 11, 2026

The owner requested extensive research supporting the project. [ResearchEvidence.md](ResearchEvidence.md) now provides 37 source cards, a six-source pitch shortlist, distinctions between association and intervention effects, feature-specific design implications, defensible pitch wording and a proposed evaluation path. The review covers the need for connection/support, granularity/labeling, adult online/workplace EI education, Yale/SEL, journaling, perspective, calming/memory options, planning/review, empathy/outreach, developer wellbeing/creativity, privacy and AI limits. Null findings and transfer limits are included; no study is represented as validation of Bearings. The five-day trial's transformed differentiation score is explicitly distinguished from a percentage reduction in negative emotion. This is a documentation/research milestone; app implementation and real-model acceptance were not changed.

## Chosen relationship demo journal — October 11, 2026

Prepared [RelationshipDemoJournal.md](RelationshipDemoJournal.md): 18 fictional entries for Alex and Jess over September 21–October 4 (14 civil days, nine entries per Monday–Sunday week). The matching `docs/fixtures/RelationshipDemoJournal.json` carries stable UUIDs, native period values, civil day keys and illustrative creation timestamps. The input text includes ordinary college life, evidence against rejection assumptions, three premature-advice conversations, an explicit support-preference conversation, dinner/listening, a relapse and repair, study-time boundaries and an unresolved exam worry.

[RelationshipDemoGuide.md](RelationshipDemoGuide.md) documents the existing editor/date workflow and separate Debug test store, period-by-period review expectations, honest labeling of fictional/cached/prepared responses, an authored listening lesson, review branches and a prompt-tuning approach. It explicitly distinguishes implemented recaps from proposed Emotional Zoom/adaptive lessons and keeps expected findings out of model inputs. All entries and guidance were synchronized to a new child of the existing Pitch page and fetched for semantic comparison; the Pitch reference was added without changing earlier notes.

The JSON is preparation material, not an implemented in-app import format. No app source, model instructions/schema, device journal, AI cache or project membership changed. Real inference and quality for this fixture remain unverified; no publishing, pushing or submission occurred.

## Professional case study and safety assessment — October 11, 2026

The owner requested a professional case study and an explainable safety argument for judges. Prepared [ProfessionalCaseStudy.md](ProfessionalCaseStudy.md) and a five-page local PDF under output/pdf. The fictional workplace scenario follows an engineer responding defensively to feedback, choosing a communication practice, experiencing partial progress and repair, and keeping an unresolved disagreement visible. It is proposed as an alternative to the existing relationship story; original stories/fixtures are preserved. All dialogue/outcomes are authored illustrations, and implemented reflection features are distinguished from proposed Emotional Zoom, source-linked editable assumptions and adaptive lessons.

Rechecked existing test result summaries and inspected the current local AI/persistence source. The safety argument covers local processing, user corrections, original-writing separation, source checks, reliable saves, default guardrails and residual risks. It explicitly identifies backup eligibility, protection after the first unlock, the lack of a separate app lock, generic refusal handling and pending semantic/lesson evaluation. No claim of clinical safety, treatment, psychological improvement, NIST certification or live generation is made. The owner's report of working AI is recorded separately from the older skipped physical-model test.

The PDF was rendered and every final page visually reviewed; Testing.md records the exact documentation checks and pending device/behavior evidence. App code, model generation instructions, private journals and project membership were not changed. The judging rubric has not yet been supplied. Notion synchronization remains pending for this local review draft; no publication, pushing, submission or messaging occurred.

## Transient timeline month label — October 11, 2026

The timeline no longer holds the month and year on screen continuously. Its center date-picker control uses a calendar icon at rest; a horizontal timeline drag or previous/next-month action reveals the current month and year, restarts a five-second timer, then returns to the icon. The state transition respects Reduce Motion, and the control's accessible label follows the visible state while retaining the selected month as its value.

A focused simulator UI test verified the title is hidden initially, appears after a horizontal drag and hides after five seconds. The signed Debug app was rebuilt, installed and launched on the connected iPhone with the existing isolated professional demo store preserved. Notion synchronization is pending; no push, publication or submission occurred.

## Professional case study demo journal — October 11, 2026

Prepared [ProfessionalCaseStudyJournal.md](ProfessionalCaseStudyJournal.md) and the matching `docs/fixtures/ProfessionalCaseStudyJournal.json`: 14 fictional Alex/Priya entries across two complete Sunday–Saturday weeks from September 27 through October 10. There is one entry per civil day, leaving Sunday, October 11 empty for the completed prior-week reflection. The story moves from defensive feedback conversations through a small clarifying-question practice, partial success, a relapse and repair, a work boundary and a self-reported “partly helped” review. [ProfessionalCaseStudyDemoGuide.md](ProfessionalCaseStudyDemoGuide.md) records the presentation labels and manual fallback.

A Debug-only, explicit loader now seeds this fixture only when both `--uitesting` and `--seed-professional-case-study` are supplied and the separate UI-test store is empty. The signed app was installed on the connected iPhone 16 Pro and launched against that isolated store. Device-store inspection confirmed 14 distinct entry days spanning September 27–October 10 and none on October 11. Weekly periods and timeline major marks now use Sunday–Saturday boundaries; on Sunday, the weekly control is “Last week” and targets the completed prior period. Analysis version 3 prevents reuse of monthly results generated with the old Monday boundary. The normal journal store was not selected or read. Real Apple-model output for this fixture remains unrequested and unreviewed. Notion synchronization is pending; no push, publication or submission occurred.

## Summary-first daily reflections — October 11, 2026

Daily reflection output now begins with a clearly labeled summary of what happened during the day, followed by “Notable emotions” only when the writing supports a specific emotion. Duplicate primary/secondary suggestions collapse into one item, and the model's internal mixed/uncertain fallback is not presented as a discovered emotion. The writer can still choose any feeling, including mixed/uncertain; that correction remains visible, survives regeneration and takes precedence over the AI suggestion.

The on-device generation instructions now tell the model not to infer emotion from ordinary events, not to force an emotion, and to use uncertain with no secondary emotion when support is insufficient. Pairwise daily combination retains the same rule. Analysis version 4 invalidates earlier cached daily/period results so they regenerate under these instructions. The data schema and original journal records are unchanged.

All 64 simulator unit tests passed with the physical-model-only test skipped. The focused deterministic UI flow passed and verifies the summary appears above notable emotions, a Peace item is shown for supported fixture output, and correction/refresh behavior remains intact. The signed Debug app was built, installed and launched on the connected iPhone 16 Pro without resetting the isolated professional demo store. Real Foundation Models wording and emotional accuracy were not semantically reviewed in this change. Notion synchronization is pending; no push, publication or submission occurred.
