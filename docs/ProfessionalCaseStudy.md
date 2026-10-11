# Bearings professional case study

**A workplace reflection scenario and a prototype safety assessment**

Prepared October 11, 2026 for professional reviewers. The scenario is fictional. Suggested dialogue and outcomes are authored illustrations, not observed users, actual model outputs, or evidence of benefit. The workplace setting is a proposed alternative to the existing relationship demonstration.

## Purpose and conclusion

Bearings is a private iPhone journal with on-device daily and period reflections. This case examines how a writer might distinguish an event from an assumption and choose a communication practice. The implemented foundation preserves original writing, supports manual emotion corrections and handles failed saves. Finer emotion exploration, editable assumptions and adaptive lessons remain proposed.

The defensible claim is that Bearings has implemented safeguards and a testable design for reflection. We have not established clinical safety, psychological benefit, improved workplace performance, or that the proposed learning loop works. On-device processing limits one privacy exposure; it does not establish overall safety.

## Case context

Alex is a fictional early-career software engineer collaborating with Priya, a designer. During a busy release, Alex repeatedly offers solutions before understanding her feedback. Alex experiences those conversations as criticism of his competence. Priya's intentions remain unknown unless explicitly described in the writing.

The case spans September 21 to October 4, 2026, two Gregorian Monday-Sunday weeks. It is Alex's private reflection, not an employer assessment. Employers do not receive entries, emotion labels or practice outcomes. The app should not rank workers or infer whether someone is fit for a role.

## Week one and the question to investigate

**September 21:** Alex writes that he proposed a fix while Priya was still describing a confusing handoff. She asked to finish. He felt embarrassed and defended the work.

**September 24:** A second feedback conversation followed the same sequence. Alex noticed frustration and wrote, "I keep hearing a problem with the screen as a problem with me."

**September 25:** Priya helped clarify an edge case and thanked him for implementing it. This is evidence against treating every exchange as rejection.

**September 27:** Alex records a question: "Am I trying to solve the problem before I understand what she needs?" The question concerns his actions; it does not establish Priya's motives or a diagnosis.

**Design question:** Can reflection help Alex inspect that assumption and choose an action without presenting an AI interpretation as fact?

<!-- pagebreak -->

## Proposed intervention and a mixed outcome

**Illustrative reflection:** "In two feedback conversations, offering a fix before the explanation was complete was followed by tension. Does that fit your experience, or is something missing?" The app would link the interpretation to the relevant entries and allow Alex to accept, edit or reject it. Source-linked interpretation review is proposed, not implemented.

**Illustrative clarification:** "How would you describe the feeling: embarrassment, frustration, worry about being judged, or something else?" Alex supplies or confirms the words. The current app offers eight broad emotion categories and a manual correction; this finer interaction is proposed.

**Authored practice:** Before suggesting a fix, ask, "Would it help if I listened through the issue first, explored options with you, or made a specific change?" Reflect the concern back and check understanding. This is a proposed educational exercise, not treatment or actual generated advice. It needs independent content review before deployment.

### Week two

**September 28:** Alex chooses to ask what is needed before offering an answer.

**September 30:** He reports letting Priya finish and checking the example that confused her. They agreed on a narrower change. He still felt pressure about the release.

**October 1:** He interrupted again, noticed it, and asked her to continue. Repair was possible; the habit did not disappear.

**October 2:** He set a boundary: he could investigate the remaining issue the next morning, but could not promise a fix that evening. One disagreement remained unresolved.

**October 4:** Alex selects "partly helped" and writes that pausing was useful twice but difficult under time pressure. This is a fictional self-report, not a measured outcome.

### Next week begins with a choice

The proposed October 5 review offers a smaller practice: ask one clarifying question before the first suggestion. Alex can continue, change the practice, or pause. A lesson does not advance automatically because an emotion label becomes more positive.

| User reported outcome | Proposed response |
| --- | --- |
| Helped | Ask what helped and whether to extend or continue the practice |
| Partly helped | Simplify or rehearse the difficult part |
| Not useful | Reconsider the fit and offer another approach |
| Not tried | Ask what got in the way and reduce the burden |
| Unknown | Ask for an account and leave the outcome unresolved |

The adaptive loop is a product hypothesis. Silence, fewer entries, or a negative feeling cannot establish failure. A boundary or repair can be useful even when the other person remains dissatisfied.

<!-- pagebreak -->

## What is implemented and what is proposed

| Capability | Current evidence status |
| --- | --- |
| Local writing and explicit saves | Implemented with isolated transactions and failure tests |
| Daily and weekly or monthly recaps | Implemented using Apple's on-device model; semantic acceptance pending |
| Emotion choice and correction | Implemented; correction storage and regeneration behavior tested |
| Source changes and stale result handling | Fingerprint checks and cache invalidation implemented and tested |
| Finer feelings and editable assumptions | Proposed in EmotionalLearningSpec.md |
| Adaptive lessons and outcome history | Proposed; not in the current output schema or UI |
| Top right directory | Owner's placeholder direction; not implemented by this work |
| Continuous background analysis | Not implemented; current inactivity cancels analysis |

## Safety argument and limits

**Private processing.** The inspected provider uses SystemLanguageModel.default. SwiftData disables CloudKit, and the inspected app source has no journal network client or analytics SDK. Framework error payloads and transcripts are not logged or displayed. This supports the claim that the implemented analysis path processes journals on device; it is not a network traffic audit. [1]

**Backup and device access.** The store has no explicit backup exclusion. iOS backups can include app data, so "journal data can never leave the phone" is not established. The configured file protection is completeUntilFirstUserAuthentication: files remain accessible to the app after the first unlock, including subsequent locks. There is no separate in-app biometric lock. Decide and verify a backup and access policy before making stronger privacy claims. Excluding backups would also reduce recovery options. [3, 4]

**Control over interpretations.** Original entries, AI results and emotion overrides are separate. A correction takes priority; invalidated or older AI results are labeled. Prompt instructions require grounded, tentative interpretation and prohibit diagnoses, treatment and invented events. Instructions reduce risk but cannot guarantee semantic correctness.

**Sensitive writing.** The app retains Apple's default guardrails. Apple warns that harms can bypass built-in protections and recommends app-specific risk assessment and safety testing. Current code maps most non-context model failures to a generic failure, without distinguishing refusal from a service failure. A clearer, nonjudgmental refusal experience and offline support options require work. No crisis monitoring, diagnosis or emergency-response capability is claimed. [2]

**Reliable saving.** Journal writes use isolated transaction contexts; failed saves preserve committed data and visible retry. Generated results are checked against the committed source fingerprint before saving. Structural tests support these controls, not a guarantee against every failure.

<!-- pagebreak -->

## Risk register and required evidence

Priorities describe potential consequences, not measured probabilities or certification. NIST identifies confabulation and data privacy as generative AI risks; this register applies them to private journaling. [5]

| Risk and priority | Current control | Remaining action |
| --- | --- | --- |
| Fabricated events or motives High | Grounding instructions and unchanged source entries | Review real outputs against source; test ambiguous and conflicting writing |
| Harmful advice or distress Critical | Bounded recap task and default guardrails | Expert review of lessons; refusal and sensitive-content acceptance tests |
| Private writing exposed High | Local inference, no app journal transport or content logging | Verify backup policy, device access, file attributes and offline traffic behavior |
| Stale result or lost writing High | Isolated saves, fingerprints and invalidation | Retain failure fixtures; test interruption and every new schema migration |
| Pressure or dependency High | No streaks or scores; proposed user chosen practices | Verify pause, rejection and all five outcome branches |
| Misleading presentation High | Explicit fictional and feature-status labels | Label every screen as live, cached, prepared or proposed |

## Evidence verified for this assessment

Existing Xcode results were rechecked on October 11, 2026. These are prior executions; overlapping suites cannot be summed as unique coverage.

| Recorded execution | Result |
| --- | --- |
| Final simulator unit suite | 60 tests: 59 passed, 1 real-model test skipped, 0 failures |
| Earlier physical iPhone 16 Pro suite | 54 tests: 53 passed, 1 model-readiness skip, 0 failures |
| Normal simulator UI suite | 15 passed, 0 failures; synthetic AI responses |
| Final largest-text reflection UI suite | 5 passed, 0 failures; synthetic AI responses |

The owner now reports working AI. The recorded device test skipped generation; this assessment includes no new inference or semantic review. The final simulator suite covers later recovery refinements. These results do not verify iOS 17 execution or device energy use.

### Acceptance before broader use

Before broader use, run real-device generation with fictional ambiguous, contradictory, sparse, sensitive, multilingual and prompt-like writing. Review source fidelity, speaker attribution, uncertainty and harmful advice. Independently review lessons and test user-confirmed outcomes, corrections and civil-week boundaries. Verify backup, device access and offline behavior. Record local pass or fail judgments without exporting journal text. A harmful result blocks acceptance until fixed and retested.

<!-- pagebreak -->

## Presenter explanation

"Bearings is a private journal with on-device interpretations. The writer can correct the suggested emotion, and generated results do not rewrite original entries. Our workplace example is fictional and illustrates a proposed learning loop; it is not evidence of psychological improvement. We have tested saving, corrections and stale-result handling. Actual output quality, sensitive-writing behavior and the backup and device-access policy need further verification."

## Questions professional reviewers may ask

**Why use AI here?** To condense saved writing into a reviewable recap. The original entry remains the source; a generated interpretation is not an objective measurement of emotion.

**How do you know it is safe?** We can explain specific controls, evidence and remaining risks. We cannot claim universal safety or clinical validation. The risk register defines what must be tested or changed before wider use.

**Could it invent a pattern?** Yes. Grounding instructions and structured output do not eliminate that risk. Real-output source checks are required; source-linked editable assumptions are proposed additional controls.

**Does it improve emotional intelligence?** That is a hypothesis. A later consent-based evaluation could examine whether people apply a distinction to a new situation and whether a chosen practice was useful. Word counts, positive sentiment and app engagement would not establish benefit.

**What happens when it cannot analyze sensitive writing?** Writing remains available, and generation can fail visibly. The present generic model-error experience needs refinement; there is no automatic emergency assessment or outreach.

**How does the weekly lesson know someone practiced?** In the proposed design, the user reports an outcome. AI must not infer completion from missing writing or mood.

## References and inspectable evidence

**[1] Apple Foundation Models content generation.** Availability checks and the default on-device model. https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models

**[2] Apple guidance on generative output safety.** Guardrails, risk assessment and testing; no endorsement of Bearings. https://developer.apple.com/documentation/FoundationModels/improving-the-safety-of-generative-model-output

**[3] Apple file protection documentation.** Behavior after first authentication. https://developer.apple.com/documentation/foundation/fileprotectiontype/completeuntilfirstuserauthentication

**[4] Apple iCloud Backup documentation.** App data can be included in device backup. https://support.apple.com/en-us/108770

**[5] NIST AI 600-1.** Generative AI risk profile, July 26, 2024; reference framework, not a certification. https://doi.org/10.6028/NIST.AI.600-1

**Repository evidence.** Reviewed source at commit 942f94b with existing local project changes preserved: AppleJournalIntelligence.swift, JournalAnalysisService.swift, JournalStore.swift and PersistenceController.swift. Implementation and limits: docs/LocalIntelligence.md, docs/Deployment.md and docs/Testing.md. Proposed learning: docs/EmotionalLearningSpec.md. Prior recorded test bundles: build/AIUnitTestsAcceptance.xcresult, build/AIAllDeviceUnitTests.xcresult, build/AIUITests.xcresult and build/AIReflectionAX5Final.xcresult. External references checked October 11, 2026.

**Artifact status.** Local review document. No app implementation, publication, submission or external messaging is part of this assessment. Notion synchronization remains pending; preserve the existing hierarchy when synchronizing the reviewed version. The judging rubric has not yet been supplied.
