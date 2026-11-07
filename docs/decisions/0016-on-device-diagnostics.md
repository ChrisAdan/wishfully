# 0016. On-device diagnostics

- **Date:** 2026-11-07
- **Status:** Accepted

## Maintainer input

> **Maintainer:** Propose diagnostics optimizations.

> **Maintainer:** Your proposed diagnostic optimizations are accepted in the sequence you propose.

## Context

Development runs without a Mac, so the phone and CI are the only places to observe the app. Diagnostic data that includes list content stays on the phone until the maintainer exports it.

## Decision

Built in this sequence:

| ID | Item | Target |
|---|---|---|
| G1 | `Logger` categories (store, sync, share, import, extraction) with private-by-default interpolation | v0 |
| G2 | Sync recorder for CloudKit setup, import and export events, with "last synced" in Settings | v0 |
| G3 | MetricKit subscriber that writes each `MXDiagnosticPayload` to disk as JSON before parsing | v0 |
| G4 | Share extension event log in the App Group | v0 |
| G5 | Diagnostics screen with recent log entries, G2 to G4 records and export through the Share sheet | v0 |
| G6 | Launch integrity check: record counts, orphaned overlay entries, duplicate IDs | v0 |
| G7 | Signposts around extraction, import and launch | v1 |
| G8 | Nightly CI job reading TestFlight crash and feedback counts through the App Store Connect API | v1 |

## Consequences

- Exports contain event codes, counts and timings. Wish titles, links, notes and prices are logged as private values.
- G8 reports counts and build numbers in CI, and crash content stays in App Store Connect, because workflow output of a public repository is readable by others (inferred, 80%).
- The privacy manifest and App Privacy answers reflect on-device diagnostics: nothing leaves the phone without a maintainer action.
