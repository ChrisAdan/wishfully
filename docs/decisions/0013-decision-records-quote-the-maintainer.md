# 0013. Decision records quote the maintainer

- **Date:** 2026-11-07
- **Status:** Accepted

## Maintainer input

> **Maintainer:** For decisions markdown, just generate it for me using the quotes of the actual slice of the prompt that triggered that response. Note somewhere that is how the decisions are logged.

## Context

Decisions originate in the maintainer's prompts during the build.

## Decision

The agent generates each decision record. A record opens with the verbatim prompt excerpt that produced the decision, then states the context, the decision and its consequences.

## Consequences

The origin of every decision is traceable to the maintainer's words. `AGENTS.md` section 6, `CONTRIBUTING.md` and this folder's README describe the practice.
