# 011 · v0 on the phones

*November 12, 2026 · Slice 11: the app, the Share extension, sync and the TestFlight route · Drafted by Claude for the maintainer*

## From the maintainer

> **Maintainer:** Your task is to one shot this app into v0 - buildable and launched in TestFlight with the add to wishfully button on share for Sabrina and the ability to check an item as bought on my end, and click through to the links.

## What v0 does

| Who | What |
|---|---|
| Sabrina | Creates her list, shares it with the maintainer, adds wishes from any app's Share sheet; title, photo, price and store fill in from the page |
| The maintainer | Sees her list, adds or imports the existing items, ticks items bought, opens each product page in Safari |
| Both | Edit and delete wishes; the list syncs through iCloud |

Bought marks stay in the maintainer's private iCloud database. Sabrina's phone has no copy to show.

## How it is built

- **Two targets.** `App/Wishfully` (the app) and `App/ShareExtension` share `App/Shared`: the page fetcher, the wish form and the CloudKit writer. Logic that runs on Linux sits in `WishfullyCore`: `PageMetadata` reads a page's title, photo and store, `SharedText` splits shared text into a title and a link, and `RecordSchema` names every CloudKit field.
- **Sync.** Decision 0017 explains the move from Core Data to CloudKit directly: Core Data's schema needs a development build on a device, and the maintainer has no Mac. Each list is a zone shared whole; the app reads changes since its last change token.
- **Signing.** Decision 0018: each TestFlight run makes its own distribution certificate through the App Store Connect API and revokes it at the end.
- **Checks.** `ios.yml` compiles the app and the extension with warnings as errors, launches the app in the simulator and keeps a screenshot.

## Importing the note

Apple Notes copies a note in two forms: plain text, which keeps the checklist markers, and rich text, which keeps each item's link. The Import screen's paste takes the plain lines and adds the link of the matching rich-text line (`NoteImporter.addingLinks`). A note that arrives with no markers at all is read in markerless mode: a line with an emoji is a section heading, and every other line is a wish. The preview shows the count of wishes and of links before anything is saved.

## Facts and inferences

| Statement | Confidence |
|---|---|
| `WishfullyCore` tests pass on Linux: 47 tests in 10 suites | 100% |
| Notes on iOS places both a plain-text and a rich-text copy of a note on the pasteboard | 80% |
| SwiftFormat, SwiftLint, jscpd, docs style, forbidden APIs and gitleaks pass locally | 100% |
| The app and extension compile and launch in the simulator | Reported by the `ios` workflow on each push |
| The signing script creates usable profiles once the identifiers in `docs/releases/v0-setup.md` exist | 75% |
| A zone-wide share gives the maintainer read and write access with the default sharing sheet options | 85% |
| Product pages from large stores return a photo and price to the extension | 60% (store-dependent; the fields stay editable) |

## Next

0.0.2: trash, snapshots and restore (decision 0014), the diagnostics screen (0016), accessibility audit tests (0015) and push-driven sync.
