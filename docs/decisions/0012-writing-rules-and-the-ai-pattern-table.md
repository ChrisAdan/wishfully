# 0012. Writing rules and the AI pattern table

- **Date:** 2026-11-07
- **Status:** Accepted

## Maintainer input

> **Maintainer:** Reading the docs and I want to add style rules. No AI bloat if you're writing the copy and do not speak in the first person.

> **Maintainer:** I want all the forbidden text patterns baked in so anybody could benefit from cleaning out the AI bloat from their language.

> **Maintainer:** you should 100% physically isolate your generated outputs into deterministic based on indisputable fact or provable statistical evidence vs inferred and your approximate confidence level expressed as a percentage with a 1 meaning actually deterministic.

## Context

Agent-written text carries recurring patterns: em dashes, negative framing, inversions, filler and emotional emphasis.

## Decision

`AGENTS.md` section 6 defines the voice (third person on behalf of the maintainer, neutral register, positive framing, current state), separates verified statements from inferences with confidence values, and maps 27 default AI language patterns to rewrites. Seven rows run in the `Docs style` CI check.

## Consequences

Every Markdown file passes the check before merge. The table is written for reuse beyond this project.
