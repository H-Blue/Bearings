# Bearings product specification

Status: approved product direction, reconciled with implemented source on October 11, 2026. Build, test and visual verification results are maintained in `docs/Progress.md` and `docs/Testing.md`; implemented source alone does not establish that the MVP has passed its completion criteria.

## Purpose

Bearings is a native iPhone journal for personal stories, daily experiences, and emotional reflection. Its working tagline is “Find what's been lost inside.” The user's writing is the central experience. The app should feel private, reflective, tactile, and carefully made, without streaks or pressure to maintain engagement.

The initial audience is people who want a calm place to write about their experiences and revisit their personal story. The MVP provides writing and navigation, without psychological diagnoses or an AI assistant.

## Approved experience

The primary journey is **timeline → day → journal editor → day → timeline**.

1. Open the timeline and navigate calendar dates or months. Saved writing appears in the timeline's visual structure.
2. Select a day. The timeline expands and moves upward to preserve its relationship to the day view.
3. Choose a period on the branching day view: morning on the left, midday at the top, evening on the right. A circle opens the latest entry for that period, or a new editor when it has none. Circles show their saved entry counts.
4. Reopen any entry from the day's list, or use Write to create another entry. Write suggests morning before 12:00, midday before 17:00 and evening thereafter using the current local time. The editor's period menu allows the user to change that suggestion; the chosen value is persisted explicitly.
5. Changes save after a short pause; Done and leaving the active app also request an explicit save. Failed saves remain visible and preserve the editor draft for retry.
6. Return through the day to the timeline. Reopening the application must retain successfully saved writing.

Basic date navigation is an implementation detail needed to reach past dates and keep the timeline useful. It should remain small and native. The MVP also supports editing and deliberate deletion with confirmation. Creating a blank draft does not create a saved entry; clearing the text of an existing entry saves that edit without silently deleting the record.

## Visual and interaction requirements

The approved [Reconnect Figma file](https://www.figma.com/design/dfQAU1BufaXau1fi2bWc5M/Reconnect?node-id=0-1) defines the timeline, day branches, and journal composition. See `docs/ReferenceReview.md` for the inspected nodes and tokens. The Notion style direction includes parchment/cardstock, dark blue, black, brass brown, kerosene yellow, and restrained angular or hand drawn influences.

The owner approved Apple's system font instead of Inter and clarified the three period circles. Implemented colors are parchment `#C8AB89`, black text/control ink `#000000`, grey markers `#D9D9D9` and opaque decorative lines `#323575`. The latest owner instruction overrides the original Figma black linework for the timeline horizontal line/ticks, day branches, entry dividers and editor rule while preserving their geometry. The journal retains Figma-derived oval/rule SVG geometry alongside Apple's native text editor; the oval fill remains grey. The timeline and day branches are native drawings representing actual journal data; dates with more than three entries show three dots and a remaining-count label. The browsed month's marker area grows together to fit those markers and the native count text while keeping ticks aligned.

The owner renamed the application and associated materials to **Bearings** on October 10, 2026, then supplied and explicitly approved `appIcon.png` as its app icon. The accepted artwork is preserved without recoloring or redrawing; only a resize to 1024 × 1024 is used for `Bearings/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`. The original file at the repository root remains untouched. The original design request called for a flush background, a fully visible circular compass over simplified topographic contours extending beyond the borders, and `#C8AB89` / `#323575` colors. Those remain the requested design targets; exact two-color enforcement is not claimed for the accepted image. The supplied-icon choice preserves the screen palette; the subsequent owner linework instruction adds the blue Line color described above.

The interface uses safe areas, keyboard controls, accessible hit targets, the user's native Dynamic Type preference, and layouts that adapt to phone sizes. Timeline cells grow with the native date-caption scale so enlarged numbers have enough width and height. The centered timeline provides a full-height horizontal scroll surface below its controls, including the bottom thumb area; enlarged dates remain reachable at native accessibility text sizes. At the largest two accessibility sizes, the editor uses compact date/period metadata and omits the decorative oval to make room for writing; the journal body retains full scalable system text. Saving status and a native Hide keyboard icon share a footer above the keyboard. Day-period labels have paper backing to keep decorative lines clear of the text.

The transition scales the timeline around the tapped date, moves it upward, and introduces the day view from below. Reverse navigation uses the corresponding animation and preserves timeline state, with explicit visual layering throughout the transition. Reduce Motion uses a short fade. Simulator and device evidence for these behaviors is recorded separately.

## Timeline experience

The owner requested a quieter timeline on October 11, 2026: remove Bearings and the slogan from this view, remove the bottom helper sentence, and center the horizontal timeline axis in the safe-area viewport. Horizontal thumb swipes in the blank area near the bottom move the dates using native scrolling. A small fountain-pen outline in opaque `#323575` replaces the visible Today label and opens today’s journal; it retains a 44-point hit target and the accessible name “Write today.” Month navigation, the date chooser, entry markers and reverse navigation remain available. Opening-screen branding remains part of the separate opening experience.

## Opening experience

The owner selected the portrait topographic map with two mountain ridges and a river bending right near the bottom for the app opening. The artwork fills the screen; Bearings appears at the safe-area top right with “Find what’s been lost inside.” underneath, both in navy. A fresh launch displays the opening for at least two uninterrupted active seconds before opening the journal. Background interruptions restart the wait; a normal return after the opening has completed does not replay it. Text uses native Dynamic Type and the artwork adapts to screen proportions by filling and clipping.

## Data and privacy

The Bearings rename preserves the existing application bundle and persistent-store identities so previously saved writing remains available.

Entries are stored locally with SwiftData and operate without a network connection. Each has a stable unique identifier, associated civil date, explicit morning/midday/evening period, creation time, modification time, and text. A journal entry stays on the calendar date chosen by the user even if the device travels to another time zone. The displayed month is also a civil identity, so travel does not change the month being browsed.

The dedicated persistent store uses iOS file protection. Journal text is not logged or sent to analytics, AI services or cloud services. Store initialization or entry-loading failures show explicit retry screens rather than silently using temporary storage or presenting a failure as an empty journal. Saving and deletion happen in isolated transactions; failed mutations preserve previously committed data and the editor draft for retry.

## Future scope

AI reflection, on-device AI, optional sync, backup/export, progressive design reveal, guided writing tools, and reminders remain future possibilities. A local read-only retrieval boundary may support later work, but no AI client or network transport belongs in this foundation. Brainstorming notes are not approval to expand the MVP.

Social networking, streaks, achievements, subscriptions, complex analytics, cloud services, and a separate web app are excluded. External publication of the repository or application requires the owner's approval.

## Completion criteria

The MVP must launch on iPhone, support date and day navigation, provide the intended transition, create/edit/delete journal entries, show saving failures, save reliably, and retain entries after closing and reopening. It also needs a functioning Xcode project, maintainable SwiftUI code, Git, current `AGENTS.md`, accurate documentation, and recorded build and test evidence. Any unverified essential behavior remains an explicit limitation.

Sources: the owner's supplied v0.3 development brief, clarified period/font decisions, the explicit Bearings rename, app-icon direction and subsequently accepted owner-supplied artwork, the later blue-linework instruction, the [Bearings Notion project](https://app.notion.com/p/3f5076d4a2e18039877ed1727adbcb42), and the inspected Reconnect designs.
