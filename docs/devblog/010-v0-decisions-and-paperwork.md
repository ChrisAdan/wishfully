# 010 · v0 decisions and paperwork

*November 7, 2026 · Slice 10: data safety, accessibility, diagnostics, paperwork drafts, usage log · Drafted by Claude for the maintainer*

## From the maintainer

> **Maintainer:** For data safety, can we rely on iCloud backups? Do we need additional redundancy?

> **Maintainer:** I approve DS2,4,5,6,7 at the proposed version numbers.
> I approve A1-10 at the proposed version numbers.
> Your proposed diagnostic optimizations are accepted in the sequence you propose. You are cleared to draft the paperwork

> **Maintainer:** You are always to report on your own usage periodically. Keep a running log of expense, although this is a pro plan so it's not API rates.

## Decision matrices

The maintainer received a decisions document with one matrix per area. Each row carried an ID, a cost in agent requests converted to two model prices, a recommendation and an empty call column. The calls became three records:

| Record | Area | v0 | v1 |
|---|---|---|---|
| 0014 | Data safety | Trash, daily snapshots, restore, round-trip test | Snapshot copy in iCloud Drive |
| 0015 | Accessibility | VoiceOver, Larger Text, contrast, dark appearance, color independence, Reduce Motion, audit tests, snapshots | Voice Control labels, App Store labels |
| 0016 | Diagnostics | Logging, sync recorder, MetricKit capture, extension log, diagnostics screen, integrity check | Signposts, crash counts in CI |

## Why sync is treated as replication

CloudKit copies every change, deletions included, to both phones, and device backups exclude data already stored in iCloud. Recovery therefore lives inside the app: deletes go to a 30-day trash, and each phone keeps 14 daily snapshots that a restore writes back as fresh records.

## Paperwork drafts

`docs/releases/paperwork/` holds the export compliance entry, a privacy manifest for the app and one for the Share extension, a v1 privacy policy, and the expected App Privacy and age rating answers. The maintainer confirms each answer at submission.

## Definition of done

`docs/releases/0.0.1-definition-of-done.md` lists ten criteria, each certified inside the development boundary before any deploy step. Its status is Proposed until the maintainer approves it.

## Usage log

`docs/usage/log.md` records measured agent usage per session segment with API-equivalent prices for one Anthropic model and one open-weight model. The maintainer's Claude Pro subscription is the actual cost; the dollar figures support build-versus-adopt estimates.
