# 0019. The shopper may own the list

- **Date:** 2026-11-13
- **Status:** Accepted

## Maintainer input

> **Maintainer:** Well I don't want to make her have to upload it, feasible?

> **Maintainer:** Yep, I wanna just do it for her

## Context

Decision 0003 made the recipient the single writer and owner of the list, so the recipient creates it and shares it with the shopper. The maintainer prefers to set the list up for the recipient: create it, import the existing note and send the link, leaving the recipient one tap.

## Decision

A list records whom it is for. `Wishlist.recipient` (CloudKit field `recipient`) holds the recipient's name when the owner made the list on their behalf, and stays empty when the owner keeps the list for themselves. Each phone derives its role from that field and the database scope: the shopper is the owner of a list made for someone else, or a participant in a self-kept list. The shopper sees bought checkboxes; the recipient sees the list without them. Both may add, edit and delete wishes, and the recipient's Share button adds to the list made for them.

## Consequences

- Bought marks stay private in both layouts: they live in the shopper's private database, outside the list's shared zone (decision 0003's storage layout holds).
- Decision 0003's single-writer rule is relaxed; the recipient writes as a share participant with read and write permission.
- The schema gains one field, imported by the `cloudkit-schema` workflow and deployed to Production by the maintainer.
