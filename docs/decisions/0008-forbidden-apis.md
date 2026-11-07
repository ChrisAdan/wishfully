# 0008. Forbidden APIs

- **Date:** 2026-11-07
- **Status:** Accepted

## Maintainer input

> **Maintainer:** As a rule, we do not use subprocess or any other dangerous package. Similar to the eval() risk. Make that  hard rule and scrape it out of the codebase. We never expose ourselves inadvertently.

## Context

Process execution and dynamic evaluation turn data into commands. The docs-style checker used `subprocess`.

## Decision

Project code executes zero external processes and evaluates zero dynamic code. `AGENTS.md` section 2 lists the APIs for Swift, Python and shell, and the `Forbidden APIs` CI check enforces it.

## Consequences

CI scripts use the Python standard library alone. The same list is part of every dependency scan (decision 0009).
