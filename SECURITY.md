# Security Policy

## Reporting a vulnerability

Please **do not open a public issue** for security problems. Use GitHub's private reporting instead: **Security › Report a vulnerability** on this repository. You'll get a response within a few days.

## What we protect

Wishfully holds personal gift lists. Its security model:

- **No third-party code in the app.** The shipped app contains only Apple frameworks and code from this repository. Development tools run in CI only.
- **No Wishfully server.** Data lives on the user's device and in their own iCloud account (CloudKit).
- **Shopper data is isolated.** A shopper's purchase records are stored only in the shopper's private iCloud database.
- **Untrusted web content.** The Share extension treats every web page as hostile: it never executes page scripts, enforces size limits and timeouts, and only extracts plain text values.
- **Supply chain.** GitHub Actions are pinned to commit SHAs; dependency updates arrive as reviewed pull requests after a cooldown period; nothing merges automatically.
- **Releases require a human.** Builds are signed and uploaded only from `main`, only after the maintainer approves the release.
