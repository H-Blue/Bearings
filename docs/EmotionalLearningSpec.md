# Bearings emotional learning: feature contract and demo stories

Prepared October 11, 2026 from the owner's feature direction. Most of this document remains a proposed implementation contract. The first Emotional Zoom clarity slice is implemented: a user-triggered editor control identifies one exact vague excerpt when present, explains the ambiguity tentatively and asks one probing question. Feeling candidates, confirmed finer words and persisted accept/edit/reject choices remain future work. Read LocalIntelligence.md and Deployment.md before extending the model boundary.

## Product loop

Write → name feelings → inspect assumptions → choose one practice → review what helped. The writer is the authority on their own experience. AI offers tentative interpretations and educational prompts. Lessons encourage learning without streaks, scores, pressure or claims that feelings are wrong.

### Emotional Zoom

Implemented first slice: the current draft can be reviewed on demand without being treated as committed journal data. A navy eyeglasses button below Done and above the editor rule sends the visible draft only to the on-device provider. The transient response appears below the writing, must ground any highlighted phrase as an exact excerpt, and asks one open-ended question. Editing clears the result. Nothing is written back to the journal or stored as a confirmed interpretation.

Input is saved writing and the user's initial description. Output includes a small set of feeling candidates, a short reviewed distinction, a clarifying question, user-confirmed finer words and an optional contextual sentence. Examples can include hurt, disappointed, lonely, frustrated, anxious, relieved, proud or grateful. Permit multiple/custom/uncertain choices. Do not force every experience into a single label.

Start with “How would you describe it?” before suggesting labels. Use “Could this fit?” rather than declaring what the writer feels. Separate the observed event, the writer's feeling, an interpretation of that event and a possible next step. “My friend cancelled” does not establish “My friend does not care.”

The current eight broad emotions and their accessible timeline palette can remain. Finer words belong in separate confirmed interpretation data; a longer vocabulary alone is not an emotional-intelligence score.

Acceptance: choosing, editing, rejecting or being uncertain is supported; choices persist independently from original writing; failure shows retry; manual/curated use survives model unavailability. New generation instructions/output require an analysis-version bump and compatibility handling.

### Evidence and editable assumptions

Every personal pattern/assumption should be traceable to saved entry IDs and revisions. Present the relevant excerpt only on-device, with the source day available to inspect. Accept/Edit/Reject is explicit; store whether a statement is model-suggested or user-confirmed. Rejected assumptions must not return as accepted facts during regeneration. The user's correction must influence later summaries/lessons.

Do not infer another person's intentions as fact, diagnose the writer, or claim a causal pattern from a few entries. With inadequate evidence, say there is not enough information and offer a question. An emotion can be accepted while a guessed cause is rejected.

Acceptance: corrections survive relaunch/regeneration; a journal edit, move or deletion invalidates affected interpretations; stale output cannot overwrite current data. Never rewrite an original entry as a side effect of a correction.

### Weekly lessons and outcome review

Use a small reviewed lesson library with stable lesson IDs/versions. AI selects or connects a lesson to confirmed context; it does not invent clinical advice. At the first opening in a new Gregorian Monday–Sunday week, present a prior-week review and a short new/continued lesson. This avoids requiring a guaranteed background scheduler or adding notification infrastructure.

Store one chosen practice and an explicit outcome: helped, partly helped, not useful, not tried, or unknown. Ask what happened rather than inferring success from tone or missing writing. If the writer reports success, acknowledge their effort and ask what made it work. With partial progress, simplify the practice. With no benefit, offer another reviewed approach or human support. Not tried is an opportunity to reduce the burden; unknown stays unknown.

Keep completed lesson history even when context changes; recompute recommendations without rewriting what the person actually practiced. Weeks have fixed civil identity; retain existing month-clipped reflection inputs. Sparse/no-prior-week cases offer a generic lesson and optional goal. Celebrate insight, boundary-setting or asking for help, even if another person does not respond as hoped.

Acceptance: all five outcomes, first week, sparse input, edits, relaunch and week/month/time-zone boundaries work; there is no invented improvement or repeated pressure to complete a lesson.

### Difficult moments and unclear understanding

Show four options: clarify, pause/ground, revisit something that helped, or reach out. Keep reviewed exercises accessible offline without the model. Personalization should use confirmed context and be optional. Helpful questions include “What happened just before this?”, “What were you hoping for?” and “Which part of that suggestion does not fit?”

If a lesson has not landed, provide a simpler example, one smaller practice, a choice of another explanation, or a break. Re-engaging with the moment should mean noticing the present or voluntarily revisiting a helpful memory; do not require reliving a painful event. No diagnosis, guaranteed calming result or emergency prediction from sentiment.

### Human-support access

The first version is user-initiated selection of one contact followed by a native call/message handoff. Suggested text: “I'm having a difficult moment. Could you call me when you're free? I'd appreciate someone to listen.” Show the exact recipient/text before the user chooses Send. Do not attach journal passages or AI assumptions automatically.

If no contact is available, offer another selected person, campus counseling/resource links, or a professional-service link. TimelyCare is an example for eligible members of partner institutions, not universal access. See PitchResearch.md for the verified official support page. External resource opening and messaging are deliberate user actions; local journal inference remains private/offline.

The owner's “message all friends” idea is retained as a later explicitly selected recipient group with exact-message review. It adds disclosure and messaging scope and should follow the core demo. Do not turn uncertain AI sentiment into automatic mass outreach. A native composer's sent status is a sent request, not proof of receipt, availability or a callback.

Acceptance: cancellation sends nothing, missing contacts/unsupported messaging have a fallback, a network outage does not damage local writing, and no private material is shared without the writer selecting it.

## Story data contract

“Story data” means both production provenance and safe demo fixtures; it does not mean building a cloud social graph.

The following concepts guide schema design; names are provisional, not a directive to replace existing types:

- Original JournalEntry: existing ID, body, civil day, period and creation/modification metadata.
- Feeling selection: source references, original description, finer user-confirmed words, uncertainty and optional context. Preserve the broad EmotionOverride compatibility behavior.
- Assumption/interpretation: statement, referenced entries/revisions, origin, acceptance state and user-edited replacement.
- Chosen practice: reviewed lesson/version, intended action, week and explicit user choice.
- Weekly review: prior practice, self-reported outcome, optional explanation and next chosen practice.
- Derived result metadata: generation/version/source fingerprint and stale state, using existing transaction/cache boundaries.

All production writes use JournalStore isolated contexts and explicit saves. Additive migration/defaults preserve older stores. New derived data stays separate from original writing. Do not log journal text, infer historical values, remove existing protection, or add external models, analytics or cloud infrastructure. Refresh membership through the existing Scripts/generate_project.py after adding Swift files.

Demo fixtures use invented content in an isolated Debug/demo store with a reset path, stable IDs and fixed Gregorian civil dates. Label the story fictional. Label deterministic fixture output separately from genuine saved/live model output. Resetting demo data must never clear the owner's normal journal. Validate fixture reset, dates, correction persistence and first-week/next-week lesson states.

## Demo case A: hurt after cancelled plans

1. **Initial entry, October 3:** “I feel bad. Sam cancelled our plans yesterday. I had been looking forward to seeing them all week.”
2. **Zoom:** offer hurt, disappointment and loneliness as candidates. Ask whether the hardest part was missing connection, an unmet expectation, or uncertainty about the friendship. The writer chooses hurt/disappointment and confirms: “I felt hurt when Sam cancelled because seeing them mattered to me.”
3. **Editable assumption:** tentative suggestion: “You may have taken the cancellation as a sign that Sam did not want to see you.” The writer rejects that motive and edits: “I don't know why they cancelled. I need clearer plans.” Show the original entry as evidence, and retain the correction.
4. **Lesson/practice for the week beginning October 5:** separate event, feeling and interpretation; choose a clear, non-accusing request. Draft: “I was disappointed when our plans changed. I'd still like to meet. Could we choose a time that works, and let each other know early if something changes?” The writer decides whether to use it.
5. **Outcome entry, October 9:** “I asked Sam about a time that works. They explained their schedule and we picked Saturday. I felt relieved. I was glad I asked rather than guessing.” This is a fictional reported outcome, not something the AI invents.
6. **Review at first opening in the week beginning October 12:** the writer selects helped. Acknowledge that they named the feeling and asked clearly. Offer a short practice on expressing appreciation or keeping a realistic plan. A “Next demo week” control is explicitly simulated; it must not alter the real phone clock or normal journal.

Alternative review branches: partly helped → refine the request; not useful → try a different reviewed approach or support; not tried → rehearse one sentence; unknown → ask and leave it unresolved. Success can include stating a boundary even if Sam remains unavailable.

## Demo case B: anger after unfair treatment

1. **Initial entry, October 4:** “I'm angry. My teammate presented our work and didn't mention my contribution. I wanted to send a harsh message.”
2. **Zoom:** explore anger, hurt, frustration or feeling overlooked. The writer chooses anger/hurt; the event is missing acknowledgment, while deliberate intent remains unknown.
3. **Lesson/practice:** notice the feeling, pause before acting, describe the observable event and choose a proportionate request. Example: “When the work was presented, my contribution wasn't mentioned. Could we add that and agree how to credit each other next time?” Avoid a forced demand to forgive or suppress anger.
4. **Outcome:** the writer can report that the conversation helped, partly helped, did not help or was not attempted. The following week's lesson uses that report. Acknowledge constructive action rather than awarding a success score.
5. **Perspective exercise, optional:** “What explanations are possible? What evidence do you have? What could you ask?” This is curiosity practice; AI does not know the teammate's inner state.

## Meaningful verification before the pitch

- Old-store migration and actual repeated save failures/retry; existing tests stay intact.
- Confirmed feelings/assumptions/lesson histories survive relaunch and regeneration.
- Source changes, queued/in-flight cancellation and stale-output rejection.
- Monday–Sunday identity, boundary-crossing weeks/month clipping and time-zone travel.
- Mixed/uncertain/manual feelings, sparse context, unsupported locale/device and unavailable model.
- Separate demo data/reset; cancellation of message composer; no automatic disclosure.
- Native UI with keyboard, large text, accessible names and Reduce Motion.
- Actual ready-device inference reviewed for semantic fit, offline behavior and latency, recorded separately from deterministic UI tests.

Empathy, creativity and improved emotional intelligence are hypotheses to evaluate, not measured benefits of this prototype. A future evaluation could ask whether users can explain distinctions in a new situation and whether a chosen practice helped; counting emotion words alone is insufficient.
