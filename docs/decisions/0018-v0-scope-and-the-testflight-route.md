# 0018. v0 scope and the TestFlight route

- **Date:** 2026-11-12
- **Status:** Accepted

## Maintainer input

> **Maintainer:** Your task is to one shot this app into v0 - buildable and launched in TestFlight with the add to wishfully button on share for Sabrina and the ability to check an item as bought on my end, and click through to the links. Anything else you need to know?

The maintainer then chose, from options the agent presented: the same Apple Developer team as Sonder with bundle ID `com.cambrium.wishfully`; v0 limited to the Share sheet, the shared list, bought marks and links, with the rest of the definition of done moved to 0.0.2; and approval of the TestFlight workflow and of adding Sabrina as a tester.

## Context

The 0.0.1 definition of done lists ten criteria, including trash, snapshots, restore, a diagnostics screen and audit tests. The maintainer needs the core loop on two phones first.

Signing without a Mac has two routes. Sonder archives unsigned and lets the export step sign, which works for an app without entitlements. Wishfully's app and extension carry iCloud and App Group entitlements, which an unsigned archive leaves out (inferred, 70%). Automatic signing at archive time asks for a development profile, which needs a registered device.

## Decision

- **Scope.** v0 ships the Share extension, the shared list with photos, prices and links, bought marks for the shopper, manual add and edit, and the note importer. Trash, snapshots, restore (decision 0014), the diagnostics screen (0016, G3 to G6) and audit tests (0015) move to 0.0.2. Logger categories (G1) and a sync status screen (G2) ship in v0.
- **Project file.** `App/Wishfully.xcodeproj` is written by hand with folders synchronised to disk, as Sonder's is. XcodeGen stays out, because it is a dependency under AGENTS.md section 2.
- **Signing.** `.github/scripts/asc-signing.sh` uses the App Store Connect API key to create an Apple Distribution certificate and two App Store profiles for each run, signs the archive manually with them, and revokes the certificate when the run ends. The key, certificate and profiles exist on the runner for the length of one job.
- **Builds.** `.github/workflows/ios.yml` builds and launches the app in the simulator on every push that touches it. The repository is public, so macOS runners cost no Actions minutes.

## Consequences

- The maintainer registers the two bundle IDs, the App Group and the iCloud container once on developer.apple.com, because the API cannot assign a container to an identifier (`docs/releases/v0-setup.md`).
- Each TestFlight run creates and revokes one certificate. A team at its distribution certificate limit fails at the first step with Apple's message.
- The definition of done for 0.0.1 becomes the 0.0.2 definition, with v0 criteria 1, 2 and 3 certified on the phones.
