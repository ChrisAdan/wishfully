# 008 · Tests, dependencies and token estimates

*November 7, 2026 · Slice 8: test policy, coverage, recursive dependency reviews · Drafted by Claude for the maintainer*

## From the maintainer

> **Maintainer:** What are we doing to control test proliferation in the codebase? We don't cut corners as a builder but we do measure twice cut once. Twice, not 7 times.

> **Maintainer:** In our evaluation of any external package, perform a cost benefit analysis on recursively tracing dependencies and performing a similar complexity security scan. Any fails propagate to the final report. If we hit a closed source dependency, we abort because we are trustless without independent scrutiny.

> **Maintainer:** Estimating milestones with time as the unit of work is essentially meaningless. Instead, estimate token I/o and estimated rates at various API or open prices.

> **Maintainer:** The word gates. I don't like it.

## Test policy

`AGENTS.md` section 3 defines the rule: each test protects one behavior, and new inputs for a covered behavior become cases of the existing test. The deciding question for any new test is which existing test fails if the behavior breaks.

CI reports line coverage and the test count for `WishfullyCore` on every run, in the log and the job summary.

### Measured consolidation

| Measure | Before | After |
|---|---|---|
| Test functions | 49 | 37 |
| Line coverage | 96.44% | 96.44% |
| Region coverage | 92.81% | 92.81% |
| Inputs exercised | all | all, as named cases |

Link parsing (7 tests) and price extraction (9 tests) each became one table-driven test plus one test for a distinct behavior: the importer integration and the JSON depth limit. Both coverage reports come from CI runs on the same pull request, one per commit.

## Dependency reviews

Section 2 of `AGENTS.md` makes every dependency evaluation a six-step sequence: a build-versus-adopt estimate in tokens, a recursive trace of the full graph, a scan of every package, propagation of every finding to the verdict, an abort on closed source, and maintainer approval with an exact pin. `docs/security/reviews/TEMPLATE.md` carries the structure.

The swift-snapshot-testing review applies the sequence. The `SnapshotTesting` target itself rates low risk (90%). The traced graph contains `dlopen` and `dlsym` (xctest-dynamic-overlay) and `Process` (swift-syntax developer tools), both on the forbidden list, plus an untraced platform-conditional subgraph on macOS. The token estimate puts the in-house alternative (a render-to-PNG helper on SwiftUI `ImageRenderer`) at about 20 requests, close to the review cost, with zero recurring update reviews. The propagated verdict recommends the in-house helper (80%); the maintainer accepted it (decision 0007).

## Token estimates

Section 7 of `AGENTS.md` sets the unit of estimation: requests, input tokens (fresh, cache write, cache read) and output tokens, priced at current list rates for an Anthropic model and an open-weight model. The project dossiers carry the first estimates, calibrated on measured usage.

## Pattern row 25

The word `gate` joins the CI-enforced patterns. Rewrites: `enables`, `unblocks`, `allows`, `requires`.

## Next

Slice 9: decision records and attribution.
