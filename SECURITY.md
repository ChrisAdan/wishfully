# Security Policy

## Reporting a vulnerability

Report vulnerabilities privately through **Security › Report a vulnerability** on this repository. Reports receive a response within a few days.

## Security model

Wishfully holds personal gift lists. These properties protect them:

- **Minimal app supply chain.** The shipped app contains Apple frameworks and code from this repository exclusively. Development tools run in CI.
- **Serverless storage.** Data lives on the device and in the user's iCloud account through CloudKit.
- **Isolated shopper data.** Purchase records live in the shopper's private iCloud database, separate from the recipient's data.
- **Untrusted web content.** The Share extension treats every page as hostile input: it reads a capped portion of each page, applies timeouts, and extracts plain text values. Page scripts remain inert data.
- **Pinned toolchain.** GitHub Actions are pinned to commit SHAs, CI tools are verified against SHA-256 checksums, and container images are pinned by digest.
- **Reviewed updates.** Dependency updates arrive as pull requests after a 7-day cooldown, and the maintainer approves each one.
- **Human-approved releases.** Builds are signed and uploaded from `main` after the maintainer approves the release.
