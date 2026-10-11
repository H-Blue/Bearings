# Bearings

A native, private iPhone journal for revisiting your story. Browse a timeline, open a day, and write in morning, midday or evening. Entries stay in local SwiftData storage; the app has no network client, cloud sync, analytics or AI request path.

Built with Swift, SwiftUI and SwiftData for **iOS 17 and later**, using Apple frameworks without external runtime dependencies.

## Run the app

You need a Mac with Xcode supporting iOS 17 or later and an installed iOS Simulator runtime. Development and verification used Xcode 27.0; iOS 17 is the deployment target, but an iOS 17 runtime has not been tested.

1. Download this repository using **Code → Download ZIP**, or clone it:

   ```sh
   git clone https://github.com/H-Blue/Bearings.git
   ```

2. Open `Bearings.xcodeproj` in Xcode from the downloaded folder.
3. Choose the **Bearings** scheme and an **iPhone simulator** at the top of the window.
4. Press **⌘R**. No developer-account configuration is needed for the simulator.

For a physical iPhone, select a valid Apple signing team in the app target. Device signing is configured locally; no signing certificate is committed here. Physical-device installation and behavior remain unverified.

## Features

- A map opening screen displays Bearings and “Find what’s been lost inside.” for at least two seconds on a fresh launch.
- Browse dates using the horizontal timeline, month arrows, date chooser and Today shortcut. Dots indicate saved entries.
- Open a day. Morning is on the left, midday at the top, evening on the right. A circle opens the latest entry for that period, or starts one if the period is empty.
- **Write** always creates another entry. The editor's time-of-day menu can change its assignment.
- Changes save after a short pause and on **Done** or app backgrounding. **Saved** confirms a successful local save. Failed saves retain the editor draft with a retry action.
- Delete through the editor's trash button and confirmation. Opening an unused editor creates no entry.
- Saved entries retain their selected calendar date across time-zone changes. Native text editing, Dynamic Type and Reduce Motion support keep writing and navigation accessible.

## Project map

`Bearings/` contains the app, models, storage, screens, design tokens, and local retrieval boundary. `BearingsTests/` verifies data and editor behavior; `BearingsUITests/` exercises the app through native controls. `docs/` records the product, references, architecture, decisions, progress, and exact verification results. `AGENTS.md` guides future development.

Source membership in the Xcode project is explicit. After adding/removing Swift files or supported resources, run:

```sh
python3 Scripts/generate_project.py
```

Project regeneration requires Python 3 and macOS `plutil`. The script preserves existing app signing teams and generates a deterministic shared project/scheme.

## Tests

Recorded verification on October 10, 2026:

- A clean export of the committed app passed an unsigned Debug simulator build; the public GitHub source was also cloned without credentials.
- The latest line-color change passed a Debug simulator build and two existing UI tests covering saved writing, period changes and reverse date navigation. Three screenshots were reviewed.
- The preceding rename/icon milestone passed all 24 data/editor tests, two focused UI tests and an unsigned generic iOS Release build.
- Earlier foundation runs passed eight core UI tests and focused keyboard, accessibility, persistence and animation checks. The complete suite and device Release build were not rerun for the final color-only change.

Exact commands, evidence and limits are in [Testing](docs/Testing.md). Physical-device behavior, a prior-version upgrade and an iOS 17 runtime remain unverified.

Use **⌘U** in Xcode to run tests on the selected simulator. For a command-line run:

```sh
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -derivedDataPath build/DerivedData -parallel-testing-enabled NO \
  -collect-test-diagnostics never \
  CODE_SIGNING_ALLOWED=NO
```

Use an available simulator name on your Mac. UI tests use a separate disk-backed test store; they never reset the normal journal.

## References and future work

The approved visual reference is [Reconnect in Figma](https://www.figma.com/design/dfQAU1BufaXau1fi2bWc5M/Reconnect?node-id=0-1). [Bearings in Notion](https://app.notion.com/p/3f5076d4a2e18039877ed1727adbcb42) is the product/documentation home. The prototype's circles and writing font were clarified by the owner; necessary date controls, labels, and entry lists are documented adaptations. Personal example writing from Figma is not bundled in the app.

The previously saved and verified [iOS Development handoff](https://app.notion.com/p/3f5076d4a2e181619c8bff6109e7ba69?pvs=204) contains the product, architecture, reference review, decisions, testing and milestone progress. `docs/NotionSync.md` records synchronization evidence, including the current Bearings milestone status.

Development was assisted by OpenAI Codex. The compass/topographic app-icon concept was created with the built-in image generator, then selected and supplied by the owner for integration. The accepted artwork was resized only to 1024 × 1024; its colors and texture were preserved. [Icon provenance](docs/design-reference/AppIcon.md) records the source, prompt and asset hashes.

The latest owner direction sets decorative timeline lines and ticks, day branches, entry dividers and the editor rule to opaque `#323575`. Text and control tint retain black Ink, period/entry markers retain grey, and the paper background is unchanged.

AI, cloud sync, export/backup, and progressive design reveal remain future work. A local read-only snapshot interface exists for later integration; it sends nothing over the network.

The public source repository is [H-Blue/Bearings](https://github.com/H-Blue/Bearings). GitHub setup is separate from a Hacklanta submission; no submission has been made. [Repository setup](docs/GitHub.md) records scope and verification.
