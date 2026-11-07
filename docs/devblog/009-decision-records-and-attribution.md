# 009 · Decision records and attribution

*November 7, 2026 · Slice 9: decision records, attribution, patterns 26 and 27 · Drafted by Claude for the maintainer*

## From the maintainer

> **Maintainer:** As a note, in the readme you say I author the commit. In actual fact you write the text and I just review and feed back.

> **Maintainer:** For decisions markdown, just generate it for me using the quotes of the actual slice of the prompt that triggered that response. Note somewhere that is how the decisions are logged.

> **Maintainer:** I accept the decision to build our own if an upstream dependency uses a forbidden package.

## Attribution

The README, `CONTRIBUTING.md`, `AGENTS.md` and post 000 state the working arrangement as it is: the agent writes the code, tests, documentation and commit messages; commits carry the maintainer's git identity and an `Assisted-by:` trailer; the maintainer directs, reviews, gives feedback on and approves every change. Decision record 0005 logs it.

## Decision records

`docs/decisions/` holds 13 records, 0001 to 0013, covering every decision made in the build so far. Each record opens with the verbatim excerpt of the maintainer prompt that produced the decision, followed by context, decision and consequences. The folder README states this logging method, and the template follows the same structure. Records are written in the third person, so the first-person check now covers them; the quotes sit in blockquotes, which the style check skips.

## Dependency rule

Step 6 of the dependency sequence in `AGENTS.md` section 2: a forbidden API anywhere in a dependency graph declines the dependency, and the capability is built in this repository. Decision 0007 records the first application: swift-snapshot-testing is declined, and snapshot rendering is built on SwiftUI `ImageRenderer`.

## Patterns 26 and 27

| # | Pattern | Rewrite | CI check |
|---|---|---|---|
| 26 | `All X are done Y. Never Z.` | `All X are done Y.` | A sentence that starts with `Never` |
| 27 | `This is that. No A, no B, no C.` | `This is that.` | A list of the form `no A, no B` |

Row 7 gains the example `An X never does Y. It does Z.`, rewritten as `X does Z.` Probe files confirm both new checks fire.

## Next

The design system and screens, with the in-house snapshot helper.
