# Bearings local AI implementation handoff

On October 11, 2026, the owner approved adapting the ReCollect specification for Bearings, publishing the handoff, and starting a new Codex project chat to begin implementation. The authoritative next-milestone task is `docs/BEARINGS_AI_IMPLEMENTATION.md`. `AGENTS.md` now permits this on-device AI scope; prior documentation describing AI as future work describes the earlier foundation. Update Product, Architecture, Decisions and Progress to reflect actual implementation as it proceeds.

The task preserves iOS 17 journaling, the existing bundle/store identity, civil `dayKey`, `body`/`modifiedAt` fields, isolated transactions, failed-save/retry tests, opening artwork and decorative linework. TestFlight upload/distribution and later implementation pushes still require explicit authorization.

## Handoff validation

Documentation-only change: checked all 20 numbered specification sections, 23 unchecked completion items, five balanced fenced examples, Bearings naming and repository-specific persistence constraints. `git diff --check` validates the documentation patch. No app code was changed for this handoff; Xcode builds, automated app tests, Foundation Models generation and deployment were not run or claimed. The implementation chat must record exactly what it executes in `docs/Testing.md`.

## Synchronization

Notion synchronization of this scope approval is pending. The implementation chat should synchronize the approved milestone and subsequent meaningful implementation milestones into the existing Bearings hierarchy, verify saved writes, and update `docs/NotionSync.md`. Do not mark the existing AI task complete before implementation and verification.
