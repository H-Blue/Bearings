# Bearings local testing and deployment preparation

Prepared October 11, 2026 from the current project configuration. A signed development build was installed and launched locally; no TestFlight distribution occurred. Exact build, simulator, device and test outcomes are recorded in [Testing.md](Testing.md).

## Current configuration

| Setting | Current value |
| --- | --- |
| Xcode project / shared scheme | `Bearings.xcodeproj` / `Bearings` |
| Minimum iOS version | 17.0 |
| App bundle identifier | `com.harryhutchins.recollectdemo.ReCollect` |
| Display name | Bearings |
| Marketing version / build number | 0.1.0 / 1 |
| Device family | iPhone |
| Signing style / configured team | Automatic / `9VLNGVF797` in Debug and Release |
| Store identity | `ReCollect`, Application Support `ReCollect/Journal.store` |
| Local model | Foundation Models `SystemLanguageModel.default`, gated to iOS 26+ |

The configured team is preserved, including when `Scripts/generate_project.py` refreshes source membership. A team identifier does not prove current membership, usable certificates, provisioning permission or App Store Connect access. The bundle and store identities preserve the existing app's saved journal; changing them is outside routine deployment preparation.

The current environment has Xcode 27.0 / SDK 27. A physical iPhone 16 Pro named Harry's iPhone was discoverable during this milestone. The signed local build was installed and launched, and the complete unit suite ran on this phone. Its Apple model reported `modelNotReady`, so actual generation was skipped; exact results are in Testing.md.

## Local simulator and unsigned compilation

Use the shared scheme and an installed simulator destination. Coordinate build/simulator operations with other active project chats. Refresh project membership after adding source files using the existing generator, then run the relevant unit and UI suites.

```sh
python3 Scripts/generate_project.py
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UUID' \
  -derivedDataPath build/AIDerivedData \
  -resultBundlePath build/AIUnitTests.xcresult \
  -only-testing:BearingsTests -parallel-testing-enabled NO \
  CODE_SIGNING_ALLOWED=NO
xcodebuild test -project Bearings.xcodeproj -scheme Bearings \
  -destination 'platform=iOS Simulator,id=SIMULATOR_UUID' \
  -derivedDataPath build/AIDerivedData \
  -resultBundlePath build/AIUITests.xcresult \
  -only-testing:BearingsUITests -parallel-testing-enabled NO \
  -collect-test-diagnostics never CODE_SIGNING_ALLOWED=NO
xcodebuild build -project Bearings.xcodeproj -scheme Bearings \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath build/AIDeviceDerivedData CODE_SIGNING_ALLOWED=NO
```

Replace the simulator placeholder with a verified available destination and use a new result-bundle path for each run. These commands are a reproducible procedure; their exact execution evidence belongs in Testing.md. An unsigned iOS build checks device compilation and linking but cannot be installed as a signed app or uploaded to TestFlight.

The iOS 17 deployment target preserves journaling compatibility. Testing on a newer simulator does not verify execution on an iOS 17 runtime. The Debug-only `--uitesting --ai-fixture` provider exercises generated-result UI using synthetic local responses; `--uitesting --ai-unavailable` exercises the unavailable experience. Release builds omit these fixtures.

## Physical iPhone verification

For a local development installation, select the connected trusted iPhone in Xcode, verify its Developer Mode and signing access, and use the existing team and bundle identifier. Preserve the installed app and its journal: use an update installation rather than deleting it. Confirm any required device registration/provisioning action before changing account resources.

Use only synthetic writing for model evaluation and debugging. On a compatible iPhone running iOS 26 or later, check runtime availability in the app after Apple Intelligence is enabled and its model is ready. Verify unsupported OS/device states separately. The app should explain unavailability while writing, editing, day reassignment and manual emotion correction continue to work.

Device acceptance should cover:

- Launch artwork timing and interrupted-opening recovery; existing-store initialization and retry.
- Existing journal continuity after update, timestamp/creation-zone display and backdated or moved entries.
- Daily interpretation with primary/secondary emotions, extracted moments and trajectory; correction persistence after regeneration.
- Sunday–Saturday weeks, Sunday prior-week review and month-clipped inputs for a boundary-crossing week.
- Long multilingual/Unicode writing, cancellation while editing/backgrounding, failed generation and retry without lost writing.
- Offline generation on an available model, foreground resumption, keyboard/large text/Reduce Motion and accessible emotion descriptions.
- Native data protection behavior and a review of realistic model latency, energy and semantic output quality.

Do not collect private journal text in console logs, screenshots, diagnostic transcripts or performance exports. A connected eligible phone still needs the actual runtime and model checks above; no real inference result is implied by hardware discovery.

## TestFlight preparation and authorization

The owner authorized implementation and local testing. Implementation pushes, TestFlight upload/distribution, public release, paid services and irreversible changes require separate explicit approval. Credentials do not grant that authorization. No upload or distribution is part of this guide.

Before an authorized TestFlight upload, verify active Apple Developer Program access, the correct team and distribution signing permission, App Store Connect access and an app record using the retained bundle identifier. Check the already-uploaded version/build numbers and select a valid next build number; the current local value `1` is not proof of uniqueness. Prepare beta contact/test details and accurate privacy/export-compliance answers from the finished app.

After local tests and physical verification, create an iOS archive using the Bearings scheme, inspect its signing and validate it in Xcode Organizer. Resolve validation errors before requesting approval for a concrete upload. With approval, choose the intended TestFlight distribution route, upload, and verify App Store Connect processing and the selected tester group. Public App Store submission is a separate action. Apple's distribution guide documents archives, validation, signing, App Store Connect records and beta distribution. [Apple: beta testing and releases](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)

## Outstanding evidence

Existing development signing and a local installation/launch were verified. Actual model generation/quality, signed distribution archives, App Store Connect access and TestFlight status remain unverified. The minimum local handoff is source plus accurate unsigned build/test evidence and a concrete list of remaining device/account actions. It is never a claim of deployment merely because the project has a signing team.

For hosted physical unit/model checks, use the generated `BearingsDeviceTests` scheme. It omits the separate UI-runner target and selects the Debug test store for the host. The full Bearings scheme initially lacked a physical UI-runner provisioning profile; no account resource was created. Build signed outputs outside Documents if its file provider adds Finder metadata that invalidates signing. See Testing.md for the successful `/private/tmp` commands and model-readiness skip.
