# 0011. Token-based estimates

- **Date:** 2026-11-07
- **Status:** Accepted

## Maintainer input

> **Maintainer:** Estimating milestones with time as the unit of work is essentially meaningless. Instead, estimate token I/o and estimated rates at various API or open prices.

## Context

Agent work consumes tokens; elapsed time depends on scheduling and review latency.

## Decision

Work is estimated in requests and tokens (fresh input, cache write, cache read, output), priced at current list rates for at least one Anthropic model and one open-weight model, with the price date. Measured usage calibrates estimates.

## Consequences

The dossiers carry token estimates per milestone. Build-versus-adopt decisions compare token costs (decision 0009).
