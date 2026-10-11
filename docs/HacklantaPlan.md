# Bearings: build, verify, present, submit, practice

Prepared October 11, 2026. This is the ordered execution plan for the owner's new emotional-learning direction. The plan and specifications are prepared; the new features below are not yet implemented. Existing daily/weekly/monthly reflections and broad emotion corrections remain the implemented foundation. See [EmotionalLearningSpec.md](EmotionalLearningSpec.md) for feature acceptance and demo stories, and [PitchResearch.md](PitchResearch.md) for evidence and claims.

## Focus and deadline

The core story is: write an experience → describe the feeling more precisely → inspect and correct an interpretation → choose a useful next action → review what happened next week. Demonstrate one complete story before expanding the feature set.

The official submission deadline is **October 11, 2026, 9:00 AM EDT**. The hacker guide requires a public **2–3 minute video**, **one main track**, at most **three side challenges**, and both **Devpost and the event Google Form**. Live judging is **3 minutes plus 2 minutes Q&A**. One team member submits both forms; obtain the Google Form from Discord announcements. Recommended targets are a 2:30 video and 2:45 pitch; those targets are planning choices, not rules. Sources: [Devpost](https://hacklanta.devpost.com/), [official hacker guide](https://aluminum-soprano-222.notion.site/Hacklanta-2026-Hacker-Guide-3b81ccc4ed5c80f4b717c0ccc4b5df54).

Freeze features at least 90 minutes before the submission deadline as a planning target. Reserve that time for recording, link checks, source preparation and form completion. If time is shorter, shrink the feature scope rather than losing submission preparation. The actual publication and final submission remain separate owner actions; this planning request does not submit anything.

## Ordered steps

### 01 — Finalize specs and two demo stories

Agree the working contract in EmotionalLearningSpec: finer feeling choices, editable assumptions with sources, a weekly lesson and explicit feedback. Prepare invented stories about hurt after a friend cancels and anger after an unfair team incident. Keep demo writing in a separate resettable store. Preserve the owner's journal and current working files.

**Done when:** every core interaction has an input, output, fallback and acceptance condition, and the fictional stories show a credible before/after change. Required scope is one excellent primary story; the second is a test case and optional demonstration.

### 02 — Verify real on-device AI early

Continue the existing “Integrate AI for basic daily summaries” task. The last documented physical model state was modelNotReady; generated-result UI tests use synthetic providers. Check current availability and obtain actual daily and weekly outputs from invented writing on an eligible ready iPhone, including offline generation. Review accuracy and latency. Continue curated lesson/UI/data work while the device prepares.

**Done when:** actual model output, offline behavior and limitations are recorded separately from fixture tests. Do not present fixture output as live AI. If readiness remains unavailable, clearly label prepared/fixture examples and narrow the claim; journaling and manual emotion learning should still work.

### 03 — Implement story data and editable assumptions

Keep original journal entries authoritative. Store refined feelings, tentative assumptions, source references/revisions, chosen actions and weekly reviews separately. Reuse the existing retrieval, isolated-save and source-fingerprint boundaries. Accept/Edit/Reject must survive relaunch and regeneration, and feed later interpretation. Record another person's motives as uncertain interpretations, never established facts.

**Done when:** an edited or rejected assumption stays corrected, source edits/moves invalidate affected interpretations, old stores migrate, and a failed save leaves a visible retry without damaging writing.

### 04 — Implement Emotional Zoom

Start with the person's own words. Offer a few precise feeling candidates, short definitions and one clarifying question. Permit mixed feelings, uncertainty, custom words and rejecting every suggestion. The cancelled-friend case should reach the person's confirmed statement: “I felt hurt when my friend cancelled yesterday.” Asking about future plans becomes a user-chosen next step.

**Done when:** the complete interaction works with a ready model and through a curated/manual fallback, persists the user's choice and preserves the current broad timeline palette.

### 05 — Implement a weekly lesson and follow-up

Retain the implemented weekly summary as context, then add one educational lesson from a small reviewed library. Begin with the two examples in the spec. At the first opening in a new Monday–Sunday civil week, review the prior selected practice using explicit user feedback: helped, partly helped, not useful, not tried, or unknown. Celebrate effort and learning; provide simpler practice or another approach without blaming the user. Missing writing does not mean failure.

**Done when:** success, partial progress, no benefit, not tried and missing-prior-week paths work; completed lesson history survives regeneration and relaunch. Keep weekly summaries and adaptive lessons as separate concepts and tasks.

### 06 — Implement help at difficult moments

Provide a small user-chosen menu: understand this feeling, pause/ground, revisit something that helped, or seek human support. When understanding is unclear, offer one concrete question, a simpler example, or a pause. Use reviewed educational/grounding content that also works without AI. AI may connect it to confirmed journal context.

**Done when:** each path is usable with sparse data and an unavailable model, the user can stop, and the app makes no diagnosis or promise of relief.

### 07 — Implement a minimal human-support handoff

Start with a user-selected trusted contact and a native message/call handoff. Review the recipient and exact text before sending. The default asks for a call without journal excerpts. If nobody is available, offer another chosen contact or campus/professional resources; TimelyCare access depends on eligibility. The expanded “message all friends” idea is preserved as a later explicit opt-in recipient-group option, not part of the core demo.

**Done when:** cancelling sends nothing; unsupported messaging, no-contact and no-response paths are honest; a sent request does not imply a guaranteed callback. Resource links open only when the user chooses them.

### 08 — Test, solidify and freeze

Run meaningful persistence/date tests and native UI workflows for the new data and interactions. Cover migration, genuine failed saves/retries, corrections/history through relaunch, stale/in-flight output, cancellation, week and clipped-month boundaries, separate demo data, accessibility and offline/manual use. Review actual model semantics and offline latency independently. Record results in Testing.md.

**Done when:** both fictional stories complete reliably on the intended demo device and the known limitations are explicit. Fix problems that interrupt the story first. Optional haptics and UI cleanup follow only if time remains, and must preserve the map opening, navy linework, centered timeline, native editing, reverse navigation and Reduce Motion. Do not revive older UI tasks that conflict with later owner decisions.

### 09 — Develop the story pitch and AI/ML explanation

Use one need statistic, one personal story and one technical explanation. Suggested sequence: unmet need → fictional cancelled-friend entry → refined feeling → inspect/correct the assumption → choose a conversation → next-week review. Explain local inference, structured output, source-linked interpretation, user correction and the difference between a suggestion and a fact. Use the saved Yale, granularity and employment sources accurately.

**Done when:** every demonstrated feature exists in the frozen build; every efficacy claim matches evidence; the script fits a 2:45 rehearsal. AI/ML remains the default main-track recommendation. A social-good narrative is possible, but choose one track and only qualifying side challenges. Local personal storage does not satisfy Zero Data's published wording.

### 10 — Record the demo video

Continue the existing Demo Video task. Record a public 2–3 minute video of the frozen story, including a brief explanation of how the AI/ML works. Use invented writing and actual behavior; distinguish live inference, saved genuine output and fixtures. Add readable captions and clear audio. Rehearse timing once before recording.

**Done when:** the final URL plays without sign-in, stays public during judging, fits the required length, and represents the same build as the pitch. Public upload is a concrete later publication step.

### 11 — Prepare and complete the submission

Continue the existing Submit Project task. Prepare title, problem/users, team, track/challenges, technologies, public source/README, run instructions or demo link, video, build instructions and any judge-specific requirements. Disclose anything built before the event; official rules permit properly disclosed general-purpose components but reject previously completed projects. Verify the public source contains the demonstrated implementation before claiming it does.

**Done when:** one designated team member has completed Devpost and the Google Form and verified both receipts before 9:00 AM EDT. Save the final URLs/confirmation. Publishing/pushing and submission need the owner's action or specific later authorization under the existing repository instructions; all draft material and link checks should be ready first. Do not add TestFlight as a prerequisite: the guide accepts clear run instructions.

### 12 — Practice the presentation and Q&A

Use the same frozen story and build. Do one technical walkthrough, one timed audience rehearsal and one interruption/model-unavailable rehearsal. A brief rehearsal supports video recording; final practice follows submission preparation. Prepare short answers about privacy, model choice, mistaken assumptions, source evidence, education versus treatment, empathy claims and current limits.

**Done when:** two consecutive runs fit the 3-minute pitch, the presenter can answer 2 minutes of questions, and the fallback demonstration is clear and honest.

## Priorities if time runs short

1. **Core:** working journaling/local AI foundation, Emotional Zoom, correctable source-linked interpretation, one lesson and explicit follow-up, one complete fictional demo.
2. **Next:** second lesson case, simple difficult-moment help, reviewed single-contact support handoff.
3. **Last:** haptics, visual cleanup, recipient-group messaging, broad curricula and deeper creativity features.

Do not defer the video, submission materials or a short timed rehearsal in order to add priority-three features. Keep the remaining ideas in the research/spec notes rather than expanding the last-minute build.

## Existing Notion tasks

- Integrate AI for basic daily summaries: implemented locally; real-model acceptance remains pending, so it stays In progress.
- Weekly Summaries: implemented locally; real-model acceptance remains pending. Adaptive weekly lessons are new work, not a claim that summaries are absent.
- Demo Video and Submit Project: reuse the existing items; avoid duplicates.
- UI Improvements: optional final polish. Centered timeline and map opening have recorded local implementation/testing; older red-tick/fade ideas must be reconciled with the later owner-approved design before any changes.

The existing task database remains the place to track completion. Planning documentation alone does not complete implementation, testing, video, submission or practice tasks.
