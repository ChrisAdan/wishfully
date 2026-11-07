# 0003. Single-writer sharing with private shopper data

- **Date:** 2026-11-06
- **Status:** Accepted

## Maintainer input

> **Maintainer:** Auto detect from page and fallback is I can look and do the CRUD click ops

> **Maintainer:** In fact we are not even using any kind of purchase record with real sensitive data. At most, it's a checklist of 'I bought this item'.

## Context

The shopper marks items bought and corrects prices. Writes from a share participant are a reported weak spot in CloudKit sync, and bought marks must stay hidden from the recipient.

## Decision

The recipient is the single writer of the shared list. The shopper's bought marks and price notes live in a `ShopperOverlay` in the shopper's private iCloud database, linked to each wish by ID.

## Consequences

Bought marks stay private through the storage layout. Shopper data is low-sensitivity checklist data. The recipient sees prices as entered; the shopper's corrections stay with the shopper.
