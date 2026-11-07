# 0001. Native iPhone app, built in the cloud

- **Date:** 2026-11-06
- **Status:** Accepted

## Maintainer input

> **Maintainer:** I don't have a Mac. There is no way to proceed?

> **Maintainer:** I approve the native app public repo approach. It's fine. We call it the app Wishfully.

## Context

iOS apps compile on macOS, and the maintainer works without a Mac. The options were a native app built on cloud Macs, a rented Mac, or a web app with a Shortcut for the Share sheet.

## Decision

Wishfully is a native Swift and SwiftUI app named Wishfully. Builds run on GitHub-hosted macOS runners and reach phones through TestFlight.

## Consequences

All compilation and testing happen in CI. Feedback arrives through CI logs, rendered screenshots and TestFlight installs, so pure logic lives in a Linux-tested package and the UI is verified through rendered images.
