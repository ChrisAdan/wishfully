# 0014. Data safety layers beyond iCloud sync

- **Date:** 2026-11-07
- **Status:** Accepted

## Maintainer input

> **Maintainer:** For data safety, can we rely on iCloud backups? Do we need additional redundancy?

> **Maintainer:** I approve DS2,4,5,6,7 at the proposed version numbers.

## Context

CloudKit sync replicates deletions and edits to every device. Apple excludes data already stored in iCloud from device iCloud Backup, and restoring an older local Core Data store does not reliably regenerate the CloudKit records. iCloud sync therefore provides availability across the two phones, and recovery needs its own layer.

Options presented (IDs from the v0.0.1 decisions document):

| ID | Option | Target |
|---|---|---|
| DS1 | iCloud sync alone | Baseline |
| DS2 | Trash with 30-day recovery; deletes are soft | v0 |
| DS3 | Manual export to Files as JSON and Markdown | Declined |
| DS4 | Automatic rolling snapshots in the App Group container, 14 daily kept | v0 |
| DS5 | Copy of each snapshot in the app's iCloud Drive folder, visible in Files | v1 |
| DS6 | Restore from a snapshot with a preview, writing fresh records so CloudKit receives them | v0 |
| DS7 | Round-trip test: snapshot then restore equals the original, in `WishfullyCore` on Linux | v0 |

## Decision

v0 ships DS2, DS4, DS6 and DS7. v1 adds DS5. DS3 stays out of scope.

## Consequences

- Each phone holds the live store, a trash and 14 daily snapshots. The snapshots also sit inside each phone's encrypted iCloud Backup (inferred, 80%).
- DS6 restores from DS4 snapshots in v0 and from DS5 copies in v1.
- The snapshot format and its round-trip test live in `WishfullyCore`, so they run on Linux CI.
- Snapshots contain real list content and stay on the phones and in iCloud. The repository holds invented fixtures exclusively.
- A request for an export outside the app reopens DS3.
