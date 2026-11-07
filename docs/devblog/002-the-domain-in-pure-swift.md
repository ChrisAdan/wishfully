# 002 · The domain, in pure Swift

*November 7, 2026 · Slice 2: WishfullyCore models · Drafted by Claude for the maintainer*

## Why the models come next

Every other part of the app depends on the data model: screens display it, storage persists it, sync shares it. It is also the cheapest code to verify. Pure Swift with Foundation alone compiles and tests on a Linux machine in seconds. So it lives in its own package, `WishfullyCore`, restricted to code that runs on Linux.

## What the package holds

| Type | Role | The decision inside it |
|---|---|---|
| `Identifier<Owner>` | Type-safe IDs | `Wish.ID` and `Wishlist.ID` are distinct types, so the compiler catches a mix-up. One generic type serves every model (DRY) |
| `Money` | An amount plus a currency | `Decimal` keeps cents exact; a test proves 0.1 + 0.2 = 0.3 |
| `Desire` | Nice to have, would love, dream gift | An enum, stored as 1 to 3, so every value is valid by construction |
| `Wish`, `Wishlist` | The recipient's data | Written by the list owner |
| `ShopperOverlay` | Purchase status, price corrections, price paid | Stored in the shopper's private iCloud database and linked to a wish by ID, the pattern Core Data uses across private and shared stores |
| `ShoppingItem` | Wish and overlay, merged | The single type behind every shopper screen; the shopper's price correction takes precedence |
| `ShoppingList` | The whole list in shopper mode | Most-wanted first, then oldest first, so the order stays stable as wishes arrive; spend totals kept per currency |

"Secret by design" is expressed in the types: purchase information exists in `ShopperOverlay` alone, and that type stays on the shopper's side.

## Tests

Thirteen tests in Apple's Swift Testing framework cover JSON round trips, exact decimal math, currency separation, ordering, the bought and to-buy split, price-override precedence, and overlays that reference wishes the recipient has removed.

A second CI job builds and tests the package in the official Swift container (Swift 6.3.3), pinned by digest, with warnings treated as errors.

## Formatting check design

The format check runs SwiftFormat one file per process. SwiftFormat's Linux build segfaults intermittently when it lints many files in parallel on multi-core runners, and per-file runs avoid that concurrency. A check that crashes (exit code 139) retries once and records a warning in the CI log. A formatting violation fails the build.

## Slice size

About 300 lines: eight small source files and three test files, one concept. This is the target size: a meaningful step that fits a single review sitting. Price extraction is a separate concern (parsing hostile web pages), so it gets its own slice.

## Verification

The agent formats and lints in its workspace before pushing. Compilation and tests run in CI, where all 13 tests pass.

## Next

Slice 3: `PriceExtractor`, which reads the price from a product page.
