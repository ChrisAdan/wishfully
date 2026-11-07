# 001 · Guardrails before code

*November 7, 2026 · Slice 1: core CI pipeline · Drafted with Claude, edited by Chris*

## Why this comes before any app code

Neither the agent nor I can run the app locally, so CI is the only place we find out whether code is right. If the guardrails arrive after the code, the first code gets written without them and then has to be retrofitted. So the pipeline lands in an empty repo, and every line of Swift written from here on has to pass it.

## What runs on every push

One Linux job called **Guardrails**, finishing in about a minute:

| Check | Tool | What it catches | Python equivalent |
|---|---|---|---|
| Format | SwiftFormat | Any file not in canonical style | `ruff format --check` |
| Lint | SwiftLint (strict) | Force unwraps, force casts, `try!` and other crash-prone patterns, all as hard errors | `ruff check` |
| Duplication | jscpd | Copy-pasted Swift blocks above 1% of the codebase. This is the DRY rule, enforced by a machine | (no common equivalent) |
| Secrets | gitleaks | API keys or certificates anywhere in the **entire git history** | `detect-secrets` |

Swift compilation and tests join this workflow in the next slice, together with the first Swift package. A test step with nothing to test is just noise.

## Supply-chain choices, explained

This is a public repo whose output lands on my wife's phone, so how the CI gets its tools matters as much as which tools it runs.

- **Only one third-party action, and it's GitHub's own:** `actions/checkout`, pinned to an exact commit hash rather than a tag. A tag can be moved to point at different code; a commit hash can't.
- **Tools are downloaded, not "actioned."** Instead of convenience actions maintained by strangers, a small script downloads each tool's official release and **verifies its SHA-256 checksum** before running it. If a release were ever swapped for a malicious one, the build would fail instead of executing it. Versions and checksums live in one file, `.github/scripts/install-tools.sh`.
- **The one npm tool (jscpd) installs with `--ignore-scripts`,** which blocks the install-time scripts that most npm supply-chain attacks rely on.
- **Least privilege:** the workflow token can only read the repo, and checkout doesn't leave credentials behind.
- **Dependabot proposes updates to the pinned actions weekly,** each after a 7-day cooldown, and nothing auto-merges. Every bump is a pull request I approve.

## What the agent verified before pushing

The lint tools have Linux builds, so the agent ran the whole guardrail suite in its own workspace first. It confirmed the checksum script works, that SwiftLint really does fail a file containing a force unwrap, and that a clean file passes. Two findings from that dry run:

1. **SwiftLint refuses to run on a repo with no Swift files.** That's the right default for a real project, but wrong for an empty one. The fix is one config line, with a comment saying why.
2. **The Linux SwiftLint binary can't use SourceKit,** so a handful of rules that need the compiler's help are skipped on Linux. They'll run on the macOS job once the app exists.

Finding those locally cost seconds; finding them in CI would have cost a push-and-wait cycle each.

## What I still have to do by hand

The agent's GitHub connection can't change repository settings, which is a sensible limit for an AI. So these switches are mine to flip:

- **Branch protection:** require the Guardrails check before anything merges to `main`.
- **Security features:** private vulnerability reporting, secret-scanning push protection, Dependabot alerts.

## Next

Slice 2: `WishfullyCore`, the first Swift package. It holds the data models, with tests running on Linux in CI.
