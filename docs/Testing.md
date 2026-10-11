# Bearings verification

Run on October 10, 2026 using Xcode 27.0 (27A266a), Swift 6.4 compiler in Swift 5 language mode, and the iOS 27 SDK. The deployment target is iOS 17.

## Emotional Zoom clarity pass — October 11, 2026

The editor clarity slice passed an unsigned generic iOS Simulator build. The final complete `BearingsTests` run executed 64 tests with zero failures and one expected physical-device Foundation Models skip in 1.923 seconds. A preceding focused engine/service run executed 30 tests with zero failures in 0.612 seconds. New coverage rejects blank questions/explanations and excerpts not present in the draft, verifies complete long-draft segmentation, exercises the transient service route, confirms no journal record is created by the output, and adds Emotional Zoom to the real-device smoke path. After the owner replaced the eyeglasses direction with the supplied traditional magnifier reference, the focused synthetic UI flow passed again with zero failures in 32.898 seconds. It typed vague writing, used the navy magnifying-glass control, asserted the exact excerpt/explanation/question, refreshed through the navy sextant, saved the original entry and captured a screenshot. The screenshot was exported and visually reviewed; the clean circular-lens/diagonal-handle symbol is below Done and above the rule, and the result and refresh control are legible below the writing.

```sh
xcodebuild build -project Bearings.xcodeproj -scheme Bearings \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build/ZoomDerivedData \
  CODE_SIGNING_ALLOWED=NO
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=47707FD0-2CB6-49DC-B509-4B102AF0837C' \
  -derivedDataPath build/ZoomDerivedData -resultBundlePath build/ZoomUnitTestsFinal.xcresult \
  -only-testing:BearingsTests/AnalysisEngineTests \
  -only-testing:BearingsTests/JournalAnalysisServiceTests \
  -parallel-testing-enabled NO -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=47707FD0-2CB6-49DC-B509-4B102AF0837C' \
  -derivedDataPath build/ZoomDerivedData -resultBundlePath build/ZoomAllUnitTestsFinal.xcresult \
  -only-testing:BearingsTests -parallel-testing-enabled NO \
  -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=795E69CB-C101-488F-A8B0-CF3ECD77C7EE' \
  -derivedDataPath build/MagnifierUIDerivedData -resultBundlePath build/MagnifierUITest.xcresult \
  -only-testing:BearingsUITests/ReflectionFlowTests/testEmotionalZoomFindsVagueWritingAndAsksAQuestion \
  -parallel-testing-enabled NO -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
```

These checks use a deterministic synthetic on-device-provider fixture and do not establish real Foundation Models wording quality. Real-model generation for the new guided schema, a physical-device run, iOS 17 runtime behavior, maximum Dynamic Type and the complete UI suite remain unverified for this change. The harmless AppIntents metadata warning and simulator debugger lookup notice persisted. No project regeneration was needed because no Swift file was added. Notion synchronization is pending.

## AI sextant refresh controls — October 11, 2026

Verified with Xcode 27.0 on the iPhone 17e simulator running iOS 26.5. All 14 `JournalAnalysisServiceTests` passed with zero failures in 0.394 seconds. The new `testExplicitRefreshBypassesCachesAndPreservesCorrection` verifies that ordinary repeated requests reuse daily and weekly caches, explicit refresh makes a second provider request for each output, and the saved manual emotion remains unchanged. The suite also retained its cache sharing, source-change retry, cancellation, corrupt-cache repair, unavailable-model and real read-only-save failure coverage.

Two synthetic-provider UI tests passed with zero failures in 80.361 seconds: `testManualFeelingSurvivesRegenerationAndCanReturnToAISuggestion` and `testWeeklyAndMonthlyReflectionsUseSyntheticLocalProvider`. They locate and activate the daily and period refresh controls, cover daily correction preservation and refresh both weekly and monthly outputs. Exported daily, weekly and monthly attachments were inspected: each output header shows the custom sextant within an unclipped 44-point control, using the shared opaque navy `Line` color (`#323575`). The local result bundles are `/private/tmp/BearingsAIRefreshServiceSuite.xcresult` and `/private/tmp/BearingsAIRefreshUI.xcresult`.

The complete app unit/UI suites, physical-device Foundation Models generation, failure during a real refresh and iOS 17 runtime were not rerun. Synthetic provider success verifies control and cache plumbing, not real model quality or availability.

## Single-entry day marker — October 11, 2026

Verified with Xcode 27.0 on the iPhone 17e simulator running iOS 26.5. An unsigned Debug build for the generic iOS Simulator succeeded. `BearingsUITests/JournalFlowTests/testMorningBranchPersistsAndPeriodCanBeChanged` passed with zero failures in 66.147 seconds, covering creation, explicit save, the retained accessible label “Morning, 1 entry,” process relaunch, period reassignment and a second relaunch. The test's “Morning branch with saved memory” attachment was exported and visually inspected: the single morning entry appears as a centered navy dot inside the grey period circle, with no numeral 1. Source review confirms that counts above one remain numeric and that the dot uses shared `BearingsTheme.line`, whose asset value is opaque `#323575`.

The full unit and UI suites, physical-device behavior and iOS 17 runtime were not rerun for this view-only change. The targeted result bundle is local at `/private/tmp/BearingsSingleEntryDotUITest.xcresult`; build products remain outside the repository.

## Owner-directed centered timeline

Verified on October 11, 2026 using Xcode 27.0 and iPhone 17e, iOS 26.5. Timeline branding/slogan and both bottom helper messages are removed. A thin fountain-pen outline uses the shared opaque `#323575` token; its accessible “Write today” button retains a 44-point hit target and opens today’s journal. The native horizontal scroll surface extends through the blank bottom thumb area, while date tap targets remain bounded to their cells.

- Debug simulator compilation and three normal-text UI tests passed with zero failures in 86.300 seconds: bottom thumb scrolling in both directions and preserved scroll position after Back, earlier-month writing/markers/navigation, and forward/reverse Reduce Motion navigation. Evidence: `build/BearingsTimelineRefresh.xcresult` and `.log`.
- Three maximum-text UI tests passed with zero failures in 88.948 seconds: bottom thumb scrolling/reverse context, visible/tappable calendar dates before and after Back, and four-entry marker counts with disk relaunch. Evidence: `build/BearingsTimelineRefreshMaximumText.xcresult` and `.log`. Both reviewed marker screenshots show the full `+1`, three dots and complete two-digit dates. Both simulators’ text sizes were restored to `large`.
- iPhone 16 Pro screenshots at normal and maximum text size were reviewed at `docs/evidence/TimelineRefresh/TimelineDefault.png` and `TimelineMaximumText.png`. Both images have a full-width navy axis at pixel row 1352 of 2622, centered in the safe-area viewport. On the compact iPhone at maximum text with four-entry markers, the minimum clearance below the controls places the axis slightly lower so the count and all dates fit. UI-test attachments are exported under `docs/evidence/TimelineRefresh/NormalAttachments/` and `MaximumTextAttachments/`.
- Source review confirms unchanged opening screen, app icon, journal models, persistence and compatibility identities. The full unit suite, full UI suite, device Release build, iOS 17 runtime and physical-device thumb interaction were not rerun for this view-only change. Historical passing results remain below.

The normal run used:

```sh
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=47707FD0-2CB6-49DC-B509-4B102AF0837C' \
  -derivedDataPath build/BearingsTestDerivedData \
  -resultBundlePath build/BearingsTimelineRefresh.xcresult \
  -only-testing:BearingsUITests/JournalFlowTests/testTimelineCanBeScrolledFromTheBottomAndRetainsPosition \
  -only-testing:BearingsUITests/JournalFlowTests/testPreviousMonthDayRetainsEntryAndNavigationContext \
  -only-testing:BearingsUITests/JournalFlowTests/testForwardAndReverseNavigationWithReduceMotion \
  -parallel-testing-enabled NO -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
```

The maximum-text run first set `xcrun simctl ui 47707FD0-2CB6-49DC-B509-4B102AF0837C content_size accessibility-extra-extra-extra-large`, then used:

```sh
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=47707FD0-2CB6-49DC-B509-4B102AF0837C' \
  -derivedDataPath build/BearingsTestDerivedData \
  -resultBundlePath build/BearingsTimelineRefreshMaximumText.xcresult \
  -only-testing:BearingsUITests/JournalFlowTests/testTimelineCanBeScrolledFromTheBottomAndRetainsPosition \
  -only-testing:BearingsUITests/JournalFlowTests/testTimelineDateCellRemainsReachableWithLargeText \
  -only-testing:BearingsUITests/JournalFlowTests/testMultipleEntriesRemainOnTheSameDay \
  -parallel-testing-enabled NO -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
```

## Owner-directed map opening screen

Verified on October 11, 2026. `OpeningMap` preserves the owner-selected 1206 × 2622 right-curving river/ridge image byte-for-byte. Bearings and “Find what’s been lost inside.” appear in navy at the safe-area top right. The active-scene task waits two seconds; scene interruptions cancel/restart it, and completed openings do not replay on normal foreground returns. Storage initializes afterward, retaining the existing visible failure/retry path.

- Final Debug simulator compilation and two existing UI tests passed with zero failures in 82.880 seconds on iPhone 17e, iOS 26.5, Xcode 27.0. Tests cover saved writing/edits across process relaunch and forward/reverse Reduce Motion navigation. Evidence: `build/BearingsOpeningScreenFinalUITests.xcresult` and `build/BearingsOpeningScreenFinalUITests.log`. A preceding overlay/preload version also passed; the final conditional opening/storage sequence is the verified final build.
- Actual iPhone 16 Pro simulator screenshots, iOS 26.5, were reviewed at normal and maximum accessibility text size. The full-bleed map and complete title/slogan are visible, and the journal appears afterward. Evidence: `docs/evidence/OpeningScreen/OpeningDefault.png`, `OpeningMaximumText.png` and `TimelineAfterOpening.png`. The created simulator's text size was restored to `large`.
- The warm-launch native recording `docs/evidence/OpeningScreen/OpeningTimingWarm.mp4` contains 114 frames with monotonic timestamps. Image comparison located the first fully rendered map frame at 18.441667 seconds and the first timeline frame at 20.568333 seconds: approximately 2.13 seconds of map presentation. The map remains still between encoded frames. Scores and timestamps are in `build/OpeningScreenSetup/WarmNativeFrameScores.json`. This supports the two-second opening floor, not a device frame-rate benchmark. The initial fresh-simulator recording had discontinuous timestamps and was excluded from quantitative timing evidence.
- The image asset and accepted source share SHA-256 `809925cf983bcfa6b7cd68c467fcb4816718b030df25fab12088642fe47830d3`. Source review confirms unchanged journal models, stores, editor logic, bundle/store identity and app icon. No full unit/accessibility suite or device Release build was rerun for this opening-only change. Physical-device launch timing, iOS 17 runtime and interrupted-opening presentation remain unverified.
- Backgrounding to Settings and returning to the same app process showed the timeline immediately without replaying the opening. Screenshot: `docs/evidence/OpeningScreen/TimelineAfterBackgroundReturn.png`.

Final test command actually run:

```sh
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=47707FD0-2CB6-49DC-B509-4B102AF0837C' \
  -derivedDataPath build/BearingsTestDerivedData -resultBundlePath build/BearingsOpeningScreenFinalUITests.xcresult \
  -only-testing:BearingsUITests/JournalFlowTests/testEntryPersistsAcrossRelaunchAndCanBeEdited \
  -only-testing:BearingsUITests/JournalFlowTests/testForwardAndReverseNavigationWithReduceMotion \
  -parallel-testing-enabled NO -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
```

The iPhone 16 Pro simulator is `4D6128DA-96C3-4BC3-89C5-EF5975616AC7`. The built Debug app was installed with `simctl install`, launched with the isolated `--uitesting` store, and captured using `simctl io screenshot` and `recordVideo --codec=h264`. `simctl ui content_size` selected maximum accessibility size for review and restored `large`. Native frame inspection used `ffprobe` timestamps and `ffmpeg` decoded frames, compared against the actual map screenshot with Pillow/NumPy; image files were not edited.

## Public GitHub source setup

Verified on October 10, 2026. The owner requested GitHub setup, selected public visibility, and explicitly excluded hackathon submission. The public repository is [H-Blue/Bearings](https://github.com/H-Blue/Bearings), with `main` as its default branch.

- A clean export of committed source `897d848a5f2db768eb148ddc7939dad1e58d578c` (52 tracked files) passed an unsigned Debug build for generic iOS Simulator. Environment: macOS 26.6.2 (25G83), Xcode 27.0 (27A266a), Swift 6.4 compiler, iOS Simulator 27.0 SDK and iOS 17 deployment target. Evidence: `build/BearingsGitHubSourceBuild.log`; derived data: `build/BearingsGitHubSourceDerivedData`. Bearings branding, retained bundle identity, AppIcon and compiled assets were inspected. The only build warning was unused AppIntents metadata extraction.
- The source/history audit found no recognized credential patterns, private journal data, database files, logs, result bundles or build artifacts in the intended source history. The app source, shared scheme, icon and privacy manifest are tracked. Owner signing changes and untracked working materials were preserved locally.
- Only `main` was pushed. GitHub reported public visibility and the `main` default branch. A fresh clone with credential helpers disabled succeeded and matched the local source commit. An anonymous raw README download matched the committed file's SHA-256. Local Codex checkpoint refs were excluded.
- Hosting and README/documentation changes do not change the app. Data/editor, UI, accessibility and Release checks were not rerun for GitHub setup; previous passing results and device/runtime limits below remain applicable. No hackathon submission was made.

Commands actually run:

```sh
xcodebuild build -project build/GitHubSourceCheckout/Bearings.xcodeproj -scheme Bearings \
  -configuration Debug -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/BearingsGitHubSourceDerivedData CODE_SIGNING_ALLOWED=NO
GIT_TERMINAL_PROMPT=0 git -c credential.helper= -c credential.interactive=never clone \
  --single-branch --branch main https://github.com/H-Blue/Bearings.git build/GitHubPublicCheckout
curl -q -fLsS https://raw.githubusercontent.com/H-Blue/Bearings/main/README.md \
  -o build/BearingsGitHubPublicREADME.md
```

The export was created by capturing `git archive --format=tar 897d848a5f2db768eb148ddc7939dad1e58d578c` through Python's `subprocess` module and extracting it with `tarfile` into an empty `build/GitHubSourceCheckout`, after validating that every archive path stayed inside that directory. Build artifacts and public-checkout evidence remain ignored local files. README/documentation changes following the compiled source do not change the app implementation.

## Owner-directed navy linework

Verified on October 10, 2026 using Xcode 27.0 and iPhone 17e, iOS 26.5. All custom decorative linework now uses opaque sRGB `#323575`: timeline horizontal line/ticks, day branches, entry dividers and the editor rule. `Line` / `BearingsTheme.line` provides the native drawing color; the SVG rule's stroke uses the same value. Source review confirmed that the rule geometry, line widths, text/control ink, gray marker fills, paper and accepted app icon are preserved.

- Debug simulator compilation and two existing UI tests passed: zero failures, 113.875 seconds. They exercise period reassignment and saved text across relaunch, plus earlier-month entry navigation and reverse context. Evidence: `build/BearingsLineColorUITests.xcresult` and `build/BearingsLineColorUITests.log`.
- All three exported screenshots were visually reviewed: navy timeline/ticks, day branches and entry divider, and editor rule are visible in `docs/evidence/Linework/`. Original source Figma assets under `docs/design-reference/` retain the historical black strokes; the app rule is the owner-recolored copy.
- Exact sRGB asset channels and full opacity were inspected. Each original screenshot contains pixels exactly matching RGB `(50, 53, 117)` / `#323575` (editor: 2,898; day: 3,648; timeline: 8,226). The SVG source differs from its earlier version only by the stroke color; independent source audit found no overlooked custom line primitives.
- No persistence behavior changed, and no new tests were added. The full data/editor and accessibility suites, unsigned device Release build, iOS 17 runtime and physical-device appearance were not rerun for this color-only change; earlier results below remain historical evidence.

Commands actually run:

```sh
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=47707FD0-2CB6-49DC-B509-4B102AF0837C' \
  -derivedDataPath build/BearingsTestDerivedData -resultBundlePath build/BearingsLineColorUITests.xcresult \
  -only-testing:BearingsUITests/JournalFlowTests/testMorningBranchPersistsAndPeriodCanBeChanged \
  -only-testing:BearingsUITests/JournalFlowTests/testPreviousMonthDayRetainsEntryAndNavigationContext \
  -parallel-testing-enabled NO -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
xcrun xcresulttool export attachments --path build/BearingsLineColorUITests.xcresult \
  --output-path docs/evidence/Linework --filter '*.png'
```

## Bearings rename and owner-selected icon

Verified on October 10, 2026 with the same Xcode version, iOS 17 deployment target and iPhone 17e simulator running iOS 26.5. The owner supplied `appIcon.png` and explicitly selected it. The source remains unchanged; the app copy was resized from 1254 × 1254 to an opaque 1024 × 1024 PNG without recoloring, redrawing or cropping. The accepted image is not claimed to contain only the two hex colors in the original generation brief. Source and asset hashes and generation provenance are in `docs/design-reference/AppIcon.md`.

| Check | Actual result |
| --- | --- |
| Renamed project syntax and discovery | Passed: `plutil -lint`, Xcode target/scheme discovery and stable project identity checks. |
| Project generator and local signing preservation | Passed in a temporary copy. Generated project semantics match the renamed working project with AppIcon; original per-configuration signing teams, absent teams, fresh projects and invalid-project failure preservation were checked. `build/BearingsGeneratorValidation.log`. |
| Debug simulator build and complete data/editor suite | Passed: 24 tests, zero failures, including both real read-only SwiftData failure/retry fixtures. `build/BearingsRenameUnitTests.xcresult`, `build/BearingsRenameUnitTests.log`. |
| Focused native UI suite | Passed: 2 tests, zero failures, 69.809 seconds. Saved writing and edits survive relaunch; forward/reverse Reduce Motion navigation works. `build/BearingsRenameUITests.xcresult`, `build/BearingsRenameUITests.log`. |
| Unsigned Release build for generic iOS device | Passed. Built name/display name/executable are Bearings; existing bundle ID is retained; primary icon is AppIcon; compiled `Assets.car` is included. `build/BearingsDeviceRelease.log`. |
| Installed simulator Home Screen icon | Passed visual review: Bearings label and selected compass/topographic artwork appear, with the circular compass entirely inside the system icon mask. `build/BearingsHomeScreen.png`. |
| Compatibility source review | JournalStore, date/model types, retrieval boundary and editor-session behavior are unchanged at their renamed paths. Existing production bundle identifier, SwiftData configuration and journal path are retained. |

Commands actually run for this milestone:

```sh
plutil -lint Bearings.xcodeproj/project.pbxproj
xcodebuild -list -project Bearings.xcodeproj
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=47707FD0-2CB6-49DC-B509-4B102AF0837C' \
  -derivedDataPath build/BearingsTestDerivedData -resultBundlePath build/BearingsRenameUnitTests.xcresult \
  -only-testing:BearingsTests -parallel-testing-enabled NO \
  -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=47707FD0-2CB6-49DC-B509-4B102AF0837C' \
  -derivedDataPath build/BearingsTestDerivedData -resultBundlePath build/BearingsRenameUITests.xcresult \
  -only-testing:BearingsUITests/JournalFlowTests/testEntryPersistsAcrossRelaunchAndCanBeEdited \
  -only-testing:BearingsUITests/JournalFlowTests/testForwardAndReverseNavigationWithReduceMotion \
  -parallel-testing-enabled NO -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
xcodebuild build -project Bearings.xcodeproj -scheme Bearings -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath build/BearingsDeviceDerivedData \
  CODE_SIGNING_ALLOWED=NO
xcrun simctl io 47707FD0-2CB6-49DC-B509-4B102AF0837C screenshot build/BearingsHomeScreen.png
```

The full UI/accessibility suite was not rerun for the branding-only change; its earlier results below remain historical evidence. Signed physical-device installation, a real upgrade from the prior binary, an iOS 17 runtime and alternate Home Screen appearances remain unverified. Compatibility is supported by preserved identity and unchanged persistence behavior, rather than a performed upgrade test. No app interface styling or persistence behavior changed in this milestone.

## Earlier foundation results

| Check | Actual result |
| --- | --- |
| Xcode project lint and deterministic regeneration | Passed. Standard-library project generator includes app, hosted unit tests, UI tests and resources. |
| Debug simulator build and unit tests on iPhone 18 Pro, iOS 27.0 | Initial suite passed: 22 tests, zero failures. `build/UnitTestsFinal.xcresult`. |
| Final data/editor suite on iPhone 17e, iOS 26.5 | Passed: 24 tests, zero failures on the final isolated-write implementation. `build/FailureAllMutationsIsolated.xcresult`. |
| Unsigned Release build for generic iOS device | Passed on the final source, including scalable timeline cells, compact editor header and transition layering. `build/device-build-final.log`. No physical-device installation or external publication occurred. |
| Full native UI suite on iPhone 18 Pro, iOS 27.0 | Passed: 8 tests, zero failures, 438.814 seconds. `build/UITestsFinal.xcresult`. |
| Read-only persistence failure tests | Both passed within the final 24-test run, including repeated real save/delete failures. |
| Compact iPhone 17e, iOS 27.0, accessibility-extra-large text | Final 2 tests passed, zero failures, with clear screenshots. `build/AX3Final.xcresult`. |
| Compact iPhone 17e, iOS 26.5, normal text, final keyboard layout | Passed: 1 long-writing test, including hiding/reopening the keyboard and disk persistence. `build/KeyboardFinal.xcresult`. |
| Compact iPhone 17e, iOS 27.0, maximum accessibility text size | Final 2 tests passed, zero failures, with complete editor/date/period labels and readable writing. `build/AX5CompactHeader.xcresult`. |
| Maximum-size timeline date selection and reverse context | Passed: 1 focused test, zero failures. `build/AX5TimelineFix.xcresult`. Before/after screenshots show complete dates 8–12, including two-digit labels. |
| Normal-size timeline geometry and earlier-month navigation | Passed: 1 focused test, zero failures. `build/TimelineGeometryNormal.xcresult`. Earlier-day markers, month position and disk relaunch remain correct. |
| Maximum-size four-entry timeline marker and persistence | Passed: 1 focused test, zero failures. `build/AX5TimelineMarkers.xcresult`. Both timeline screenshots show the complete remaining count, three dots and dates, including after disk relaunch. |
| Normal-size four-entry timeline marker and persistence | Passed: 1 focused test, zero failures. `build/TimelineMarkersNormal.xcresult`. Dates 6–14, three dots and the remaining count remain clear before/after relaunch. |
| Final normal and Reduce Motion navigation | Passed: 2 focused tests, zero failures. `build/TransitionFinal.xcresult`. Native-frame review confirmed both reverse transitions remain layered correctly. |

## What the unit tests verify

Calendar tests cover strict day-key validation, leap years, local midnight, daylight saving, non-Gregorian calendar settings, travel across time zones, skipped civil dates, and month navigation across year boundaries. A civil month includes every intended day even when a particular time zone skipped one.

Persistence tests use both isolated in-memory and actual file-backed stores. They verify stable IDs, creation/modification times, multiple entries per day, explicit periods, edits, deletion, disk reopening, cleared existing entries, blank-new-entry rejection, invalid-store launch failure, and the local snapshot retrieval boundary. Editor tests verify that unused drafts create nothing and late changes cannot resurrect a successfully deleted entry.

The initial run passed 17 tests but exposed noisy test cleanup that unlinked open SQLite files. Tests were changed to leave isolated simulator temporary stores to process/system cleanup. The final 22-test run had no such SQLite unlink warnings.

Two additional tests open real file-backed SwiftData fixtures with saving disabled. They exposed a genuine failure-recovery defect: rollback and native undo did not reliably restore registered model values or fetch membership after failed writes. The final store isolates every mutation in a fresh context using the same container, and only mirrors successful commits into visible models. Repeated failed creates leave no ghost entries; failed edits retain the saved body, period and timestamps; failed deletes retain the record and retry deletion. All assertions passed without weakening the fixtures or replacing their storage with an injected mock.

## What the UI tests exercise

Eight tests drive the real app through native accessibility controls: blank drafts; cancellation/confirmation of deletion; saved writing and edits across process termination/relaunch; long multiline writing with the keyboard open; multiple entries on one day; morning/evening assignment and reassignment; earlier-month day selection and reverse navigation; and the custom navigation's Reduce Motion route. The Reduce Motion test uses a Debug-only override of the same branch driven by the system accessibility setting. It does not change the simulator's global settings.

Test runs use a separate disk-backed UI store. `--uitesting` selects it; `--reset-test-store` explicitly resets only that test store. These hooks exist only in Debug builds. Test writing is fictional; the personal sample text in Figma is not copied into the app or test fixtures.

The initial eight-test UI run passed seven tests and failed to locate a previous-month date button. Removing the unnecessary accessibility-child grouping restored the button's identity. The unchanged date-navigation test then passed in `build/DateNavigationFix.xcresult`. The full eight-test suite subsequently passed on the final isolated storage implementation.

Accessibility screenshot review found decorative branch lines crossing enlarged labels and a floating keyboard accessory obscuring the save status. Labels now mask the line behind them with the paper color. The editor's keyboard-hide control now shares an in-layout footer with the save status instead of floating over it. The complete eight-test workflow run compiled before these two layout refinements; focused keyboard and period checks verify the final layout separately. The long-writing test now also hides and reopens the keyboard, verifies that all 24 lines remain unchanged, and uses Done with the keyboard open.

The first maximum-font run passed its interaction assertions but exposed truncated metadata and clipped writing in screenshots. At the two largest accessibility sizes, the editor now omits the decorative oval and uses scalable native caption styles for date and period metadata; journal text retains the full native title3 size. The two focused maximum-font tests then passed with complete labels and visible writing/caret. Maximum-size day labels wrap without ellipses, and the day content scrolls. Simulator text size was restored to its previous `large` setting after checks.

A ninth UI test selects the actual timeline date at the maximum text size and verifies reverse context after Back. Its first run passed interaction assertions but screenshots exposed clipped one-digit labels and missing two-digit labels. Timeline cells now expand in width and height with the native caption scale while preserving 44 × 235 points for the standard-size empty/two-entry layout. Labels retain their intrinsic single-line size without a font cap. The final focused run passed, and both screenshots show complete dates before selection and after returning. The normal-size earlier-month navigation test also passed after this geometry change.

Review also found that three stacked dots on a minor tick need 75 points, and more than three entries additionally need room for the native remaining-count caption. The marker area now grows uniformly across the browsed month; cell and scroll viewport heights use that same allowance to preserve aligned ticks. The multiple-entry test now creates four entries, checks every entry and the actual timeline date's count, then relaunches from disk. The maximum-font and normal-size focused runs both passed, with complete `+1` labels, three separate dots and readable dates in the before/after-relaunch screenshots. Neither run reported SwiftUI layout warnings, and the simulator font was restored and verified as `large`.

Native recording exposed a brief blank content frame on reverse navigation. Explicit fixed layers (paper 0, timeline 1, day 2) preserve the departing day above the background. The two final navigation tests passed. Review of 88 decoded native frames across two reverse sequences in `docs/evidence/TransitionFinal.mp4` showed the day moving/fading above the returning timeline without a blank content frame. Simulator recordings have variable frame timing; low-rate frame conversion can exaggerate gaps, so these observations use native timestamps. This is layering evidence, not a device frame-rate benchmark.

## Earlier foundation commands and evidence

```sh
python3 Scripts/generate_project.py
xcodebuild test -project ReCollect.xcodeproj -scheme ReCollect \
  -destination 'platform=iOS Simulator,id=47707FD0-2CB6-49DC-B509-4B102AF0837C' \
  -derivedDataPath build/SecondaryDerivedData -resultBundlePath build/FailureAllMutationsIsolated.xcresult \
  -only-testing:ReCollectTests -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
xcodebuild test -project ReCollect.xcodeproj -scheme ReCollect \
  -destination 'platform=iOS Simulator,id=795E69CB-C101-488F-A8B0-CF3ECD77C7EE' \
  -derivedDataPath build/DerivedData -resultBundlePath build/UITestsFinal.xcresult \
  -only-testing:ReCollectUITests -parallel-testing-enabled NO \
  -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
xcodebuild build -project ReCollect.xcodeproj -scheme ReCollect -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath build/DeviceDerivedData \
  CODE_SIGNING_ALLOWED=NO
```

Build artifacts, detailed logs, result bundles and screenshot evidence stay local and are ignored by Git. Xcode reports a harmless skipped AppIntents metadata extraction because the app has no AppIntents integration. UI automation also reports a debugger-version lookup notice; completion and assertion results, rather than that notice, determine test status.

Earlier UI runs reported an unlocated frame-dimension warning as the keyboard opened. It did not recur in the final normal-text or accessibility keyboard runs after the floating keyboard toolbar was removed. Initial diagnostic collection stalled after a passing focused test; stopping only that completed run's `simctl diagnose` child allowed a successful exit/result export. Final runs use `-collect-test-diagnostics never` and complete normally.

## Earlier foundation limits

- No physical iPhone was attached or tested. Device signing, actual locked-device file protection, haptics, and real-device animation performance remain unverified.
- iOS 17 is validated as the compilation/deployment target; an iOS 17 runtime is not installed here.
- There is no application network client, cloud sync, analytics SDK or AI request path. Offline capability is supported by source inspection and local-store execution; a disconnected physical-device session has not been performed.
- Abrupt termination before the 350 ms debounce or a failed disk save can leave the newest draft unpersisted. Done and inactive/background transitions request immediate saves, and the editor retains failed drafts while open. Repeated failure will not be presented as saved.
- File-backed read-only fixtures verified failed-save/delete isolation and repeated retries. Recovery from a real disk-full or locked-device failure, and its complete UI presentation, still require device-level testing.
- Automated navigation checks establish working routes and reverse context. Final animation feel and frame-rate profiling require owner/device review.

## Local intelligence milestone — October 11, 2026

This section supersedes the earlier foundation's AI and device limits where explicitly verified below. Tests use invented writing. No private journal text was exported, logged or sent to a model service.

| Executed check | Actual result / evidence |
| --- | --- |
| First integrated Debug simulator build, Xcode 27.0 / SDK 27, iOS 17 deployment target | Passed. `build/AIBuild.log`. |
| First persistence/service suite on iPhone 17e, iOS 26.5 simulator | 38 passed, zero failures. `build/AIUnitTests.xcresult`. |
| Expanded unit suite including engine, concurrency and civil-boundary checks, same simulator | 53 passed, zero failures. `build/AIUnitTestsFinal.xcresult`. |
| Final complete simulator unit suite, iPhone 17e / iOS 26.5 | 60 executed: 59 passed, one real-model test skipped on simulator, zero failures. Includes cache repair, independent correction reads, repeated real failed correction saves/removals and cancellation resumption. `build/AIUnitTestsAcceptance.xcresult`. |
| Signed Debug build for Harry's physical iPhone 16 Pro, iOS 27.0.1 | Passed after building outside the Documents file-provider directory; rerun after recovery refinements. `build/AIDeviceBuildAccessible.log`; strict signature verification passed. |
| Local app installation and launch on that iPhone | Both succeeded with the retained bundle identifier. Launch used `--uitesting`, selecting the separate test journal. No TestFlight distribution. `build/AIDeviceLaunch.log`. Latest recovery build update-installation also succeeded (`build/AIDeviceInstallAccessible.log`); it was not relaunched while the phone remained locked. |
| Real Apple-model smoke test on the physical iPhone | Skipped: runtime reports `modelNotReady` (“Apple’s on-device model is still preparing”). No real generation was performed. `build/AIRealDeviceTestsUnitScheme.xcresult`. |
| Full physical-device unit suite | 54 executed: 53 passed, one model-readiness skip, zero failures. Includes actual file-backed old-schema migration, original repeated failed saves/retries, new derived save/correction/move failures, cache invalidation and cancellation resumption. `build/AIAllDeviceUnitTests.xcresult`. |
| Complete native UI suite, iPhone 18 Pro / iOS 27.0 | 15 passed, zero failures: 10 foundation journal/navigation flows and five new reflection/metadata/correction/unavailable flows. `build/AIUITests.xcresult`; 781.970 seconds. Synthetic local AI provider, no real model. |
| Final reflection UI suite at maximum accessibility text size, compact iPhone 17e / iOS 27.0 | 5 passed, zero failures on the final UI source. `build/AIReflectionAX5Final.xcresult`; 249.174 seconds, no reported runtime warnings. Native Form/menu scrolling, creation-time preservation, correction reset, unavailable/empty states and period results. |
| Unsigned generic iOS Release build, rerun after final service/UI refinements | Passed with iOS 17 deployment target. `build/AIReleaseBuildAccessible.log`. Binary inspection confirmed minimum OS 17.0 and weak linkage to Foundation Models. |

The initial signed product under Documents failed with “resource fork, Finder information, or similar detritus not allowed.” Removing extended metadata only from the generated product allowed signing, but the file provider reintroduced Finder metadata and strict verification failed afterward. Building in `/private/tmp/BearingsAIDeviceDerivedData` resolved this; source artwork and metadata were not changed. The original signed test attempt with the full scheme failed because no provisioning profile existed for the separate UI test runner. The new generated `BearingsDeviceTests` scheme builds hosted unit tests only and supplies `--uitesting` to the host, avoiding that account resource and the ordinary journal store. No profile was created or account setting changed.

A follow-up full-device run waited at launch because the iPhone was locked and was stopped before tests executed (`build/AIAllDeviceUnitTestsFinal.log`). The successful earlier physical suite above remains the device evidence; the later cache/correction recovery refinements were separately verified in the final simulator suite.

The initial maximum-text run passed three tests and failed two selectors that expected offscreen native Form/menu items to exist without scrolling (`build/AIReflectionAX5.xcresult`). The tests now reveal those native controls, and the final five-test run passed. Actual screen review also found wrapped day-header control labels at the two largest sizes; native icons with unchanged accessible names/44-point targets and a fully scalable caption date restore room for the scroll content. Normal-size geometry and branch linework are preserved. Reviewed normal and final maximum-size screenshots are under `docs/evidence/LocalAI`; the compact simulator font is restored to its original large setting after review. The 15-test normal suite predates these focused accessibility/retry refinements; the final maximum-size suite and final unit suite verify those changes.

The reviewed maximum-size metadata screenshots show wrapped creation time/zone fields. The final test scrolls to and asserts Last edited, which is outside the selected screenshot viewport; complete maximum-size metadata in one screenshot is not claimed. Period text remains accessible by scrolling. Normal screenshots show all reflection fields.

The project generator was rerun and preserved the project, both schemes, workspace and local signing byte-for-byte (`build/AIGeneratorValidation.json`).

The new deterministic engine/service tests verify guided-output Codable shape and fixed taxonomy, every UTF-8 byte including oversized combining graphemes, long-source segmentation, adaptive context retries and explicit irreducible errors, independent extracted-event retention, one inference at a time, queued/in-flight cancellation, resumed work, duplicate day/period requests, month-clipped sources, override precedence and persisted cache reuse. They establish pipeline correctness with injected results, not Apple's semantic emotion accuracy.

### Commands used for the AI milestone

```sh
python3 Scripts/generate_project.py
xcodebuild build -project Bearings.xcodeproj -scheme Bearings \
  -destination 'generic/platform=iOS Simulator' -derivedDataPath build/AIDerivedData \
  CODE_SIGNING_ALLOWED=NO
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=47707FD0-2CB6-49DC-B509-4B102AF0837C' \
  -derivedDataPath build/AIDerivedData -resultBundlePath build/AIUnitTestsAcceptance.xcresult \
  -only-testing:BearingsTests -parallel-testing-enabled NO \
  -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=795E69CB-C101-488F-A8B0-CF3ECD77C7EE' \
  -derivedDataPath build/AIUIDerivedData -resultBundlePath build/AIUITests.xcresult \
  -only-testing:BearingsUITests -parallel-testing-enabled NO \
  -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
xcrun simctl ui AB0A92C0-900B-46A8-85A9-8053C46559E9 content_size accessibility-extra-extra-extra-large
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=AB0A92C0-900B-46A8-85A9-8053C46559E9' \
  -derivedDataPath build/AIAX5DerivedData -resultBundlePath build/AIReflectionAX5Final.xcresult \
  -only-testing:BearingsUITests/ReflectionFlowTests -parallel-testing-enabled NO \
  -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
xcrun simctl ui AB0A92C0-900B-46A8-85A9-8053C46559E9 content_size large
xcodebuild build -project Bearings.xcodeproj -scheme Bearings -configuration Debug \
  -destination 'platform=iOS,id=00008140-0011052A3C32801C' \
  -derivedDataPath /private/tmp/BearingsAIDeviceDerivedData
xcodebuild build -project Bearings.xcodeproj -scheme BearingsDeviceTests -configuration Debug \
  -destination 'platform=iOS,id=00008140-0011052A3C32801C' \
  -derivedDataPath /private/tmp/BearingsAIDeviceDerivedData
codesign --verify --strict --verbose=2 /private/tmp/BearingsAIDeviceDerivedData/Build/Products/Debug-iphoneos/Bearings.app
xcrun devicectl device install app --device 00008140-0011052A3C32801C \
  /private/tmp/BearingsAIDeviceDerivedData/Build/Products/Debug-iphoneos/Bearings.app
xcodebuild test -project Bearings.xcodeproj -scheme BearingsDeviceTests \
  -destination 'platform=iOS,id=00008140-0011052A3C32801C' \
  -derivedDataPath /private/tmp/BearingsAIDeviceDerivedData \
  -resultBundlePath build/AIAllDeviceUnitTests.xcresult -only-testing:BearingsTests \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -test-timeouts-enabled YES DEVELOPMENT_TEAM=9VLNGVF797
xcodebuild build -project Bearings.xcodeproj -scheme Bearings -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath /private/tmp/BearingsAIReleaseDerivedData \
  CODE_SIGNING_ALLOWED=NO
```

Build products, logs and result bundles remain local and ignored. The harmless skipped AppIntents metadata warning persists. UI automation's debugger lookup notices are judged separately from assertion results.

### Current device/runtime limits

- Actual Foundation Models daily/weekly/monthly generation, semantic quality, latency, energy and disconnected-device inference remain unverified because the physical device's model was not ready. Use `FoundationModelsDeviceTests` after Apple Intelligence is enabled/prepared; the six cases in `docs/fixtures/SyntheticJournalEvaluation.json` support later semantic evaluation.
- iOS 17 is the verified compilation/deployment target. No iOS 17 runtime is installed; execution on that OS remains unverified.
- File-backed old-schema migration succeeded on simulator and physical hardware with synthetic stores. Updating the owner's real journal was not used as a migration test.
- Native protection attributes are applied; locked-device, disk-full and abrupt termination timing still require dedicated acceptance testing. In-app corrections and inference never modify original writing.
- This is a local development installation. App Store Connect/distribution access, archive upload, TestFlight processing and beta distribution have not been performed or verified. They require separate owner authorization.

## Emotional-learning planning document checks — October 11, 2026

The planning-only update adds HacklantaPlan.md, EmotionalLearningSpec.md and PitchResearch.md. Checked the twelve ordered step headings, required feature/demo-case coverage, sibling Markdown links, saved Notion sections/native cross-references and the nine new tasks' unchecked Not started status. Verified the retained AI task stays In progress/unchecked, Weekly Summaries now reflects implemented-but-unverified work, and Demo Video/Submit Project remain incomplete. Notion fetches reported no truncation/unknown-block indicators; those fields were absent rather than explicitly false. Existing home, Pitch and iOS Development content was preserved.

No Xcode build, simulator UI test, physical-device inference or app regression test was run for this documentation-only change. The earlier implementation evidence and modelNotReady limitation remain unchanged. New feature acceptance tests described in EmotionalLearningSpec.md are future work, not executed evidence.

## Professional case study and safety assessment — October 11, 2026

Created docs/ProfessionalCaseStudy.md and output/pdf/BearingsProfessionalCaseStudy.pdf as a fictional workplace design case and an evidence-based prototype safety assessment. The proposed lesson and its mixed outcome are authored illustrations, not actual AI responses, participant observations or app-benefit evidence. The owner reports working AI, but this request did not verify actual device generation; the prior modelNotReady skip remains the last recorded physical-model result.

Re-read the existing Xcode result bundles using xcresulttool summaries: AIUnitTestsAcceptance reports 59 passed and 1 skipped out of 60; AIAllDeviceUnitTests reports 53 passed and 1 skipped out of 54; AIUITests reports 15 passed; AIReflectionAX5Final reports 5 passed. All four have zero failures. These are prior executions with overlapping coverage, not newly run or independent safety tests.

Source review checked provider instructions/error handling, CloudKit-disabled store configuration, isolated saves, file protection and source-fingerprint checks. The app source search found no journal network client, analytics SDK, content logger, backup exclusion or separate in-app biometric lock. This is a source review, not a network or device-security audit. Findings: iOS backup behavior needs an explicit policy; completeUntilFirstUserAuthentication does not require unlock on every access; refusals have a generic failure experience; finer emotion/assumption/lesson safeguards remain proposed. Apple and NIST primary references are included in the case study.

Generated the PDF with the bundled Python/ReportLab runtime, rendered all five final pages through bundled Poppler and inspected the page images for clipping, table wrapping, pagination and readable references. The draft's orphaned acceptance section was repaired before final inspection. Text extraction verifies five pages with substantive content and the required fictional/evidence-status labels. git diff --check is part of this documentation validation.

No Xcode build, new app test, physical inference, app change, publication, submission, push or external message was performed. Real output quality and sensitive-content behavior, offline traffic behavior, locked-device/file attributes, backup handling, and proposed learning acceptance remain unverified. Notion synchronization of this local draft is pending.

## Research reference checks — October 11, 2026

ResearchEvidence.md adds 37 sequentially numbered source cards, direct original-source links, a six-source shortlist, feature implications and pitch/evaluation notes. Checked card numbering, source-link presence, sibling Markdown links and Git whitespace. Key intervention statistics and limitations were checked against available original papers/abstracts, including the five-day differentiation trial, null word-learning trial, online adult EI program and its 91-person follow-up, workplace training review, empathy review, progress-monitoring review and breathing study. This was a targeted literature review, not a registered systematic review or independent study-quality audit.

The complete Notion research page was fetched and matched its source after normalization of native mentions, table tags, Markdown formatting and whitespace: 33,740 normalized characters. All 37 source-card headings were present. Scoped links/summaries on the existing Pitch and Bearings home were fetched and verified, preserving prior brainstorming and the technical child. Truncation/unknown-block fields were absent, not explicitly false. No app tests, model inference or journal-data collection were performed for this documentation-only milestone.

## Relationship demo fixture checks — October 11, 2026

Validated `docs/fixtures/RelationshipDemoJournal.json` with Python JSON parsing and assertions: exactly 18 unique UUIDs; exactly 14 consecutive valid civil dates; two full Monday–Sunday weeks with nine entries each; ten single-entry days and four double-entry days; chronological ordering; exact JournalEntry-compatible record field names and native morning/midday/evening period values; valid timezone-aware creation/modification timestamps; nonempty bodies; and creation-zone date consistency. The 1,577 journal words have a maximum entry size of 534 UTF-8 bytes, below the existing 2,400-byte source-segment size. This is a byte-size check, not a model token-budget or generation-quality claim.

Checked all 18 copy-ready Markdown paragraphs against the JSON and checked the saved JSON/Markdown deliverable copies. Verified local document links. Source fixture SHA-256: `d28e50555a1faaf9d0ffb91bad691e684be3c167692cacd096bc67634024534d`. Notion's saved demo page matches the source after normalization of native mentions, table tags/separators, formatting and whitespace: 20,283 normalized characters. All 18 numbered entry headings, prepared-reply labeling and the AI/loading guide are present. The existing Pitch body was preserved exactly below the inserted reference.

No Xcode build, simulator/device test, JSON-to-SwiftData import, phone-store write, actual Apple-model inference, latency measurement or recap/lesson quality test was run for this fixture/documentation-only change. The app has no JSON import UI. Earlier deterministic-provider results and the physical modelNotReady limitation remain as recorded above; they do not validate this story's AI results.

## Professional case study demo load — October 11, 2026

- Built the current `Bearings` Debug scheme for the connected physical iPhone 16 Pro (iOS deployment target 17.0) with `xcodebuild`; build succeeded.
- Installed the signed app and launched it with `--uitesting --reset-test-store --seed-professional-case-study --reduce-motion`. This selected and reset only `Library/Application Support/BearingsUITests/ui-tests.store`; the normal compatibility store was not selected or read.
- After the owner selected Sunday as the first day of the week, rebuilt, reinstalled and reset only the demo store with the revised fixture. After the two-second opening completed, copied the separate demo-store files back from the device and inspected only structural metadata. `ZJOURNALENTRY` contained exactly 14 rows on 14 distinct civil days from `2026-09-27` through `2026-10-10`, with no October 11 entry.
- Relaunched without `--reset-test-store`, copied the demo store again and confirmed it still contained 14 rows with the same day bounds. This verifies the empty-store guard prevented duplicate seeding.
- The launch used the real Apple intelligence provider because neither synthetic-provider argument was supplied. No model generation was requested or semantically reviewed in this check. The installed UI was not visually audited, and iOS 17 execution remains unverified.

### Sunday week-boundary verification

- Ran the complete `BearingsTests` target in the iPhone 16 Pro simulator: 64 tests executed, 63 passed, the real-model device test skipped, and 0 failures. This includes real file-backed migration and read-only save-failure fixtures.
- Unit assertions verify that October 1 belongs to September 27–October 3, October 11 begins a new week, and its review period is October 4–10. Monthly clipping now ends the first October segment on Saturday, October 3.
- Built and launched the Debug app in the simulator with the synthetic demo fixture. Visual inspection confirmed the long timeline tick falls on Sunday, October 11; neighboring days use short ticks.
- Ran the two affected reflection UI tests with the deterministic provider: 2 passed and 0 failed. They verify Sunday prior-week routing, the empty prior-week unavailable case, weekly generation from the seeded October 4–10 fixture, monthly generation and refresh.
- Built, signed, installed and launched the revised Debug app on the connected physical iPhone 16 Pro. The isolated device demo store contains the revised 14-day fixture. Real Foundation Models generation, the proposed lesson feature, and physical-device pixel inspection remain unverified.

## Transient timeline month label — October 11, 2026

- Built the changed Debug app and ran `JournalFlowTests.testMonthTitleAppearsDuringHorizontalScrollThenHides` in the iPhone 16 Pro simulator. The first execution failed because the visible text was combined into its parent button's accessibility element rather than exposed as a separate static text. The control was changed so its accessible label follows the visible state.
- Reran the focused UI test: 1 passed and 0 failed. It verified the resting “Choose date” state, a different month/year label after a horizontal drag, and return to “Choose date” five seconds after the drag ended.
- Rebuilt, signed, installed and launched the Debug app on the connected physical iPhone 16 Pro without resetting the isolated demo store. Compilation, signing, installation and launch succeeded. Physical-device pixel timing and a maximum-Dynamic-Type visual pass remain unverified.

## Summary-first daily reflections — October 11, 2026

- Ran `AnalysisEngineTests` plus `ReflectionFlowTests.testManualFeelingSurvivesRegenerationAndCanReturnToAISuggestion` in the iPhone 16 Pro simulator: 15 focused unit tests and 1 UI test passed with 0 failures. The UI test verifies the “Day summary” content appears above “Notable emotions,” a supported Peace item is exposed accessibly, manual Joy survives regeneration, and returning to the AI suggestion restores Peace.
- Ran the complete `BearingsTests` target in the same simulator: 64 tests executed, 63 passed, the real Foundation Models device test skipped, and 0 failed. The suite includes real file-backed migration and intentional read-only save-failure fixtures. New assertions verify supported primary/secondary emotions, uncertain omission and duplicate removal.
- Built the `Bearings` Debug scheme for the connected iPhone 16 Pro with deployment target iOS 17.0; compilation, signing and validation succeeded. Installed and launched bundle `com.harryhutchins.recollectdemo.ReCollect` with `--uitesting --seed-professional-case-study --reduce-motion`, without `--reset-test-store`, preserving the isolated demo store.
- The installed app uses the real on-device provider, but this verification did not request or inspect a new Foundation Models result. Summary wording, emotion precision, latency, offline behavior and the physical-device layout remain unverified. The owner has reported that Apple Intelligence finished preparing; that report is not a substitute for the skipped hosted model test.
