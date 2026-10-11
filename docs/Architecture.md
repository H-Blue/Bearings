# Bearings architecture

Status: reconciled with implemented source on October 11, 2026. Build, test and visual verification results are maintained separately in `docs/Testing.md` and `docs/Progress.md`.

## Platform and organization

Bearings uses Swift, SwiftUI, SwiftData, and native Apple frameworks, with iOS 17 as the minimum version because SwiftData is available from that release. No third-party runtime dependencies are needed.

| Folder | Responsibility |
| --- | --- |
| `Bearings/App` | Application launch, dependency creation, root view, persistent-store recovery. |
| `Bearings/Models` | Journal entries, explicit journal periods, and calendar-day identity. |
| `Bearings/Persistence` | Dedicated SwiftData container and one store responsible for reads and mutations. |
| `Bearings/Features` | Timeline, day view, journal editor, and navigation state. |
| `Bearings/Design` | Shared palette, typography, reusable drawing, and interface components. |
| `Bearings/Services` | Local read-only entry snapshots for possible future integrations. |

SwiftUI owns transient screen state. The journal store owns persistent mutations. Keep view drafts separate from managed entries so an unsuccessful save cannot erase the user's current writing.

## Opening sequence

`AppEntryView` owns process-session presentation state. It first shows `OpeningScreenView`, then creates `StoreBootstrapView` after the opening completes. This keeps synchronous store initialization outside the opening interval and preserves the existing loading/error/retry path. Store retries do not replay the opening.

`OpeningScreenView` uses the bundled `OpeningMap` imageset, an edge-to-edge aspect-fill image, and native Dynamic Type text aligned to the safe-area top right. Its scene-phase keyed task waits two seconds only while active. An interruption cancels the task; the next active period starts a full new wait. After completion, ordinary background/foreground transitions retain the journal view. No animated dismissal is added, so Reduce Motion requires no alternate opening animation. Persistence and bundle/store identities are unchanged.

## Data model

| Concept | Meaning |
| --- | --- |
| Entry UUID | Stable unique identity, independent of text or calendar date. |
| `dayKey` | Zero-padded Gregorian civil date, `YYYY-MM-DD`; the user's intended journal day. |
| `periodRawValue` / `period` | Persisted raw string with typed `JournalPeriod` access; morning, midday or evening matching the approved circles. Unknown raw values read as midday. |
| Body | The user's writing, retained verbatim. |
| Created timestamp | Actual instant the persisted entry was created. |
| Modified timestamp | Timestamp of the most recent saved change; updates use the greater of the current time and prior timestamp so clock changes cannot move it backward. |

`JournalDay` separates civil dates from absolute timestamps. Conversion into a chosen calendar date uses the relevant local time zone, but stored day identity does not shift when the device time zone changes. Dates must be validated rather than relying on a timestamp at midnight; noon is used for ordinary calendar conversion to reduce daylight-saving boundary issues.

`JournalMonth` holds the year and month being browsed and enumerates Gregorian civil days directly, including civil dates that a time zone may have skipped. Its display date and date labels use UTC to preserve the components while the device travels. Month arithmetic is bounded to years 1–9999 and does not reinterpret local midnight timestamps.

`JournalPeriod` expresses the approved meanings in code. Morning, midday and evening come from the selected branch or the editor menu. Write suggests a period using the current local hour (before 12 morning, before 17 midday, otherwise evening), but the resulting selection is user-editable and persisted; it is not recalculated from the entry's creation timestamp.

## Persistence and saving

The SwiftData container uses a dedicated store in the application's Application Support directory. The Bearings rename preserves the existing bundle identifier, SwiftData configuration name `ReCollect`, and `ReCollect/Journal.store` path so existing installations continue to open their saved journal. Public app/project/scheme/target names and brand-specific Swift types use Bearings; storage identifiers remain compatibility values. CloudKit is disabled. The directory, main store, and existing SQLite companion files use iOS `completeUntilFirstUserAuthentication` protection. This allows normal use after the first device unlock while retaining the operating system's data-at-rest protection.

Application launch does not fall back to an in-memory store after a disk-store failure. Instead it presents the failure and a retry path. A root query fetch error also displays an explicit loading error with retry instead of appearing as an empty journal. In-memory configuration is reserved for isolated tests.

`JournalStore` retains the container's observed context for reading, but creates a fresh `ModelContext` from the same container for **every create, update and delete transaction**. Autosave is disabled in both contexts. Updates and deletions resolve the entry by its stable UUID in the transaction context, then call `processPendingChanges()` and explicitly save. Successful edits mirror the confirmed body, period and modification timestamp into the original model held by the editor; failed saves never mirror those changes.

On a transaction save failure, the store rolls back that isolated context and lets the failed transaction be discarded while `JournalEditorSession` retains its independent draft. There is no native undo manager in this implementation. The store increments its revision only after successful commits. This isolation was chosen because failure fixtures exposed registered-model/cache behavior that rollback in the interface's shared context did not reliably restore.

`JournalStore.entries(for:)`, `daysWithEntries()` and `snapshots(from:through:)` fetch with `includePendingChanges = false`. `BearingsRootView` initializes its `@Query` with an ascending creation-time descriptor that also excludes pending changes, then passes date-filtered committed entries to the day and timeline views. A missing UUID during update or deletion throws `JournalStoreError.entryNotFound` instead of creating a replacement entry.

The editor requests saving 350 milliseconds after the most recent body or period edit using a cancellable SwiftUI task. Done, a transition out of the active scene, and editor disappearance also request saving. `JournalEditorSession.SaveState` is empty, unsaved, saving, saved or failed. Done only dismisses after a successful save, and interactive dismissal is disabled while edits remain unsaved. A visible retry action retains the draft when saving fails. A new empty or whitespace-only draft is not inserted. An existing entry can be edited to an empty body; deletion remains a separate deliberate operation.

Deletion requires confirmation. A successful deletion puts the session in a terminal deleted state so a pending autosave or disappearance callback cannot recreate the entry. A failed deletion is tracked separately from a failed edit save, and Try again retries deletion rather than substituting a save.

## Navigation and drawing

Navigation stores the selected civil day and explicit period independently of the editor's text. The timeline remains mounted while a day is open, preserving its browsed month and horizontal position. Day cells start with a 44-point width and 235-point height at standard text size for months with at most two entries per day; caption scaling and additional marker content expand the available space. A major tick appears every seventh calendar day starting at day 1. Saved entries appear as up to three stacked dots plus a remaining-count label. A small navy fountain-pen button opens today’s journal; previous/next month and a native graphical date picker provide basic date navigation.

The timeline uses the user's native Dynamic Type preference. `@ScaledMetric(relativeTo: .caption)` supplies additional date-caption space for the cell width and cell height. Native monospaced-digit caption labels retain their single-line intrinsic size, without capping the user's font setting.

Every day in the browsed month shares the same marker-area height, selected from the largest saved entry count in that month. The area is 70 points for up to two entries, 75 for three, and 80 plus a native caption2-scaled allowance for more than three. This reserves space for the three dots, gaps, minor-tick padding and remaining-count label while keeping all horizontal ticks aligned. The cell grows with that shared marker area. The horizontal axis is centered in the safe-area viewport by accounting for the measured control height and the marker/tick axis offset. A minimum 24-point top clearance lets the axis sit lower when maximum-size controls and entry markers need more room. The native horizontal scroll view fills the remaining screen height; its content shape includes the blank bottom area for thumb swipes, while date buttons retain their own bounded hit areas. This replaces the earlier vertically scrolling accessibility timeline on supported portrait iPhones. The selected-date zoom anchor uses the actual axis offset instead of the former fixed 80-point offset. The editor and other text use scalable system styles. Exact maximum-size and overflow-marker visual evidence belongs in `docs/Testing.md`.

The day view draws a `#323575` branching stem and three grey period circles. Period labels have a paper-colored backing that keeps decorative lines clear of the text. Each circle opens the latest matching entry by creation order, or a new editor if none exists. Write always starts another draft. The list below the branches permits opening every saved entry, including earlier entries for the same period. Blank saved entries display “Untitled entry.”

`BearingsRootView` stores the tapped date's normalized viewport anchor. Opening a day scales the timeline to 1.8 around that anchor, moves it upward 180 points and fades it out; the day enters from 160 points below and fades in. Returning reverses the state change with `Animation.spring(response: 0.55, dampingFraction: 0.88)`. Reduce Motion removes the scale and offsets and uses `easeInOut(duration: 0.18)`. There is no matched-geometry effect, avoiding overlapping hidden source views. Explicit root layer ordering keeps paper at z-index 0, timeline at 1 and day at 2 so the day remains visible during the reverse transition. Animation and responsive geometry evidence is recorded in the testing log.

The writing interface uses Apple's `TextEditor` and system font, as approved by the owner. The editor sheet includes the day, editable period, Done and confirmed deletion. Saving status shares a footer in the normal layout with a native Hide keyboard icon while the editor is focused; its hit target is at least 44 × 44 points. The footer stays in the sheet's layout above the keyboard.

The oval and thin rule use Figma-derived `EditorCircle.svg` and `EditorRule.svg` imagesets with vector representation and geometry preserved. The latest owner instruction overrides the rule's original black stroke with opaque `#323575`; the oval retains its grey fill. At Dynamic Type accessibility4 and accessibility5, the editor uses a compact header: it omits the decorative oval and uses scalable native caption styles for the date and period metadata. Journal text retains the full scalable title3 style. `BearingsTheme` uses asset colors Paper (`#C8AB89`), Ink (`#000000`), Marker (`#D9D9D9`) and Line (`#323575`). The shared `BearingsTheme.line` supplies the opaque decorative timeline horizontal line/ticks, day branch strokes and entry dividers; the editor rule SVG uses the same opaque color. Text and control tint continue to use Ink, while marker fills and paper retain their existing colors. The application requests a light appearance to retain this owner-approved palette.

The app icon uses the owner-supplied and explicitly accepted `appIcon.png`, preserved without recoloring or redrawing and resized only to 1024 × 1024 for `Bearings/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`. The root source remains untouched. The original compass/topographic-map request specified `#C8AB89` / `#323575` design targets; exact two-color enforcement is not claimed for the accepted artwork. This asset does not alter the interface's Paper, Ink and Marker tokens.

## Future integration boundary

`LocalJournalRetrieving.snapshots(from:through:)` returns immutable `JournalEntrySnapshot` values within an inclusive civil-date range, including period, identity, body and timestamps, sorted by day and creation time. It provides a narrow read-only local boundary; it has no network client, AI runtime, analytics SDK, automatic sharing, or sync infrastructure. Later integrations require explicit authorization before sending journal content outside the device.

## Verification and documentation

Validate calendar identity, period persistence, create/update/delete behavior, blank draft semantics, failure handling, disk persistence across container recreation, navigation, keyboard use, and normal/Reduce Motion transitions. The exact commands, results, and remaining limitations belong in `docs/Testing.md`. Milestone progress belongs in `docs/Progress.md`; significant choices are recorded in `docs/Decisions.md`. These documents must be synchronized to the existing Bearings Notion hierarchy and the saved Notion content fetched for verification.
