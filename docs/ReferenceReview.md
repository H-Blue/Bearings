# Bearings reference review

Reviewed on October 10, 2026 through the connected Notion integration and the Reconnect Figma file. The original Notion review is limited to the project home then associated with ReCollect and the three references supplied by the product owner. Unrelated ancestor projects were not read.

## Access and read status

| Reference | Verified read result | Source facts |
| --- | --- | --- |
| [Project home: Reco — title at original review](https://app.notion.com/p/3f5076d4a2e18039877ed1727adbcb42) | Successfully fetched page content | Tagline: “Find what’s been lost inside.” Links to Pitch, Initial Brainstorming, Design & Style Guide, and Steps for Project ReCollect at the time of review. Last edited reported as October 10, 2026, 21:26:21 UTC. |
| [Design & Style Guide](https://app.notion.com/p/3f5076d4a2e1803485f0cfc95d63f856) | Successfully fetched page content | Materials, palette names, angular/hand drawn direction, file naming convention, and progressive design reveal idea. Last edited reported as October 10, 2026, 19:51:00 UTC. |
| [Initial Brainstorming](https://app.notion.com/p/3f5076d4a2e180bfbd7dd67f7ec77adb) | Successfully fetched page content | Daily stories, meaningful life moments, emotional awareness, local storage and future AI ideas. Last edited reported as October 10, 2026, 17:10:20 UTC. |
| [Steps for Project ReCollect — title at original review](https://app.notion.com/p/3f5076d4a2e180ed841bd463c948dd36) | Successfully fetched database schema and queried its data source | Properties are `Name` (title) and `Checkbox` (checkbox). WIP filters unchecked rows; Finished filters checked rows. Query returned zero rows with `has_more: false`. |

The three fetched pages report native Notion verification state `unverified`. This is source metadata, not a fetch failure. The responses did not report truncation or unknown-block indicators; those fields were absent. No task completion claims can be inferred from the empty Steps database. The linked Pitch page was not read in this review.

## Confirmed direction

- The project home confirms the working tagline in the supplied development brief.
- The style guide specifies high contrast, kerosene yellow, dark blue, black, cardstock, brass brown, straight and jagged forms, aged paper, angular shapes, and hand drawn influence.
- The brainstorm favors daily personal stories and experiences, important life moments, emotional awareness, and an evolving direction for the user's life. It proposes building the basic journaling app first.
- The brainstorm supports local data storage and possible future local AI. It also names worn paper, maps, topography, compass, cartography, and seafaring as aesthetic references.

## Scope and conflicts

The supplied v0.3 brief explicitly authorizes a native Swift/SwiftUI/SwiftData iPhone foundation with timeline, day view, journal creation/editing/deletion, reliable local saving, and a timeline-to-day transition. The fetched Notion material contains no more detailed screen or interaction specifications.

- **Naming:** At the original review, the Notion home was titled `Reco` and brainstorming included `New Name HeartMap`; the initial application brief used `ReCollect`. The owner subsequently explicitly renamed the app and all associated materials to **Bearings** on October 10, 2026. Current application, repository and Notion material should use Bearings. Preserve historical source titles in this evidence record and the approved Figma file's actual name, Reconnect.
- **File convention:** The style guide says folders use `pw_purpose` and code files use `pw_`, referring to Project Wayfinder. This older convention is not aligned with the current Bearings naming. Record any chosen repository convention as an implementation decision rather than claiming it was established in Figma.
- **Progressive design reveal:** The style guide describes an app that becomes deeper and more complex with use. The explicit brief defers this concept; preserve flexibility without adding progression or achievements to the MVP.
- **Brainstorm features:** Daily triggers, working through texts, AI-selected art, stream of consciousness and the 12345 method are ideas, not approved initial functionality. The brief defers AI and excludes elaborate prompts and scope expansion.

## Confirmed Figma reference

The parent development agent found the [Reconnect file](https://www.figma.com/design/dfQAU1BufaXau1fi2bWc5M/Reconnect?node-id=0-1) in the connected desktop browser and inspected page metadata, design context, and screenshots for the three interface frames. This inventory records those confirmed findings; the Figma URL was not present in the four supplied Notion references.

| Frame | Node | Inspected dimensions | Confirmed visual structure |
| --- | --- | --- | --- |
| [Timeline](https://www.figma.com/design/dfQAU1BufaXau1fi2bWc5M/Reconnect?node-id=1-3) | `1:3` | 502.57 × 874 | Parchment background; horizontal major and minor timeline ticks; stacked grey dots above the timeline. |
| [Day](https://www.figma.com/design/dfQAU1BufaXau1fi2bWc5M/Reconnect?node-id=1-98) | `1:98` | 402 × 874 | Three grey circles at left, top and right connected by a branching black stem on parchment. |
| [Journal](https://www.figma.com/design/dfQAU1BufaXau1fi2bWc5M/Reconnect?node-id=1-180) | `1:180` | 402 × 874 | Parchment background `#C8AB89`; black Inter at 20 points in the prototype. |

Reference SVGs are saved under `docs/design-reference/`. Implemented timeline and day graphics use native drawing to represent actual dates and saved entries. The editor uses the actual Figma oval and rule SVGs as `EditorCircle` and `EditorRule` vector imagesets. Inspected asset colors are preserved as Paper `#C8AB89`, Ink `#000000`, and Marker `#D9D9D9`. The composition adapts to safe areas and phone sizes instead of fixing the app to the reference frame dimensions.

## Resolved owner decisions

- The current application and associated materials are named **Bearings**, superseding the initial ReCollect brief.
- The original icon request specified a flush, edge-to-edge background in `#C8AB89`, thin `#323575` linework, a fully visible circular compass and simplified topographic contours extending beyond the borders. The owner subsequently supplied and explicitly approved `appIcon.png` as the app icon. Preserve the accepted artwork without recoloring or redrawing, resize only to 1024 × 1024 for `Bearings/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`, and leave the root source untouched. The original colors are requested design targets; exact two-color enforcement is not claimed for the accepted image. This owner decision does not change the inspected interface tokens.
- The left circle means **morning**, the top circle means **midday**, and the right circle means **evening**. These are explicit journal periods, not decoration or a gamification system.
- The owner approved Apple's system font in place of Figma's Inter. Use the system text editor and accessible text scaling while preserving the inspected composition and palette.
- The implemented system text styles follow native Dynamic Type settings. Timeline cell width and cell/viewport height expand with the date-caption scale. The month also uses a shared marker-area height that grows for three dots or a remaining-count label, preserving aligned ticks. The 44 × 235 baseline applies at normal text size with at most two entries per day. The timeline adds vertical scrolling at accessibility sizes while retaining horizontal date browsing; these are data and accessibility adaptations of the inspected composition, with visual verification recorded separately.
- At the largest two accessibility text sizes, the editor omits the decorative oval and uses native caption date/period metadata to preserve writing space; journal text retains full scalable title3. The native keyboard-dismiss icon shares the normal saving footer. Day-period labels use paper-colored backing so decorative lines stay clear of text. These are accessibility and keyboard adaptations of the approved composition.
- The approved transition direction remains timeline zoom and upward movement into the selected day's branches, with corresponding reverse navigation. The implementation scales the timeline to 1.8 around the tapped day, offsets it −180 points, and introduces the day from +160 points while fading. Forward and reverse use a 0.55 response / 0.88 damping spring; Reduce Motion uses a 0.18-second fade without scale or offsets. These are routine implementation decisions, not behavior inferred from static screenshots.
- The root explicitly layers paper, timeline and day at z-indices 0, 1 and 2 to keep reverse navigation visually continuous. The animation's recorded simulator verification is maintained in `docs/Testing.md`.

Figma inspection is complete for these three frames, and the implementation descriptions above were reconciled with source. Visual fidelity, touch behavior, the native editor and animation evidence are recorded in `docs/Testing.md`; design inspection and source reconciliation alone are not test results.

## Documentation synchronization

This file records reference research and owner clarifications only. No Notion page or database was changed during this review. Implementation progress, technical architecture, decisions, verification results, and any differences between approved Figma designs and the implemented interface must be saved and verified in the Bearings Notion hierarchy as implementation milestones are completed.

The Bearings rename and owner-accepted app-icon milestone was synchronized to [iOS Development](https://app.notion.com/p/3f5076d4a2e181619c8bff6109e7ba69) and the saved content fetched for verification on October 10, 2026. See `docs/NotionSync.md` for the final verified scope and source hashes.
