# 0010. Test policy: one test per behavior

- **Date:** 2026-11-07
- **Status:** Accepted

## Maintainer input

> **Maintainer:** What are we doing to control test proliferation in the codebase? We don't cut corners as a builder but we do measure twice cut once. Twice, not 7 times. Optimize your criteria for deciding when to create a new test vs adapt an existing test for reusability.

## Context

The suite had grown to 49 test functions, several testing one behavior with different inputs.

## Decision

Each test protects one behavior. New inputs become cases of an existing parameterized test; a new test is written for a new behavior. CI reports coverage, and a consolidation keeps coverage equal or higher.

## Consequences

The first consolidation took the suite from 49 to 37 test functions at an unchanged 96.44% line coverage.
