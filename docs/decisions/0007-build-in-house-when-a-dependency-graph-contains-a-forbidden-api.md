# 0007. Build in-house when a dependency graph contains a forbidden API

- **Date:** 2026-11-07
- **Status:** Accepted

## Maintainer input

> **Maintainer:** To clarify the alternative to using an external package is always building and maintaining our own.

> **Maintainer:** I accept the decision to build our own if an upstream dependency uses a forbidden package.

## Context

Screens need rendering to images in CI. The review of swift-snapshot-testing 1.19.7 found `dlopen`, `dlsym` and `Process` in its transitive graph and an untraced platform-conditional subgraph. The in-house helper costs about the same in tokens as the review alone.

## Decision

swift-snapshot-testing is declined. Snapshot rendering is built in this repository on SwiftUI `ImageRenderer`. As a standing rule, a forbidden API anywhere in a dependency graph declines the dependency and the capability is built here.

## Consequences

The design-system slice proceeds with the in-house helper. Pixel comparison is added when regression detection is needed. The review is in `docs/security/reviews/2026-11-07-swift-snapshot-testing.md`.
