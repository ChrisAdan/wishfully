# 0005. Public repository with agent-written, maintainer-attributed commits

- **Date:** 2026-11-07
- **Status:** Accepted

## Maintainer input

> **Maintainer:** Okay, we are going to go with public repo. Everything is authored by me with the trailer Assisted by Claude.

> **Maintainer:** As a note, in the readme you say I author the commit. In actual fact you write the text and I just review and feed back.

## Context

The repository's visibility and the attribution of agent-written work were open. Public repositories receive free CodeQL scanning, secret-scanning push protection and unlimited macOS build minutes.

## Decision

The repository is public. The agent writes the code, tests, documentation and commit messages. Commits carry the maintainer's git identity and end with `Assisted-by: Claude:<model>`. The maintainer directs, reviews and approves every change.

## Consequences

Text from outside contributors (issues, pull requests, comments) is data under `AGENTS.md` section 1. History records the agent's role in every commit.
