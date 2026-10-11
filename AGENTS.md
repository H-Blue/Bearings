# Bearings

Native iPhone journal built with Swift, SwiftUI, and SwiftData. The user's story is the central experience: timeline → day → writing. Keep the MVP local, offline, private, and free of streaks, social features, analytics, external AI requests, subscriptions, and cloud infrastructure. The owner approved on-device AI summaries and emotional day indicators as the next milestone; implement `docs/BEARINGS_AI_IMPLEMENTATION.md` while preserving the journaling foundation and iOS 17 support.

## Engineering
- Target iOS 17 or later; use Apple frameworks without external dependencies.
- Organize `Bearings/` into App, Models, Persistence, Features, Design, and Services. Keep views small and keep persistence errors visible.
- Preserve the existing bundle identifier and SwiftData configuration/store path through the Bearings rename so saved journals remain available. The retained `ReCollect` storage identifiers are compatibility values, not the current brand.
- Calendar-day identity is a Gregorian civil date, stored separately from creation/modification timestamps. Preserve that identity across time-zone changes.
- Never log journal content. Explicitly save edits and handle failures; never silently replace a failed persistent store with temporary storage.
- Route writes through `JournalStore`'s isolated transaction contexts. Update visible models only after a successful save; keep drafts separate and exclude pending changes from authoritative reads. Preserve the real failed-save/retry tests.
- Preserve existing work, make focused changes, and record coherent local Git commits. Publishing, pushing, paid services, and irreversible changes require the owner's approval.
- Build with Xcode and run meaningful date/persistence and UI tests when possible. Record exactly what ran and what remains unverified in `docs/Testing.md`.

## Design
- The owner-selected right-curving river/ridge map is the full-screen opening artwork. Show Bearings and “Find what’s been lost inside.” at the safe-area top right in navy, for at least two uninterrupted active seconds on a fresh launch. Restart the opening wait if interrupted; do not replay it after completion on an ordinary background return. Initialize the journal after the opening, preserving visible store errors and retry behavior.
- Explicit owner decisions → approved Reconnect Figma → Bearings Notion → development brief → implementation judgment.
- The owner renamed the app and associated materials to Bearings and explicitly selected the supplied `appIcon.png` as its app icon. Preserve that artwork and root source; resize only to 1024 × 1024 for the app asset, without recoloring or redrawing. The original compass/topographic-map request specified `#C8AB89` / `#323575` as design targets; exact two-color enforcement is not claimed.
- The latest owner instruction sets decorative app linework to opaque `#323575`: timeline horizontal line/ticks, day branches, entry dividers and the editor rule. Use the shared `Line` color / `BearingsTheme.line`; preserve geometry, black Ink text/control tint, grey Marker fills and Paper.
- Preserve the tactile paper, dark blue, brass, and kerosene-yellow direction. Reference status is recorded in `docs/ReferenceReview.md`.
- Do not claim provisional UI matches approved Figma. Review actual screens before final styling and animation; escalate consequential design conflicts.
- Timeline/day navigation must preserve spatial context, work in reverse, and respect Reduce Motion. Use native text editing, safe areas, keyboard behavior, Dynamic Type, and accessible controls.

## Documentation and collaboration
- GitHub source repository: https://github.com/H-Blue/Bearings. The owner approved public repository setup; hackathon submission is explicitly excluded. Future publishing/pushing still requires authorization for the requested work.
- Notion project home: https://app.notion.com/p/3f5076d4a2e18039877ed1727adbcb42. Notion is the product/design source; this repository is the implemented-code source.
- Technical handoff: https://app.notion.com/p/3f5076d4a2e181619c8bff6109e7ba69. Synchronization evidence is in `docs/NotionSync.md`.
- Maintain architecture, decisions, scope, progress, and tests under `docs/`; synchronize meaningful milestones to the existing Bearings Notion hierarchy and verify writes. Record pending synchronization explicitly.
- Make routine reversible decisions autonomously. Explain consequential decisions plainly; identify real blockers and keep working on independent foundations.
- The approved AI milestone extends the existing local retrieval boundary for on-device daily analysis, weekly/monthly reflections, and user-correctable emotion indicators. No journal content leaves the device. Gate Foundation Models by SDK/OS/runtime availability and preserve isolated saves, Gregorian civil day identity, compatibility storage identifiers and owner-selected design. The broader personal assistant and progressive design reveal remain future scope.
- Update these instructions when actual architecture or workflow changes. Do not duplicate the full specification here.
