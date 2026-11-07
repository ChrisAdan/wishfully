# 001 · Guardrails first

*November 7, 2026 · Slice 1: core CI pipeline · Drafted by Claude for the maintainer*

## Why guardrails lead

CI is the place where code proves itself on this project. Landing the pipeline before any app code means the first line of Swift and every line after it meet the same standard.

## What runs on every push

The **Guardrails** job runs on Linux in about a minute:

| Check | Tool | What it enforces | Python equivalent |
|---|---|---|---|
| Format | SwiftFormat | Canonical style in every Swift file | `ruff format --check` |
| Lint | SwiftLint (strict) | Safe optional handling: force unwraps, force casts and `try!` are errors | `ruff check` |
| Duplication | jscpd | Duplicated Swift stays under 1% of the codebase, which enforces DRY | |
| Secrets | gitleaks | A clean secret scan across the entire git history | `detect-secrets` |
| Docs style | `docs-style.py` | The CI rows of the pattern table in `AGENTS.md` | |
| Forbidden APIs | `forbidden-apis.py` | Zero process execution and zero dynamic evaluation in project code | `bandit` (partial) |

## Supply-chain design

The output of this pipeline lands on a family member's phone, so the way CI obtains its tools is part of the security model.

- **One action, from GitHub:** `actions/checkout`, pinned to a commit hash. Commit hashes are immutable, which makes the pin exact.
- **Verified downloads:** each tool comes from its official release and passes a SHA-256 checksum check before it runs. A mismatch fails the build. Versions and checksums live together in `.github/scripts/install-tools.sh`.
- **Script-free npm install:** jscpd installs with `--ignore-scripts`, which blocks install-time scripts, the usual vector for npm supply-chain attacks.
- **Least privilege:** the workflow token is read-only, and checkout keeps credentials out of the workspace.
- **Reviewed updates:** Dependabot proposes updates to the pinned actions weekly, after a 7-day cooldown. The maintainer approves each one.

## Local verification

SwiftFormat, SwiftLint and gitleaks all have Linux builds, so the agent runs the guardrail suite in its workspace before each push. The suite confirms that SwiftLint rejects a force unwrap and accepts clean code. The Linux build of SwiftLint runs without SourceKit, so the SourceKit-backed rules run in the macOS job that arrives with the app target.

## Repository settings

Repository settings belong to the maintainer: branch protection with the Guardrails and WishfullyCore tests checks required on `main`, private vulnerability reporting, secret-scanning push protection and Dependabot alerts.

## Next

Slice 2: `WishfullyCore`, the domain model in pure Swift.
