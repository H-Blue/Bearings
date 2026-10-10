# ReCollect

Native iPhone journal built with Swift, SwiftUI, and SwiftData. The user's story is the central experience: timeline → day → writing. Keep the MVP local, offline, private, and free of streaks, social features, analytics, AI requests, subscriptions, and cloud infrastructure.

## Engineering
- Target iOS 17 or later; use Apple frameworks without external dependencies.
- Organize `ReCollect/` into App, Models, Persistence, Features, Design, and Services. Keep views small and keep persistence errors visible.
- Calendar-day identity is a Gregorian civil date, stored separately from creation/modification timestamps. Preserve that identity across time-zone changes.
- Never log journal content. Explicitly save edits and handle failures; never silently replace a failed persistent store with temporary storage.
- Route writes through `JournalStore`'s isolated transaction contexts. Update visible models only after a successful save; keep drafts separate and exclude pending changes from authoritative reads. Preserve the real failed-save/retry tests.
- Preserve existing work, make focused changes, and record coherent local Git commits. Publishing, pushing, paid services, and irreversible changes require the owner's approval.
- Build with Xcode and run meaningful date/persistence and UI tests when possible. Record exactly what ran and what remains unverified in `docs/Testing.md`.

## Design
- Explicit owner decisions → approved Reconnect Figma → ReCollect Notion → development brief → implementation judgment.
- Preserve the tactile paper, dark blue, brass, and kerosene-yellow direction. Reference status is recorded in `docs/ReferenceReview.md`.
- Do not claim provisional UI matches approved Figma. Review actual screens before final styling and animation; escalate consequential design conflicts.
- Timeline/day navigation must preserve spatial context, work in reverse, and respect Reduce Motion. Use native text editing, safe areas, keyboard behavior, Dynamic Type, and accessible controls.

## Documentation and collaboration
- Notion project home: https://app.notion.com/p/3f5076d4a2e18039877ed1727adbcb42. Notion is the product/design source; this repository is the implemented-code source.
- Technical handoff: https://app.notion.com/p/3f5076d4a2e181619c8bff6109e7ba69. Synchronization evidence is in `docs/NotionSync.md`.
- Maintain architecture, decisions, scope, progress, and tests under `docs/`; synchronize meaningful milestones to the existing ReCollect Notion hierarchy and verify writes. Record pending synchronization explicitly.
- Make routine reversible decisions autonomously. Explain consequential decisions plainly; identify real blockers and keep working on independent foundations.
- Future AI has an explicit local retrieval boundary only; no journal content leaves the device without user authorization. Progressive design reveal remains future scope.
- Update these instructions when actual architecture or workflow changes. Do not duplicate the full specification here.
