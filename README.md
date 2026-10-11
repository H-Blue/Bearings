# Bearings

A native, private iPhone journal. Move along your timeline, open a day, and write in morning, midday, or evening. Your writing stays in local SwiftData storage.

## Run the app

1. Open `Bearings.xcodeproj` in Xcode.
2. Choose the **Bearings** scheme and an **iPhone simulator** at the top of the window.
3. Press **⌘R**. No developer-account configuration is needed for the simulator.

Xcode is already installed on the development Mac. The app supports iOS 17 and later and uses Apple's frameworks without external packages. Running on a physical iPhone requires a valid Apple signing team in the app target. The existing team configuration is retained; no signing certificate is committed here.

## Writing

- Scroll the horizontal timeline or use the month arrows and date chooser. Dots indicate saved entries.
- Open a day. Morning is on the left, midday at the top, evening on the right. A circle opens the latest entry for that period, or starts one if the period is empty.
- **Write** always creates another entry. The editor's time-of-day menu can change its assignment.
- Changes save after a short pause and on **Done** or app backgrounding. **Saved** confirms a successful local save. Failed saves retain the editor draft with a retry action.
- Delete through the editor's trash button and confirmation. Opening an unused editor creates no entry.

## Project map

`Bearings/` contains the app, models, storage, screens, design tokens, and local retrieval boundary. `BearingsTests/` verifies data and editor behavior; `BearingsUITests/` exercises the app through native controls. `docs/` records the product, references, architecture, decisions, progress, and exact verification results. `AGENTS.md` guides future development.

Source membership in the Xcode project is explicit. After adding/removing Swift files or supported resources, run:

```sh
python3 Scripts/generate_project.py
```

The script uses Python's standard library and macOS `plutil`, preserves existing app signing teams, and generates a deterministic shared project/scheme.

## Tests

Use **⌘U** in Xcode to run tests on the selected simulator. For a command-line run:

```sh
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -derivedDataPath build/DerivedData -parallel-testing-enabled NO \
  -collect-test-diagnostics never \
  CODE_SIGNING_ALLOWED=NO
```

Use an available simulator name on your Mac. UI tests use a separate disk-backed test store; they never reset the normal journal. Results and limitations are documented in `docs/Testing.md`.

## References and future work

The approved visual reference is [Reconnect in Figma](https://www.figma.com/design/dfQAU1BufaXau1fi2bWc5M/Reconnect?node-id=0-1). [Bearings in Notion](https://app.notion.com/p/3f5076d4a2e18039877ed1727adbcb42) is the product/documentation home. The prototype's circles and writing font were clarified by the owner; necessary date controls, labels, and entry lists are documented adaptations. Personal example writing from Figma is not bundled in the app.

The previously saved and verified [iOS Development handoff](https://app.notion.com/p/3f5076d4a2e181619c8bff6109e7ba69?pvs=204) contains the product, architecture, reference review, decisions, testing and milestone progress. `docs/NotionSync.md` records synchronization evidence, including the current Bearings milestone status.

The owner supplied and approved `appIcon.png` for the Bearings app icon. The artwork is preserved without recoloring or redrawing and resized only to 1024 × 1024 for `Bearings/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`. The root source remains untouched. The original compass/map direction requested `#C8AB89` and `#323575`; those are design targets, not a claim that the supplied image contains exactly two colors.

The latest owner direction sets decorative timeline lines and ticks, day branches, entry dividers and the editor rule to opaque `#323575`. Text and control tint retain black Ink, period/entry markers retain grey, and the paper background is unchanged.

AI, cloud sync, export/backup, and progressive design reveal remain future work. A local read-only snapshot interface exists for later integration; it sends nothing over the network.

Git is configured locally on `codex/bearings-foundation`. To host the project privately on GitHub later, sign in to GitHub and authorize creating/pushing a private repository. Remote publication requires the owner's approval.
