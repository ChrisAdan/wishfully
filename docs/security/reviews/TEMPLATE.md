# Dependency security review: PACKAGE

*Adversarial source review · release X.Y.Z · YYYY-MM-DD*

## Decision summary

| Item | Value |
|---|---|
| Package | `owner/name`, license |
| Version reviewed | X.Y.Z, commit `<sha>` (date) |
| Proposed use | Product, target type (app or test) |
| Recommendation | Approve · Approve with conditions · Decline · Abort (closed source) |
| Confidence in recommendation | NN% |

Confidence scale: 100% means verified directly against source code or tool output. Lower values are inferences with the estimated probability of being correct.

## 1. Build-versus-adopt estimate

| Path | Requests | Output tokens | Cost (Anthropic model) | Cost (open-weight model) |
|---|---|---|---|---|
| Adopt: review and recursive trace | | | | |
| Adopt: review per update × expected updates per year | | | | |
| Build: implement in this repository | | | | |
| Build: maintenance per year | | | | |

Price sources and dates:

## 2. Dependency graph

Every package, including platform-conditional dependencies. Closed source anywhere in the graph aborts the evaluation.

| Package | Version | Open source | Reached by the proposed use | Trace depth and reason |
|---|---|---|---|---|

## 3. Scan results per package

Risk categories: process execution, network access, environment access, file writes, dynamic evaluation, unsafe memory, deserialization, Objective-C runtime use, build plugins, binary artifacts, manifest code.

| Package | Category | Finding | Reaches the build |
|---|---|---|---|

## 4. Verified facts (100%)

## 5. Inferences

| Statement | Confidence |
|---|---|

## 6. Propagated findings

Every finding from sections 2 and 3 that bears on the verdict.

## 7. Conditions or alternatives

## 8. Recommendation
