# Wishfully

A cozy iPhone app for gift lists. The recipient adds things from any app's Share sheet. The shopper sees the same list, shops from it and marks items bought, and the surprise stays intact.

**Status:** v0, targeting Christmas 2026. Builds reach two phones through TestFlight; [`docs/releases/v0-setup.md`](docs/releases/v0-setup.md) lists the setup steps.

## How it works

- **Add from anywhere.** Sharing a product page to Wishfully captures the photo, the title and, when the store publishes one, the price.
- **One shared list.** The list syncs between two iPhones through iCloud. Apple's CloudKit is the entire backend.
- **Secret by design.** The shopper's bought marks and price notes live in the shopper's private iCloud database, separate from the recipient's list.

## Architecture

Native Swift 6 and SwiftUI, iOS 18 and later. Domain logic lives in `WishfullyCore`, a pure Swift package tested on Linux. Each list is a CloudKit record zone in its owner's private database, shared whole with the shopper; each phone keeps a local snapshot (decision 0017). The shipped app contains Apple frameworks and code from this repository exclusively. Decision records in [`docs/decisions`](docs/decisions) explain each choice.

## Design principles

- **Guardrails first.** Every change passes formatting, strict linting, duplicate detection, secret scanning and a forbidden-API check before merge.
- **Pure logic first.** Behavior lives in a Linux-tested package; storage and UI build on top of it.
- **Human authority.** An AI coding agent (Claude) writes the code, tests and documentation under the direction of the maintainer, who reviews and approves every change. Commits carry the maintainer's git identity and an `Assisted-by:` trailer. See [CONTRIBUTING.md](CONTRIBUTING.md).
- **Small slices.** Each change is one pull request with one purpose, documented in the [dev blog](docs/devblog).

## Contributor and agent rules

[AGENTS.md](AGENTS.md) holds the project rules: authority, security, engineering, slices and writing style, including a table of AI language patterns and their rewrites.

## Repository layout

```
App/Wishfully/           The iPhone app (SwiftUI)
App/ShareExtension/      The Share sheet's "Wishfully" entry
App/Shared/              Code both targets compile: page fetcher, wish form, CloudKit writer
App/CloudKit/            The CloudKit schema
Packages/WishfullyCore/  Domain models, page and price extraction, note import, record fields (pure Swift)
Tools/                   The app icon generator
docs/decisions/          Decision records
docs/devblog/            Build log, one post per slice
.github/                 CI workflows, scripts, Dependabot, code owners
AGENTS.md                Rules for agents and contributors
```

## Security

See [SECURITY.md](SECURITY.md) for the security model and private vulnerability reporting.

## License

[MIT](LICENSE) © 2026 Chris Adan
