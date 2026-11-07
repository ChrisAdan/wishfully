# 0004. App contents limited to Apple frameworks and project code

- **Date:** 2026-11-06
- **Status:** Accepted

## Maintainer input

> **Maintainer:** If this becomes a public thing it becomes a target for bad actors. The news is full of cases. I could inadvertently be loading a backdoor onto my wife's phone.

## Context

The app runs on a family member's phone. Third-party code in the app binary is the most direct path for a supply-chain compromise to reach the device.

## Decision

The shipped app contains Apple frameworks and code from this repository exclusively. Development and test tools run in CI.

## Consequences

Capabilities such as HTML scanning and price parsing are implemented in `WishfullyCore`. Releases require the maintainer's approval in a protected environment.
