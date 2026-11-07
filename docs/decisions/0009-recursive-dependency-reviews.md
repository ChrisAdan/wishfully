# 0009. Recursive dependency reviews

- **Date:** 2026-11-07
- **Status:** Accepted

## Maintainer input

> **Maintainer:** In our evaluation of any external package, perform a cost benefit analysis on recursively tracing dependencies and performing a similar complexity security scan. Any fails propagate to the final report. If we hit a closed source dependency, we abort because we are trustless without independent scrutiny.

## Context

A package's risk includes every package it pulls in, and package manifests run as code during resolution.

## Decision

Every dependency candidate goes through the `AGENTS.md` section 2 sequence: a build-versus-adopt estimate in tokens, a recursive trace, a scan of each package, propagation of every finding, an abort on closed source, a decline on any forbidden API, and maintainer approval with an exact pin.

## Consequences

Reviews follow `docs/security/reviews/TEMPLATE.md`. The token estimate comes first, so a cheap in-house build ends the evaluation early.
