# Agent usage log

Measured agent usage per session segment. Dollar figures are API list-price equivalents, used for build-versus-adopt estimates (AGENTS.md section 7). The maintainer's account is a Claude Pro subscription, so actual spend is the flat subscription fee; usage counts against the plan allowance.

Prices per million tokens, checked 2026-11-07:

| Model | Input | Cache write (1h) | Cache read | Output |
|---|---|---|---|---|
| Opus 5.5 | $4 | $8 | $0.20 | $20 |
| DeepSeek V4 Pro direct, off-peak | $0.66 | $0.66 | $0.044 | $1.98 |

| Date | Segment | Requests | Input | Cache write | Cache read | Output | Opus 5.5 | DeepSeek off-peak | Work |
|---|---|---|---|---|---|---|---|---|---|
| 2026-11-07 | Session 1, measured part | 189 | 410 | 1,274,770 | 72,784,039 | 258,193 | $29.92 | $4.56 | Slices 1 to 9, CI, dossier, reviews |
| 2026-11-07 | Session 1, after summary | 12 | 26 | 136,387 | 2,104,031 | 16,060 | $1.83 | $0.21 | v0.0.1 decisions PDF |
| | **Running total** | **201** | | | | | **$31.75** | **$4.77** | |

Coverage: one reply in the second segment has no usage on record, and the stretch between the first measurement and the summary may be uncounted (inferred, 50%).
