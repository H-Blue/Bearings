# Bearings development progress

Milestones: native journaling foundation, owner-directed Bearings rename/app icon, and blue app linework, October 10, 2026.

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
- Native Dynamic Type with scalable date cells and entry markers, vertical timeline scrolling, readable period labels, a keyboard/save footer, and compact metadata at the largest text sizes.

## Reference and owner decisions

All supplied Bearings Notion sources were reviewed, along with metadata, design context and screenshots for the three Reconnect Figma frames. The owner clarified the circles and approved the system font. Figma paper/ink/marker colors and the editor's oval/rule geometry are retained. The subsequent owner instruction changes decorative strokes to opaque `#323575`, as recorded below. The graphs are dynamic SwiftUI drawings; date labels, controls and entry lists are necessary functional adaptations of the preliminary prototype.

## Verification

Debug compilation and all 24 data/editor tests passed, including repeated real read-only write failures. Eight core UI workflow tests passed. Focused final checks passed for normal/Reduce Motion navigation, keyboard use, accessibility-extra-large and maximum-size writing/period assignment, maximum-size date selection, normal month navigation, and four-entry marker/persistence behavior at normal and maximum text sizes. Screenshots show complete metadata, writing, dates and remaining-count markers. The final unsigned device Release build passed. Native-frame review verified reverse layering without the observed blank frame. The final app was launched using its normal journal store in the iPhone 18 Pro simulator; a preview is saved locally as `docs/evidence/Bearings-Preview.png`. Existing screenshots, test logs and captured manifests remain historical evidence from before the rename. See `Testing.md` for exact evidence and device-level limits.

## Documentation synchronization

The original foundation product, architecture, references, decisions, tests and progress were synchronized to [iOS Development](https://app.notion.com/p/3f5076d4a2e181619c8bff6109e7ba69?pvs=204) under the existing Bearings Notion home. Saved content and parent hierarchy were fetched and verified; all six sections matched the final local documentation after native formatting normalization. No external GitHub repository has been created or pushed.

## Bearings rename and app icon

The owner explicitly renamed ReCollect to **Bearings** and requested the compass/map app icon. Current app branding, Xcode project/scheme/target names, source folders and brand-specific types, repository documentation, and the local development brief use Bearings. Existing bundle identity and the SwiftData `ReCollect` configuration / `ReCollect/Journal.store` location are retained to preserve saved writing. Historical evidence and source reference names remain intact.

The owner supplied and explicitly accepted `appIcon.png` for the app icon. Its artwork is preserved without recoloring or redrawing and resized only to 1024 × 1024 at `Bearings/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`; the root source remains untouched. The original flush-background, circular-compass and simplified-topographic-map request specified `#C8AB89` / `#323575` as design targets. Exact two-color enforcement is not claimed for the accepted image. The supplied-icon decision retained the approved paper/ink/marker palette; the subsequent blue-linework instruction is recorded below.

The renamed app passed all 24 data/editor tests, two focused UI tests covering saved edits/relaunch and Reduce Motion navigation, and an unsigned generic iOS Release build. The simulator Home Screen shows Bearings with the accepted compass icon. The local branch is now `codex/bearings-foundation`; original signing configuration and journal identities are preserved. Exact checks and limits are recorded in `docs/Testing.md`.

The Bearings milestone's complete product, architecture, references, decisions, tests and progress were synchronized to [iOS Development](https://app.notion.com/p/3f5076d4a2e181619c8bff6109e7ba69) under the existing Bearings Notion home on October 10, 2026. The saved six-document content and parent hierarchy were fetched and verified; `docs/NotionSync.md` records the final source hashes.

## Blue app linework

The latest owner request changes decorative app line colors to opaque `#323575`. A shared `Line` colorset and `BearingsTheme.line` apply to the timeline horizontal line/ticks, day branches and entry dividers; the editor rule SVG uses the same blue stroke. Existing geometry is preserved. Text/control tint stays black Ink, period and entry marker fills stay grey, and Paper remains unchanged. The historical Figma black linework is retained in the original reference files.

Debug simulator compilation and two existing UI tests passed with zero failures. Timeline, day and editor screenshots were reviewed and show the navy linework. Source audit confirms the opaque sRGB token and complete coverage of custom line primitives. Exact checks and remaining verification limits are recorded in `docs/Testing.md`.

This linework milestone was synchronized to [iOS Development](https://app.notion.com/p/3f5076d4a2e181619c8bff6109e7ba69) under the existing Bearings home on October 10, 2026. The complete six-document saved snapshot and parent hierarchy were fetched and verified; `docs/NotionSync.md` records the final source hashes.

## Next work and boundaries

The native journaling foundation is ready for simulator review. Owner/device review of animation feel and real iPhone behavior follows. AI, cloud sync, export/backup, progressive reveal, subscriptions, analytics, social features and gamification are outside this milestone.
