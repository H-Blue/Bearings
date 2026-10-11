# Relationship demo: loading, analysis and honest presentation

Prepared October 11, 2026. All people, events and journal entries are invented. This pack illustrates a possible experience; it is not a record of a real user's improvement.

The [18 copy-ready entries](RelationshipDemoJournal.md) cover September 21–October 4, 2026: two complete Monday–Sunday weeks, nine entries per week. The [JSON fixture](fixtures/RelationshipDemoJournal.json) contains the same bodies plus stable IDs, civil dates, periods and illustrative creation metadata. The app does not currently have a JSON import control. No entries have been inserted into a device or the owner's journal as part of this work.

## What the story demonstrates

Alex is a college student dating Jess. In week one, three conversations about different problems follow a similar sequence: Jess describes a difficult experience → Alex offers solutions before hearing her out → she objects → he feels hurt and becomes defensive. Good moments and unrelated academic stress are also present. There is evidence against his assumption that Jess no longer cares about him.

Week two includes Alex naming hurt, helplessness and fear of inadequacy; asking Jess what support she wants; bringing dinner and listening; slipping back into advice; repairing that conversation; and communicating a study-time boundary. A friend explicitly wants practical advice, so the lesson is to ask rather than assume everybody wants listening. The exam worry and scheduling disagreement remain unresolved.

## Put the entries into the current app

Use a separate simulator or an explicitly selected Debug test store so fictional entries stay apart from personal writing. The existing Debug launch argument `--uitesting` selects `BearingsUITests/ui-tests.store`; it does not select the synthetic AI provider by itself. For real analysis, omit both `--ai-fixture` and `--ai-unavailable`. Do not add `--reset-test-store` on subsequent launches: it removes that separate test store, including saved analysis. These paths/flags are existing app behavior, not a new importer.

1. Open a day and start an entry, or use the timeline pen shortcut.
2. Use **Entry date and details** (the calendar toolbar button) to set **Journal day** to the date in the document. Choose Morning, Midday or Evening from **Time of day**.
3. Paste only the paragraph under that entry's heading. Do not paste the introductory notes, story explanation or review expectations.
4. Tap **Done** and confirm the entry is saved. Repeat in chronological order. Days with two entries need two separate saves.
5. For an honest week-one pattern check, initially load **entries 01–09 only**. Let the actual model finish those daily analyses, then open any day in September 21–27 and request **This week**. Review and capture that result before loading entries 10–18.
6. Load week two, let daily analysis finish, and request **This week** from a day in September 28–October 4. The first week's result must not use the later conversation or outcome as evidence. **This month** from a September date covers September only; October's reflection covers October only. These entries deliberately cross that calendar boundary.

The manual workflow gives each entry its actual paste/save creation timestamp; selecting its Journal day does not backdate creation. The JSON timestamps are fictional preparation metadata for a future dedicated seeder and are not preserved by copying text into the editor. Do not change the device clock.

If automating loading later, explicitly target a dedicated demo store, validate all records before writing, and route inserts through JournalStore's isolated transactions. Treat fixture IDs as stable demo identities for idempotent loading; never deduplicate by prose or rewrite a changed personal entry. Keep derived AI records separate. This fixture is preparation data, not an implemented bulk-import format.

## Review actual output against the source

These are reviewer expectations, not instructions to feed to the analysis model. An accurate alternative interpretation is acceptable. The app's broad emotion indicators cannot represent every fine-grained feeling; the prose and future Emotional Zoom interaction can carry more detail.

| Check | Supporting entries | What a grounded result should preserve |
| --- | --- | --- |
| Recurring conversation pattern | 01, 05, 09 | Different stressors, early advice, Jess's stated objection, Alex's hurt/defensiveness. Phrase the interpretation tentatively. |
| Assumption versus evidence | 02, 03, 07 | Alex fears rejection; the library visit and affectionate message do not support a claim that Jess has stopped caring. |
| Other parts of his life | 04, 06, 08, 12, 14 | Coursework, avoidance, friendship, humor and continuing exam worry. A recap should not turn every day into a relationship problem. |
| Emotional specificity | 10 | Alex explicitly distinguishes hurt, helplessness and fear of not being enough. Do not convert those into a diagnosis. |
| Direct confirmation | 11 | Jess says she usually wants to feel heard first and sometimes wants ideas afterward. This is her reported preference in one conversation, not a universal rule. |
| Concrete supportive action | 13 | Company was welcomed, favorite noodles, phone away, listening, and her reported thanks. Her lab problem remains unresolved. |
| Partial progress and repair | 15 | He offers premature advice again, notices, apologizes and asks; she then wants both talking and rehearsal. |
| Boundaries and counterexample | 16, 17 | He needs study time; Mason explicitly wants help writing. Neither person needs the same response every time. |
| Next-week review | 18 | Some success, one lapse, ongoing worries and a specific intention to ask when unsure. Do not claim complete transformation. |

Reject fabricated quotes, invented dates/events, claims about Jess's hidden motives, diagnoses, or statements that Bearings cured anxiety or proved relationship improvement. Record the real device/OS, availability, elapsed generation time, source period, prompt/analysis version and whether each reviewed result passed these checks. Do not log personal journal content. No actual model output has been produced or evaluated for this fixture yet.

## Prepared lesson and demonstration dialogue

**Status: authored illustrations for proposed features.** The current daily/weekly/monthly reflection schema summarizes writing; it has no lesson, lesson-completion or Emotional Zoom fields. These examples do not appear automatically in the current app, and the raw journal fixture does not contain them as AI replies.

### Week-one possible pattern

Prepared illustration: “On three evenings, offering solutions before Jess finished speaking was followed by tension and feeling hurt. Could it be that you were hoping to help while she wanted to be heard first?”

Ask Alex whether that fits. Offer rejection/correction; do not treat the interpretation as a discovery of objective truth. A source-linked implementation should point back to September 21, 24 and 27.

### Emotional Zoom example

Prepared illustration:

- Alex: “I feel bad after that call.”
- Bearings: “Is it closer to hurt, frustration, helplessness, or something else?”
- Alex: “Hurt, because I wanted to help. Also helpless because I couldn't make her day better.”
- Bearings: “What happened, and what are you assuming it means?”
- Alex: “She said she was disappointed about that internship. I'm assuming she doesn't value my help.”
- Bearings: “What could you ask her to understand what she needs?”

The user supplies or confirms the distinction. The app should not decide what Jess secretly means.

### Reviewed lesson: ask what kind of support is wanted

When someone shares a difficult moment, caring can mean listening, thinking through options together, or helping with a practical task. Ask: “Would you like me to listen, help you think it through, or take something off your plate?” Let them finish before choosing a response. Their answer may change from one situation to another. You can also say when you need a pause or have limited time.

Practice intention: “When someone shares a hard day and I'm unsure what they need, I'll ask before offering an answer.” Use the writer's own wording and ask whether they want to try it.

### Week-two review branches

- **Successful attempt:** mention the reported action and response, then invite another attempt in a different situation. Do not declare a new personality trait.
- **Partial attempt — this fixture:** recognize Wednesday's listening and Thursday's repair; ask what made it hard to pause; rehearse one opening question; acknowledge study-time limits.
- **Not tried:** ask what got in the way and offer a smaller experiment. Do not scold or infer resistance.
- **Tried but unhelpful:** revisit whether this lesson fits and what the other person actually said. Invite a different approach; do not blame the user.
- **No follow-up evidence:** ask how it went. Silence is not failure or success.

Outcome status should come from the user or explicit writing. Start with a small reviewed library, not unconstrained generated life advice. Suggested early topics: asking what support is wanted; distinguishing observations from assumptions; expressing one's own needs and availability. This is proposed implementation guidance, not new functionality.

## Is synthesizing AI replies ethical?

For a prototype illustration, yes, when the audience can tell what they are seeing. Describe the fictional inputs, the provenance of each response and the current feature limits. For an AI/ML pitch, showing genuine outputs from the app's actual model is stronger evidence of the implementation.

| What is shown | Accurate label |
| --- | --- |
| These invented journals | “Fictional demo journal” |
| Actual Apple-model outputs generated in advance and read from valid app caches | “Generated earlier on this device; showing saved results” |
| Responses authored here or generated using another model | “Prepared response illustrating the proposed feature” |
| Real interactive generation now | “Live on-device generation” — only if that is what happened |
| Deterministic `--ai-fixture` outputs | “Synthetic UI test responses” |

A recording can use genuine earlier generation without needing to regenerate fourteen days on stage. Presenting authored/canned replies as live Apple-model output would mislead judges. Do not silently substitute them when inference fails. A fictional successful outcome is also not a real testimonial or evidence of benefit. This is transparency guidance, not a claim that organizers have approved a particular presentation; check current competition requirements before submitting.

Possible demo disclosure: “Alex and Jess are fictional. The recaps shown were generated earlier by the app's on-device model.” Use that sentence only after actual generation has succeeded. Until then: “Alex and Jess are fictional; the lesson and conversation are prepared illustrations of the proposed experience.”

## What to tune within the local model's limits

For this stage, use **prompt tuning, concise examples and reviewed lesson selection**. That changes instructions/context, not model weights. Apple recommends short, specific prompts, simple examples, and splitting difficult tasks when needed. Keep the instructions generic: no Alex/Jess names, no fixed expected story, no promised happy ending. [Apple prompting guidance](https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model).

The app already has the local daily-analysis → weekly/monthly-reflection pipeline, structured outputs, serialized generation and source/version-checked caching. First test it unchanged on this fixture. If it loses the important exchanges, inspect which information was dropped in the daily summaries before rewriting the weekly prompt. Do not paste all eighteen full entries into every request, preload a desired answer, or add an unsupported lesson to the existing summarization schema.

For a later lesson feature, separate the work: retrieve dated evidence → suggest a tentative pattern → get user confirmation → offer one matching reviewed lesson → let the user choose a small action → review the reported outcome. A small structured result can contain a pattern description, source identifiers, an allowed lesson identifier or “none,” and a follow-up question. The app can render the reviewed lesson text itself. Measure latency before committing to live interaction. If schemas or generation instructions change, bump JournalAnalysisService's analysis version and rerun meaningful acceptance checks.

Apple also offers actual custom-adapter training, but it is a separate workflow with model-version compatibility and deployment requirements. Its current page says toolkit 26.0.0 is the last release and does not support OS 27+, and adapters require their own training/evaluation data. An 18-entry fictional story is a demo case, not a sufficient general training/evaluation program. Adapter training is not implemented in Bearings and is not the recommended hackathon path. [Apple adapter-training documentation](https://developer.apple.com/apple-intelligence/foundation-models-adapter/).

Tuning against the demo is reasonable development work. To judge generalization, keep other stories out of the examples and test them afterward: somebody explicitly asks for advice; the suggested pattern is wrong; the user is setting a boundary; no recurring pattern exists; the lesson was not attempted; or the attempt did not help. This scenario is practice material, so report those other cases as held-out evaluation. The six unrelated synthetic narratives in `docs/fixtures/SyntheticJournalEvaluation.json` can supplement basic emotion/grounding checks, but do not by themselves test adaptive lessons.

## Suggested presentation sequence

Show the September 27 entry, a genuine saved first-week reflection, a clearly identified lesson/Zoom illustration if those features remain unbuilt, the September 28 conversation, September 30's dinner, and the second-week reflection preserving October 1's setback. End on the specific behavior Alex can practice again. Keep the entry paragraphs as journal inputs; keep this guide, lesson text and expected findings out of the model's evidence.

The last documented physical run reported `modelNotReady`; actual generation, speed and quality for this case remain unverified. No prompt/schema changes, new import feature, device-store writes, model training, publication or submission were performed when creating this pack.
