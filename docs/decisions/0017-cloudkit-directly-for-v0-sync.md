# 0017. CloudKit directly for v0 sync

- **Date:** 2026-11-12
- **Status:** Accepted

## Maintainer input

> **Maintainer:** Your task is to one shot this app into v0 - buildable and launched in TestFlight with the add to wishfully button on share for Sabrina and the ability to check an item as bought on my end, and click through to the links.

> **Maintainer:** I have the list I can import it or add the items by hand one by one, or go on iCloud on my laptop to get the actual URLs

## Context

Decision 0002 chose Core Data with `NSPersistentCloudKitContainer`. That container needs its CloudKit schema in the Production environment before a TestFlight build can sync, and TestFlight builds use Production: Apple applies the `iCloudContainerEnvironment` export option to non-App Store exports exclusively. Core Data generates its schema from a development-signed build running on a device signed in to iCloud. The maintainer works without a Mac, so that build has no route to a device.

Options:

| Option | Schema source | Fit |
|---|---|---|
| Core Data mirroring | A development build on a device | Blocked without a Mac |
| Core Data, schema written by hand | Reverse-engineered `CD_` record types | Undocumented format; a mismatch fails silently |
| CloudKit directly | `App/CloudKit/schema.ckdb`, written here | Imported by `cktool` on macOS CI, deployed from the CloudKit Console in a browser |

## Decision

v0 syncs through CloudKit directly. Each list is a record zone in its owner's private database, shared whole through a zone-wide `CKShare` with read and write permission, so the maintainer can add the existing items. The shopper's bought marks are `Overlay` records in a `Shopper` zone of the shopper's private database, which keeps decision 0003's privacy layout. Each phone keeps a JSON snapshot and the product photos in the App Group folder, so lists open before iCloud answers. Record field names live in `RecordSchema` in `WishfullyCore`, tested on Linux.

## Consequences

- Decision 0002 is superseded for v0. `WishRepository`-style storage behind a protocol remains possible later.
- Sync is pull-based: the app reads changes on launch, on return to the foreground, on pull-to-refresh and every 60 seconds while open. Push subscriptions wait for a later slice.
- The Share extension writes to CloudKit itself. When iCloud is unreachable it keeps the wish in the App Group inbox, and the app sends it on the next sync.
- Concurrent edits resolve as last writer wins per field. Two people writing one list makes this rare.
- A schema change adds fields; Production keeps every deployed field. Renames are schema changes.
