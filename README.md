# Wishfully

A small, cozy iPhone app for gift lists. One person adds things they'd love from any app's Share sheet; the person shopping for them sees the list, shops from it, and marks things bought, without ever spoiling the surprise.

> **Status:** early development, building toward Christmas 2026. Not yet on the App Store.

## How it works

- **Add from anywhere.** Share a product page to Wishfully. It picks up the photo, title and (when the store publishes it) the price.
- **One shared list.** The list syncs between two iPhones through iCloud. There is no Wishfully server.
- **Secret by design.** Whatever the shopper records (bought, wrapped, price paid) lives only in the shopper's own iCloud, so it can never appear on the recipient's phone.

## Architecture in one paragraph

Native Swift 6 / SwiftUI, iOS 18+. Logic lives in a pure Swift package (`WishfullyCore`) that is tested on Linux. Storage is Core Data on device, synced and shared with CloudKit using Apple's two-store (private + shared) pattern. The app ships **no third-party code**: only Apple frameworks and this repository. See [`docs/decisions`](docs/decisions) for the reasoning behind each choice.

## Building in the open

This project is built with an AI coding agent (Claude) under human direction. Every commit is authored and reviewed by a human and carries an `Assisted-by:` trailer. The policy is in [CONTRIBUTING.md](CONTRIBUTING.md). The build is narrated slice by slice in the [dev blog](docs/devblog).

## Repository layout

```
docs/decisions/   Decision records: why things are the way they are
docs/devblog/     Build log, one post per slice of work
.github/          CI workflows, Dependabot, code owners
```

More directories (`Packages/`, `App/`, `ShareExtension/`) arrive as the build progresses.

## Security

See [SECURITY.md](SECURITY.md) to report a vulnerability.

## License

Copyright © 2026 Chris Adan. All rights reserved. A license has not been chosen yet; until one is added, no rights to reuse this code are granted.
