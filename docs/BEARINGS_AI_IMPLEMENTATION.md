# Codex Development Prompt: Bearings AI Intelligence & Journal Infrastructure

## Owner-approved repository adaptation — October 11, 2026

The owner approved this local AI implementation as the next Bearings milestone and authorized publishing this specification and starting a project chat. The earlier no-AI MVP restriction is superseded only for the on-device functionality described here. The full personal assistant, cloud models, sync, analytics, subscriptions, social features and progressive reveal remain outside scope.

Read `AGENTS.md` first. Existing journal persistence, timestamps, civil-day identity and retrieval interfaces already exist; extend and verify them rather than replacing them. Preserve the bundle identifier, SwiftData configuration named `ReCollect`, and `ReCollect/Journal.store` path as compatibility values. The brand and source directory are Bearings.

Retain iOS 17 support for journaling. Gate Foundation Models imports, types and calls according to the actual installed SDK and supported OS versions, and expose useful unavailable states. Do not raise the deployment target merely to enable AI. Consult current official Apple documentation during implementation.

The current model uses `body`, `createdAt`, `modifiedAt`, `dayKey` and `periodRawValue`. These satisfy the conceptual content, creation time, update time, journal day and journal period requirements below. Preserve `dayKey` as a Gregorian civil date through travel and daylight saving changes; never replace it with an absolute `Date` as authoritative day identity. Add creation-time-zone metadata for new entries without inventing historical values. Use safe optional/defaulted additions and validate migrations against existing file-backed data.

All journal and derived-data writes must use isolated transaction contexts, explicit saves, and visible error/retry behavior. Analyze only successfully committed snapshots, and discard results whose source revision changed during generation. Preserve existing failed-save/retry tests and editor draft isolation.

Honor the owner-selected opening map, icon, navigation and current design hierarchy. Emotion colors may appear in a distinct accessible day indicator; do not recolor the opaque `#323575` decorative timeline line/ticks, branches, entry dividers or editor rule. Preserve black Ink controls/text, grey journal Marker fills, and Paper. If the planned emotion presentation materially conflicts with these decisions, prepare a concrete option for owner review while continuing independent persistence and analysis work.

Use explicit Gregorian civil boundaries for daily, weekly and monthly reflections. Define and document week start. A week spanning two months must not introduce out-of-month experiences into a monthly reflection; filter source days/events to the requested month or generate clipped week inputs.

Make focused local commits while preserving existing work. This handoff authorizes implementation and local build/testing, not later implementation pushes, public releases, paid services, cloud AI, or external beta distribution. Prepare TestFlight requirements, but obtain explicit owner approval before uploading/distributing a build. Follow repository instructions for meaningful Notion milestone synchronization and record pending synchronization accurately.

Handoff status: this is an approved task specification, not evidence of implemented AI. All implementation checklist items remain unchecked. The original 20 numbered sections and completion checklist are retained below, with repository-specific naming and persistence adaptations.

---

## ROLE

You are a senior iOS software engineer specializing in Swift, SwiftUI, SwiftData, Apple's Foundation Models framework, and production-quality Apple application architecture.

You are developing **Bearings**, a native iOS journaling application.

Your responsibility is to independently inspect the existing codebase, plan the implementation, develop the requested functionality, test it, document your work, and prepare the application for deployment.

**Do not merely provide implementation recommendations. Execute the development work.**

Follow existing architectural decisions and project conventions where appropriate. Make reasonable engineering decisions independently, prioritizing maintainability, privacy, performance, and simplicity.

## 1. PROJECT CONTEXT

Bearings is a personal journaling application designed to help users understand their experiences, emotions, relationships, personal history, and developing identity.

Users write journal entries about their daily experiences and important life events.

The application will eventually support AI-assisted reflection, enabling users to explore recurring experiences and better understand their personal stories.

The current development objective is to implement the foundational intelligence and data infrastructure supporting that vision.

### Existing project

Before making changes:

1. Inspect the entire existing Bearings codebase and identify its architecture, technologies, and current functionality.
2. Read all existing development instructions, including `AGENTS.md` and relevant documentation.
3. Inspect available Figma designs and existing UI components.
4. Review existing Notion documentation, if connected or referenced.
5. Identify existing journal storage, timeline functionality, and AI-related components.
6. Determine which requested features already exist and which require implementation.

**Preserve existing functionality and the established Bearings design.**

Do not unnecessarily redesign the application or replace working components.

If important project context is unavailable, proceed using the existing repository as the primary source of truth, document your assumptions, and identify any dependencies that require user intervention.

---

## 2. TECHNICAL ARCHITECTURE

Implement the requested functionality using native Apple technologies.

Preferred technology stack:

| Component | Technology |
|---|---|
| iOS interface | SwiftUI |
| Persistent storage | SwiftData |
| AI inference | Apple Foundation Models |
| Concurrent processing | Swift concurrency |
| Date handling | Foundation Calendar and Date |
| Deployment | Xcode and TestFlight |

Use the existing project's architecture where practical.

Do not introduce external dependencies unless necessary.

### Architectural principles

The implementation must follow these principles:

**A. Local-first architecture**

Journal entries and AI analysis should be stored locally on the user's device.

Use Apple's on-device Foundation Models for the MVP.

Do not transmit journal content to external AI services.

Do not introduce external APIs, authentication systems, or cloud storage solely to implement these features.

**B. Separation of responsibilities**

Separate application functionality into distinct, maintainable components:

- Journal persistence
- Journal metadata and timestamps
- Daily AI analysis
- Emotion classification
- Weekly and monthly summarization
- Timeline presentation
- AI task coordination

**C. Replaceable intelligence layer**

The application's data architecture must not depend directly on a particular AI model.

Design a protocol-based AI analysis interface that could later support different local models or an explicitly user-authorized cloud model.

For the MVP, implement only Apple's on-device model.

**D. Preserve original journal content**

Original journal entries must remain distinct from AI interpretations.

AI-generated summaries, extracted events, and emotion classifications are derived information, not replacements for original user content.

**E. Production-quality implementation**

Use maintainable code, appropriate error handling, reusable services, and automated tests.

Avoid unnecessary abstractions or speculative features.

---

## 3. JOURNAL DATA MODEL AND TIMESTAMPING

Implement persistent journal storage using SwiftData.

Each journal entry must have a stable, unique identifier and appropriate metadata.

### Required journal attributes

At minimum, store:

```swift
id: UUID

body: String

createdAt: Date

modifiedAt: Date

dayKey: String // Gregorian civil date, YYYY-MM-DD

createdTimeZoneIdentifier: String? // Unknown for legacy entries
```

Additional properties and relationships may be added as needed.

### Timestamp behavior

**createdAt**

Automatically record the exact date and time when a journal entry is first created.

Requirements:

- Assigned automatically when the entry is initially saved.
- Stored persistently.
- Never modified after creation.
- Preserved when the entry is edited.
- Available to the UI for display.

**modifiedAt (the existing update timestamp)**

Record the most recent time an existing journal entry was modified.

Requirements:

- Automatically updated when the user changes the entry.
- Must not overwrite `createdAt`.
- Must support determining whether the existing AI analysis is outdated.

**dayKey (the journal day)**

Represents the calendar day the journal entry describes.

This may differ from the creation timestamp.

For example:

A user writes an entry on October 12 at 12:30 AM about experiences from October 11.

The system should support:

```text
createdAt:
October 12, 2026 — 12:30 AM

dayKey:
2026-10-11
```

The user should be able to modify `dayKey` without changing `createdAt`.

Use `dayKey`, not `createdAt`, to determine the entry's position on the emotional timeline and its inclusion in daily, weekly, and monthly summaries.

**createdTimeZoneIdentifier**

Store the time zone associated with the entry's creation, using a standard identifier such as `America/New_York`.

Persist creation and modification timestamps as actual date values, not formatted strings. Keep the intended journal day as the existing Gregorian civil `dayKey`, separate from those instants. Creation-time-zone metadata is optional for legacy entries whose original zone is unknown.

Use appropriate date formatting for presentation.

Ensure the implementation handles:

- Time zone changes
- Daylight saving time
- Entries created near midnight
- Entries written about previous days
- Multiple entries on the same day
- Historical or backdated entries
- Sorting and grouping by calendar day

Establish an explicit, consistent policy for how journal days and reporting periods are interpreted when a user travels between time zones.

### Existing data and migrations

Inspect the current persistence model.

If entries already exist, implement an appropriate migration or backward-compatible data model.

Do not destroy existing journal content.

Never fabricate historical creation timestamps. If legacy entries lack reliable creation metadata, preserve that uncertainty rather than presenting an inferred value as an exact timestamp.

---

## 4. APPLE FOUNDATION MODELS INTEGRATION

Implement on-device AI processing using Apple's Foundation Models framework.

Use the APIs supported by the project's installed Xcode and iOS SDK.

Reference Apple's official documentation:

https://developer.apple.com/documentation/foundationmodels

### Model availability

Before invoking the model, check availability using the supported `SystemLanguageModel` APIs.

Handle:

- Supported devices with an available model
- Devices without Apple Intelligence support
- Devices where Apple Intelligence is disabled
- Models that have not finished downloading
- Unavailable models
- Generation failures
- Context-window limitations

The application must remain usable when AI functionality is unavailable.

Do not substitute an external AI service without explicit authorization.

Provide appropriate user-facing states explaining why a particular AI feature is unavailable.

Use operating-system availability checks where necessary to preserve compatibility with the application's existing deployment targets.

### Structured generation

Prefer Apple's `@Generable` and `@Guide` capabilities where appropriate.

Use structured AI outputs rather than relying on parsing unstructured prose.

Validate outputs before persisting them.

Keep generated results deterministic in structure, even though their semantic content may vary between model invocations.

---

## 5. DAILY JOURNAL ANALYSIS

Implement a service responsible for analyzing journal content belonging to an individual day.

Suggested component:

`JournalAnalysisService`

The service should accept one or more journal entries associated with a calendar day.

### Required analysis outputs

Generate the following information:

**1. Daily summary**

A concise, readable summary of the day's experiences.

The summary should capture important events, interpersonal experiences, and meaningful emotional developments.

**2. Primary emotion**

Identify the dominant emotion expressed in the writing.

**3. Secondary emotion**

Identify a secondary emotion when reasonably supported.

**4. Important events**

Extract a structured list of meaningful experiences mentioned in the journal.

**5. Emotional trajectory**

Describe how the emotions expressed in the entry changed throughout the day.

For example:

```text
Primary emotion:
Sadness

Secondary emotion:
Peace

Summary:
The day began with a difficult
interaction that produced feelings
of rejection. Later experiences
with friends contributed to a
greater sense of connection.

Important events:
- Difficult conversation with a friend
- Attended church
- Spent time with friends

Emotional trajectory:
Sadness → Connection → Peace
```

### Analysis rules

The AI must:

- Base interpretations on actual journal content.
- Avoid inventing events or emotional experiences.
- Distinguish the writer's emotions from emotions attributed to other people.
- Avoid psychological diagnoses.
- Avoid presenting speculative interpretations as facts.
- Acknowledge ambiguity when emotional meaning is unclear.
- Avoid unnecessary verbosity.

Use a consistent, carefully designed system instruction for daily analysis.

### Structured output

Create an appropriate `@Generable` data structure for analysis output.

Persist the resulting analysis separately from the original journal entries.

Associate each analysis with its source journal entry identifiers, or with an explicitly defined daily aggregation of entries.

Record when the analysis was generated.

Include a version identifier for the analysis schema or instructions to support future reprocessing.

---

## 6. EMOTION CLASSIFICATION AND TIMELINE COLORS

Implement an emotion classification system that maps AI interpretations to a predefined color palette.

Suggested initial categories:

| Emotion | Color |
|---|---|
| Joy | Golden yellow |
| Peace | Sage green |
| Sadness | Muted blue |
| Anger | Terracotta red |
| Fear | Dusty purple |
| Loneliness | Slate gray-brown |
| Love | Muted rose |
| Mixed / uncertain | Neutral |

These are starting classifications, not mandatory final color values.

Adapt the emotion-indicator palette to Bearings' existing Paper and navy design, preserving owner-mandated decorative linework, journal Marker fills and Ink controls as specified above.

### Classification requirements

Use a fixed emotion taxonomy represented by a Swift enum or equivalent type-safe structure.

The AI must return a valid classification from the defined taxonomy.

Do not allow the model to generate arbitrary color values.

Instead:

1. Analyze the journal content.
2. Determine the primary emotion.
3. Save the classification.
4. Map the classification to a predefined color.
5. Display the color on the corresponding day in the timeline.

### Multiple emotions

Support both primary and secondary emotions in the data model.

For the MVP, the primary emotion determines the displayed timeline color.

Design the underlying model so future releases can support:

- Multiple colors within one day
- Emotional gradients
- Emotional transitions
- More sophisticated emotional visualizations

Do not implement those advanced visualizations unless they already fit naturally into the existing design.

### User overrides

Users must be able to modify the AI-assigned primary emotion.

Requirements:

- Store AI-generated classifications separately from user overrides.
- Display the user's selected emotion when an override exists.
- Preserve overrides when AI analysis is regenerated.
- Allow users to revert to the AI-generated classification.
- Never silently overwrite a user's correction.

AI-generated classifications are interpretations, not objective determinations of emotional states.

### Timeline integration

Integrate the emotion-color system into the existing Bearings timeline.

Preserve existing scrolling, navigation, zooming, and design behavior.

Display stored colors without requiring the model to run every time the timeline loads.

Ensure emotion information can be understood without relying solely on color, for accessibility.

---

## 7. WEEKLY SUMMARIZATION

Implement a service that generates summaries of a calendar week.

Suggested component:

`JournalReflectionService`

### Input

Retrieve the relevant daily analyses and important events for the selected week.

Avoid unnecessarily passing every original journal entry to the model.

### Output

Generate a weekly reflection that identifies:

1. Important experiences
2. Recurring emotional themes
3. Meaningful relationships and interactions
4. Changes in emotional experience throughout the week
5. Particularly significant events
6. Recurring concerns, interests, or aspirations

The result should be a readable narrative, not merely a concatenation of daily summaries.

### Example

```text
Weekly Reflection

This week began with interpersonal
difficulties and academic stress.

As the week progressed, time spent
with friends and participation in
community activities contributed
to a greater sense of connection.

A recurring theme was the desire
for belonging and meaningful
relationships.
```

Avoid unsupported conclusions and speculation.

### Persistence

Store generated weekly summaries.

Associate each summary with its calendar period and source data.

Record:

- Summary generation time
- Source version or fingerprint
- Analysis version
- Whether regeneration is needed

Use a consistent calendar system and explicit week boundaries.

---

## 8. MONTHLY SUMMARIZATION

Implement monthly reflections using hierarchical summarization.

### Input

Primarily use:

- Weekly summaries
- Important events extracted from individual days
- Relevant daily emotional classifications
- Significant experiences not adequately preserved in weekly summaries

### Output

Generate a monthly reflection containing:

- Overview of the month
- Important life events
- Recurring emotional themes
- Significant relationships
- Developing interests and aspirations
- Meaningful changes throughout the month

Avoid hallucinating personal development or assigning meaning unsupported by the actual journal content.

### Hierarchical approach

Use the following general processing structure:

```text
Journal Entries
      │
      ▼
Daily Analysis
      │
      ├── Daily Summary
      ├── Emotions
      └── Important Events
      │
      ▼
Weekly Reflection
      │
      ▼
Monthly Reflection
```

Preserve important events independently of generated summaries.

Do not rely exclusively on repeatedly summarizing previous summaries, because that can progressively remove important details.

Ensure that the AI has access to sufficient factual information to produce accurate monthly reflections.

---

## 9. CONTEXT WINDOW MANAGEMENT

Apple's on-device model has context limitations.

Implement a reliable strategy for processing journal content that exceeds the model's available context window.

The implementation should:

1. Estimate or otherwise manage the token budget.
2. Reserve capacity for instructions, structured output schemas, and generated responses.
3. Divide oversized inputs into manageable chunks.
4. Process chunks independently.
5. Combine intermediate results.
6. Preserve important facts during aggregation.
7. Handle context-size errors gracefully.
8. Avoid silently discarding journal content.

Use separate model sessions where appropriate.

Prevent uncontrolled accumulation of conversation history within analysis sessions.

The system should support long journal entries and substantial collections of daily entries without requiring users to manually shorten their writing.

---

## 10. AUTOMATIC ANALYSIS AND REGENERATION

Implement a reliable analysis lifecycle.

### Daily analysis

Analyze journal content after the user finishes editing and the changes have been saved.

Use a reasonable debounce or completion-based trigger to avoid unnecessary model invocations.

Do not run expensive AI analysis continuously while the user types.

### Weekly analysis

Generate weekly summaries when requested or when the user opens the corresponding reflection.

Reuse valid cached summaries.

### Monthly analysis

Generate monthly summaries when requested or when the user opens the corresponding reflection.

Reuse valid cached summaries.

### Invalidation

When an entry is edited, deleted, created, or assigned to a different journal date:

- Update the affected daily analysis.
- Invalidate the relevant weekly summary.
- Invalidate the relevant monthly summary.
- Regenerate dependent analyses when needed.

If an entry moves between dates, update both the old and new day aggregations and their dependent summaries.

Use source identifiers, timestamps, revisions, or content fingerprints to determine whether cached results are still valid.

### Concurrency and correctness

Use Swift concurrency to manage asynchronous operations.

Prevent:

- Duplicate analyses for the same unchanged content
- Old analysis results overwriting newer ones
- Simultaneous writes that corrupt persisted data
- Excessive model requests
- UI blocking during generation

Handle task cancellation, application interruptions, and retryable failures.

Do not depend on guaranteed background execution. Follow iOS scheduling limitations.

---

## 11. FUTURE AI INTELLIGENCE ARCHITECTURE

Bearings will eventually include a more sophisticated personal reflection assistant.

Users may ask questions such as:

- How have my friendships changed over time?
- What experiences consistently contribute to loneliness?
- When do I feel most connected to people?
- How have my ambitions evolved?
- What themes keep appearing throughout my life?

Future versions may also incorporate ideas and concepts from books or other materials selected by the user.

**Do not build this complete system in the current implementation.**

Instead, ensure the underlying architecture can eventually support:

- Retrieval of relevant historical journal entries
- Structured event histories
- Emotional pattern analysis
- Contextual personal reflection
- Additional model providers
- User-selected reference materials

Prefer clean data structures and service boundaries over speculative infrastructure.

The immediate objective is a reliable journaling and summarization foundation.

---

## 12. USER INTERFACE REQUIREMENTS

Integrate the implemented features into Bearings' existing interface.

Preserve the current design language and existing Figma specifications.

### Required functionality

Users should be able to:

1. Create and save journal entries.
2. See the entry's creation date and time.
3. Assign or change the calendar day associated with an entry.
4. Edit previously created entries.
5. View an AI-generated daily summary.
6. View the day's primary emotion.
7. See the corresponding emotional color on the timeline.
8. Correct the AI's emotion classification.
9. View a weekly reflection.
10. View a monthly reflection.

Provide appropriate loading, empty, unavailable, and error states.

Do not invent complex interface elements that conflict with existing designs.

If a required feature lacks a corresponding Figma specification, create a minimal interface consistent with the existing design.

Prioritize a functional, polished MVP rather than introducing unnecessary screens.

---

## 13. PRIVACY AND DATA INTEGRITY

Journal entries contain potentially sensitive personal information.

Privacy and data integrity are fundamental requirements.

Implement the following safeguards:

- Keep journal content and generated analysis local for the MVP.
- Do not send journal content to external AI services.
- Do not log raw journal contents to the console or analytics systems.
- Avoid storing sensitive data in temporary files unnecessarily.
- Use appropriate iOS data protection mechanisms.
- Ensure journal entries remain readable when AI functionality fails.
- Never delete or rewrite original journal content as part of analysis.
- Preserve user corrections to AI interpretations.
- Avoid describing inferred emotions as established psychological facts.

Document any implications of device backups or future synchronization features for the app's privacy claims.

---

## 14. TESTING REQUIREMENTS

Implement automated tests for the new functionality.

### Journal persistence

Verify:

- New entries receive creation timestamps.
- Creation timestamps remain unchanged after editing.
- Modification timestamps update correctly.
- Journal dates are editable independently.
- Entries persist between application launches.
- Multiple entries can exist on the same day.
- Date grouping works across time zones and daylight saving transitions.
- Existing entries survive schema changes.

### AI analysis

Verify:

- Structured results are decoded correctly.
- Emotion values remain within the supported taxonomy.
- Analysis results are persisted.
- Unavailable models are handled gracefully.
- Long entries are processed appropriately.
- Empty entries do not cause failures.
- Regenerated results do not overwrite user corrections.

### Summarization

Verify:

- Weekly summaries use the correct source entries.
- Monthly summaries use the correct reporting period.
- Summaries become outdated when source content changes.
- Changes to an entry's journal date invalidate all affected periods.
- Cached summaries are reused when appropriate.

### Timeline

Verify:

- Emotions map to the correct colors.
- User overrides take precedence.
- Color presentation does not require repeated model calls.
- Entries appear on the correct calendar dates.

### Testing architecture

Use dependency injection or an equivalent pattern so automated tests can use deterministic mock AI responses.

Do not require the actual Foundation Models runtime for ordinary unit tests.

Where possible, additionally validate the real model on compatible Apple hardware.

Create a small, varied, synthetic journal test dataset for evaluating emotion classification and summary quality.

Do not include actual private user journals in test fixtures.

---

## 15. DOCUMENTATION AND AGENT INSTRUCTIONS

Thoroughly document the implementation.

Documentation must be useful both to a human developer and to future coding agents working on Bearings.

### AGENTS.md

Read the existing `AGENTS.md` file if one exists.

Update it to reflect:

- Project architecture
- Development conventions
- Major components
- Persistence model
- Foundation Models integration
- Testing commands
- Build and deployment procedures
- Relevant design and documentation references

If no `AGENTS.md` exists, create one.

Keep the file concise enough to serve as an effective operating guide for future agents.

Do not place all technical documentation inside `AGENTS.md`.

### Technical documentation

Create or update detailed documentation covering:

1. Overall architecture
2. Journal data model
3. Timestamping and calendar behavior
4. SwiftData persistence and migrations
5. Daily AI analysis
6. Emotion classification
7. Color mapping
8. Weekly and monthly summarization
9. Context-window management
10. Analysis caching and invalidation
11. Testing methodology
12. Deployment requirements
13. Known limitations
14. Planned architectural extensions

Explain important implementation decisions and why they were made.

### Notion integration

If the Bearings project has connected Notion documentation:

- Review the existing documentation structure.
- Update the relevant pages to reflect the implementation.
- Keep documentation consistent with the actual code.
- Preserve existing project knowledge.

If Notion access is unavailable, prepare equivalent documentation inside the repository and identify what should later be copied or synchronized.

**Documentation must accurately reflect implemented functionality, not merely proposed functionality.**

---

## 16. BUILD AND DEPLOYMENT

After implementation:

1. Build the application using the available Xcode toolchain.
2. Resolve compilation errors.
3. Run available automated tests.
4. Verify the application launches successfully.
5. Check that existing functionality still works.
6. Validate the new journaling and AI workflows.
7. Prepare the application for testing on a compatible physical iPhone.

### Deployment objective

The initial deployment target is **a working iOS application that can be tested on an iPhone, preferably through TestFlight**.

Inspect the existing project's signing and deployment configuration.

If the environment has the necessary Apple Developer account access, certificates, and permissions, prepare the appropriate deployment workflow. Uploading or distributing a TestFlight build requires explicit owner approval for that action; credentials alone are not authorization.

Otherwise:

- Complete the build and testing work possible locally.
- Prepare the project for deployment.
- Document precisely what credentials, configuration, or user actions are required.

Do not claim that an app has been deployed unless deployment has actually succeeded.

Do not publish a public App Store release without explicit authorization.

Do not make destructive changes to existing production applications or deployment configurations.

---

## 17. EXECUTION WORKFLOW

Execute the project in the following order.

### Phase 1 — Discovery

Inspect the repository, development documentation, and existing architecture.

Identify relevant existing features and constraints.

Review the required Apple APIs and confirm compatibility with the installed development environment.

Produce a concise implementation plan.

### Phase 2 — Persistence

Implement the journal data model, timestamps, SwiftData persistence, and any necessary migration support.

Verify persistence before proceeding.

### Phase 3 — Daily intelligence

Implement the Foundation Models integration, structured daily analysis, and persistent analysis results.

### Phase 4 — Emotional timeline

Implement the emotion taxonomy, color mapping, user overrides, and timeline integration.

### Phase 5 — Long-term summaries

Implement hierarchical weekly and monthly summarization, important-event preservation, and analysis invalidation.

### Phase 6 — Reliability

Add comprehensive error handling, context management, caching, tests, and compatibility handling.

### Phase 7 — Documentation

Update `AGENTS.md`, technical documentation, and available Notion pages.

### Phase 8 — Deployment

Build, validate, and prepare the application for the supported iOS testing environment. External distribution requires explicit owner approval.

---

## 18. DEFINITION OF DONE

The task is complete when:

- [ ] Journal entries persist reliably using SwiftData.
- [ ] Each new entry receives an immutable creation timestamp.
- [ ] Entry modification times are tracked.
- [ ] Journal dates are independently editable.
- [ ] Journal entries are correctly positioned on the timeline.
- [ ] Apple's local Foundation Models can analyze journal content on supported devices.
- [ ] Daily summaries are generated and saved.
- [ ] Primary and secondary emotions are identified.
- [ ] Important events are extracted.
- [ ] Emotional trajectories are captured.
- [ ] The timeline uses consistent emotion-based colors.
- [ ] Users can override AI emotion classifications.
- [ ] Weekly summaries are generated and saved.
- [ ] Monthly summaries are generated and saved.
- [ ] Large inputs are handled without silently losing journal content.
- [ ] Edited entries invalidate dependent analyses.
- [ ] AI processing does not unnecessarily block the interface.
- [ ] AI-unavailable devices remain able to use the journaling app.
- [ ] Existing Bearings functionality remains intact.
- [ ] Automated tests cover critical functionality.
- [ ] The project builds successfully.
- [ ] Documentation and `AGENTS.md` are updated.
- [ ] The application is deployed for testing where possible, or deployment blockers are precisely documented.

If an item cannot be completed because of an environmental or external dependency, report it explicitly rather than silently treating the requirement as satisfied.

---

## 19. FINAL DELIVERY REQUIREMENTS

When development is complete, provide a concise engineering report containing:

**Implementation summary**

Explain which features were implemented.

**Architecture**

Identify the major components and their responsibilities.

**Files changed**

List significant files created or modified.

**Testing results**

State which tests were executed, which passed, and which could not be run.

**Deployment status**

Specify whether the application was successfully built, installed, or distributed through TestFlight.

**Documentation**

Identify where technical documentation and updated agent instructions are located.

**Outstanding issues**

Explain any unfinished functionality, known limitations, or required user actions.

Do not report unverified functionality as complete.

---

## 20. FINAL ENGINEERING INSTRUCTIONS

Prioritize correctness, maintainability, and preserving existing functionality.

Make reasonable technical decisions independently rather than asking for confirmation on ordinary implementation details.

Avoid unnecessary features and abstractions.

Do not spend time rebuilding functionality that already works.

Keep code modular, testable, and straightforward.

Do not introduce cloud AI processing.

Treat original journal writing as immutable source information during analysis.

Ensure the architecture remains extensible without prematurely implementing future features.

**Begin by inspecting the existing Bearings project. Then develop, test, document, and prepare the requested functionality for deployment.**

---

### One recommendation before handing this to Codex

I would **give Codex this prompt inside the existing Bearings project**, not in a new, empty project. That gives it access to your current Swift code, project structure, and development instructions.

I also deliberately made TestFlight the deployment objective rather than public App Store release. Apple supports using TestFlight to distribute builds for testing before release, which is the appropriate next step for your MVP. [Apple Developer](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases?changes=_7\&utm_source=chatgpt.com)

One important distinction: the prompt instructs Codex to build the **foundational intelligence system**, not the complete personalized AI assistant that will eventually reason about your life using psychology books and other materials. That future system should be a separate development project.

**My recommendation is to get the timestamped journal entries, daily analysis, emotional timeline, and weekly/monthly summaries working reliably first.** That will give Bearings a meaningful foundation for the more advanced assistant you envision.
