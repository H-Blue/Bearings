# Bearings verification

Run on October 10, 2026 using Xcode 27.0 (27A266a), Swift 6.4 compiler in Swift 5 language mode, and the iOS 27 SDK. The deployment target is iOS 17.

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

## Limits

- No physical iPhone was attached or tested. Device signing, actual locked-device file protection, haptics, and real-device animation performance remain unverified.
- iOS 17 is validated as the compilation/deployment target; an iOS 17 runtime is not installed here.
- There is no application network client, cloud sync, analytics SDK or AI request path. Offline capability is supported by source inspection and local-store execution; a disconnected physical-device session has not been performed.
- Abrupt termination before the 350 ms debounce or a failed disk save can leave the newest draft unpersisted. Done and inactive/background transitions request immediate saves, and the editor retains failed drafts while open. Repeated failure will not be presented as saved.
- File-backed read-only fixtures verified failed-save/delete isolation and repeated retries. Recovery from a real disk-full or locked-device failure, and its complete UI presentation, still require device-level testing.
- Automated navigation checks establish working routes and reverse context. Final animation feel and frame-rate profiling require owner/device review.
