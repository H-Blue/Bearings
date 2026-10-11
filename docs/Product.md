# Bearings product specification

Status: approved product direction, reconciled with implemented source on October 10, 2026. Build, test and visual verification results are maintained in `docs/Progress.md` and `docs/Testing.md`; implemented source alone does not establish that the MVP has passed its completion criteria.

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

The owner approved Apple's system font instead of Inter and clarified the three period circles. Implemented colors are parchment `#C8AB89`, ink `#000000` and markers `#D9D9D9`. The journal uses Figma's actual oval and rule SVG assets alongside Apple's native text editor. The timeline and day branches are native drawings representing actual journal data; dates with more than three entries show three dots and a remaining-count label. The browsed month's marker area grows together to fit those markers and the native count text while keeping ticks aligned.

The owner renamed the application and associated materials to **Bearings** on October 10, 2026, then supplied and explicitly approved `appIcon.png` as its app icon. The accepted artwork is preserved without recoloring or redrawing; only a resize to 1024 × 1024 is used for `Bearings/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`. The original file at the repository root remains untouched. The original design request called for a flush background, a fully visible circular compass over simplified topographic contours extending beyond the borders, and `#C8AB89` / `#323575` colors. Those remain the requested design targets; exact two-color enforcement is not claimed for the accepted image. Approved screen colors remain unchanged.

The interface uses safe areas, keyboard controls, accessible hit targets, the user's native Dynamic Type preference, and layouts that adapt to phone sizes. Timeline cells grow with the native date-caption scale so enlarged numbers have enough width and height. At accessibility text sizes, the timeline scrolls vertically so enlarged content remains reachable while dates still scroll horizontally. At the largest two accessibility sizes, the editor uses compact date/period metadata and omits the decorative oval to make room for writing; the journal body retains full scalable system text. Saving status and a native Hide keyboard icon share a footer above the keyboard. Day-period labels have paper backing to keep decorative lines clear of the text.

The transition scales the timeline around the tapped date, moves it upward, and introduces the day view from below. Reverse navigation uses the corresponding animation and preserves timeline state, with explicit visual layering throughout the transition. Reduce Motion uses a short fade. Simulator and device evidence for these behaviors is recorded separately.

## Data and privacy

The Bearings rename preserves the existing application bundle and persistent-store identities so previously saved writing remains available.

Entries are stored locally with SwiftData and operate without a network connection. Each has a stable unique identifier, associated civil date, explicit morning/midday/evening period, creation time, modification time, and text. A journal entry stays on the calendar date chosen by the user even if the device travels to another time zone. The displayed month is also a civil identity, so travel does not change the month being browsed.

The dedicated persistent store uses iOS file protection. Journal text is not logged or sent to analytics, AI services or cloud services. Store initialization or entry-loading failures show explicit retry screens rather than silently using temporary storage or presenting a failure as an empty journal. Saving and deletion happen in isolated transactions; failed mutations preserve previously committed data and the editor draft for retry.

## Future scope

AI reflection, on-device AI, optional sync, backup/export, progressive design reveal, guided writing tools, and reminders remain future possibilities. A local read-only retrieval boundary may support later work, but no AI client or network transport belongs in this foundation. Brainstorming notes are not approval to expand the MVP.

Social networking, streaks, achievements, subscriptions, complex analytics, cloud services, and a separate web app are excluded. External publication of the repository or application requires the owner's approval.

## Completion criteria

The MVP must launch on iPhone, support date and day navigation, provide the intended transition, create/edit/delete journal entries, show saving failures, save reliably, and retain entries after closing and reopening. It also needs a functioning Xcode project, maintainable SwiftUI code, Git, current `AGENTS.md`, accurate documentation, and recorded build and test evidence. Any unverified essential behavior remains an explicit limitation.

Sources: the owner's supplied v0.3 development brief, clarified period/font decisions, the explicit Bearings rename, app-icon direction and subsequently accepted owner-supplied artwork, the [Bearings Notion project](https://app.notion.com/p/3f5076d4a2e18039877ed1727adbcb42), and the inspected Reconnect designs.
