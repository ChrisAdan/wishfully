# 002 · The domain, in pure Swift

*November 7, 2026 · Slice 2: WishfullyCore models · Drafted with Claude, edited by Chris*

## Why the models come next

The data model is the thing everything else depends on: screens display it, storage persists it, sync shares it. It's also the cheapest code to verify, because pure Swift with no UI and no Apple-only frameworks compiles and tests on a free Linux machine in seconds. So it goes first, and it goes into its own package, `WishfullyCore`, which is forbidden from importing anything that would stop it running on Linux.

## What's in the slice

| Type | What it is | The decision inside it |
|---|---|---|
| `Identifier<Owner>` | Type-safe IDs | `Wish.ID` and `Wishlist.ID` are different types, so mixing them up is a compile error. One generic type serves every model, which keeps it DRY |
| `Money` | An amount plus a currency | `Decimal`, never `Double`: binary floating point can't represent 0.1 exactly, and totals drift. A test proves 0.1 + 0.2 = 0.3 |
| `Desire` | Nice to have / would love / dream gift | An enum, so a typo can't compile. Stored as 1–3 |
| `Wish`, `Wishlist` | The recipient's data | Written only by the list owner |
| `ShopperOverlay` | The shopper's private layer: bought status, price fixes, price paid | Lives only in the shopper's iCloud. It links to a wish by ID, because Core Data can't relate objects across the private and shared stores |
| `ShoppingItem` | Wish + overlay, merged | The single type every shopper screen reads from. The shopper's price correction wins over the store's price |
| `ShoppingList` | The whole list in shopper mode | Ordering (most-wanted first, then oldest first, so the list doesn't jump around as wishes arrive) and spend totals that never add dollars to euros |

The "secret by design" idea from the architecture shows up here as types: nothing in `Wish` can say whether it was bought. That information only exists in `ShopperOverlay`, which never leaves the shopper's phone.

## Tests, on Linux

Thirteen tests using Apple's Swift Testing framework, covering JSON round-trips, exact decimal math, currency separation, ordering, the bought/to-buy split, and price-override precedence. One test checks that overlays pointing at wishes the recipient has since deleted are ignored, not counted toward the budget.

CI gains a second job that builds and tests the package in Apple's official Swift container, with **warnings treated as errors**.

## On slice size

This slice is about 300 lines: 8 small source files and 3 test files, one concept (the domain model). That's the target size. It's big enough to be a meaningful step, and small enough that every line can be reviewed in one sitting. Price extraction is closely related but a different concern (parsing hostile web pages), so it gets its own slice.

## What the agent couldn't verify locally

The agent can lint and format Swift in its workspace, and that caught three issues before pushing: a comment style, an overly strict naming rule for `ID`, and a safer way to convert data to text in a test. But it can't compile Swift there, so the first real compile of this code happened in CI. It passed first time: Swift 6.3.3, all 13 tests green.

One follow-up came out of that run: the CI log printed the exact Swift container digest, so the workflow now pins the image by digest instead of by tag. The agent couldn't look that digest up beforehand because Docker Hub is blocked from its workspace, so the first CI run was how we observed it.

## The first flaky failure

The very next run failed, on code that hadn't changed: **SwiftFormat segfaulted** in the Guardrails job. The agent ran the same check 40 times in its own workspace without a single crash. Its machine has 2 cores; the CI runner has 4. That points to a threading bug in SwiftFormat's Linux build when it checks many files in parallel, and SwiftFormat has no switch to turn parallelism off.

The fix isn't to make the check optional or blindly retry the job. Instead, a small script checks **one file per SwiftFormat process**, which removes the tool's internal concurrency entirely. As a backstop, a file whose check *crashes* (exit 139) gets one retry, with a visible warning in the CI log. A real formatting violation is never retried: it still fails the build. The agent verified both paths locally: clean code passes, a badly formatted file fails.

The lesson for agentic work: when a check flakes, the agent shouldn't weaken it to get green. It should find the mechanism, fix that, and leave a trail.

## Next

Slice 3: `PriceExtractor`. Given the HTML of a product page, find the price, if the store publishes one, without trusting anything about the page.
