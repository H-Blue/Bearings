# Professional case study demo: loading and presentation

The copy-ready source is [`ProfessionalCaseStudyJournal.md`](ProfessionalCaseStudyJournal.md). The machine-readable equivalent is [`fixtures/ProfessionalCaseStudyJournal.json`](fixtures/ProfessionalCaseStudyJournal.json). Both contain the same 14 fictional entries spanning two complete Sunday–Saturday weeks from September 27 through October 10, 2026.

## Installed demo path

A Debug-only launch argument, `--seed-professional-case-study`, loads the fixture when the selected store is empty. Pair it with `--uitesting` so Bearings uses its separate `BearingsUITests/ui-tests.store`, and use `--reset-test-store` only for the first clean load. This keeps fictional judging data separate from the normal journal. The seeder routes every entry through `JournalStore`; it does not write into the SwiftData database directly.

For genuine on-device analysis, omit `--ai-fixture` and `--ai-unavailable`. The fixture contains journal writing only. Daily summaries and weekly reflections must be produced by the Apple model in the app. Do not describe prepared text or synthetic test responses as live model output.

The seeder intentionally does nothing when the selected store already contains entries. This prevents a relaunch from duplicating the story or replacing edits. To start over, explicitly reset the separate test store and seed it again.

## Manual fallback

If the phone cannot be connected or the demo build cannot be installed, enter the paragraphs from the copy-ready document through the normal editor. Set the journal day and time shown in each heading, save, and confirm each entry appears before continuing. Manual entry preserves the civil journal dates but uses the actual paste/save time as creation metadata.

For a staged presentation, load entries 01–07 and capture the September 27–October 3 reflection before adding entries 08–14. October 11 is intentionally empty; select that Sunday and request **Last week** to review the completed October 4–10 period. The automatic seeder loads both weeks at once, which is better for a complete browsing demo. Bearings computes reflections from the requested civil week, so week one remains separate even when week two is already present.

## Honest presenter label

“Alex and Priya are fictional. These journal entries were prepared from the Bearings professional case study. The summaries shown here were generated on this iPhone by Bearings’ on-device model.”

Use the final sentence only after real generation succeeds. Until then say: “The journal is loaded; model output has not yet been verified on this device.”
