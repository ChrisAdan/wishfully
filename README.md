# Wishfully

A cozy iPhone app for gift lists. The recipient adds things from any app's Share sheet. The shopper sees the same list, shops from it and marks items bought, and the surprise stays intact.

**Status:** early development, targeting Christmas 2026. Builds are distributed through TestFlight.

## How it works

- **Add from anywhere.** Sharing a product page to Wishfully captures the photo, the title and, when the store publishes one, the price.
- **One shared list.** The list syncs between two iPhones through iCloud. Apple's CloudKit is the entire backend.
- **Secret by design.** The shopper's bought marks and price notes live in the shopper's private iCloud database, separate from the recipient's list.

## Architecture

Native Swift 6 and SwiftUI, iOS 18 and later. Domain logic lives in `WishfullyCore`, a pure Swift package tested on Linux. Storage is Core Data on the device, synced and shared through CloudKit using Apple's two-store pattern (private and shared). The shipped app contains Apple frameworks and code from this repository exclusively. Decision records in [`docs/decisions`](docs/decisions) explain each choice.

## Design principles

- **Guardrails first.** Formatting, strict linting, duplicate detection and secret scanning gate every change.
- **Pure logic first.** Behavior lives in a Linux-tested package; storage and UI build on top of it.
- **Human authority.** An AI coding agent (Claude) implements under the direction of the maintainer, who authors and approves every commit. Commits carry an `Assisted-by:` trailer. See [CONTRIBUTING.md](CONTRIBUTING.md).
- **Small slices.** Each change is one pull request with one purpose, documented in the [dev blog](docs/devblog).

## Contributor and agent rules

[AGENTS.md](AGENTS.md) holds the project rules: authority, security, engineering, slices and writing style, including a table of AI language patterns and their rewrites.

## Repository layout

```
Packages/WishfullyCore/  Domain models, price extraction, note import (pure Swift)
docs/decisions/          Decision records
docs/devblog/            Build log, one post per slice
.github/                 CI workflows, scripts, Dependabot, code owners
AGENTS.md                Rules for agents and contributors
```

## Security

See [SECURITY.md](SECURITY.md) for the security model and private vulnerability reporting.

## License

[MIT](LICENSE) © 2026 Chris Adan
