# 000 · Project principles

*November 7, 2026 · Slice 0: repository foundations · Drafted by Claude for the maintainer*

## The problem

Gift lists kept in a note are hard to shop from. Adding an item from Safari means copying links by hand, the shopper has nowhere to record purchases, and anything written beside the list risks spoiling the surprise.

**Wishfully** solves this. The recipient shares products to it from any app. The shopper shops from the same list on a second phone and records purchases privately.

## Constraints

- **Deadline:** Christmas 2026, seven weeks out.
- **Cloud builds:** every build and test runs on GitHub Actions machines, including the macOS builds iOS requires. CI output is the project's feedback loop.
- **Security as a precondition:** the app runs on a family member's phone, so every feature starts from the security model.
- **Learning by building:** the maintainer is learning Swift through this project, so each slice explains its reasoning.

## How the work is decomposed

The agent works in **slices**. A slice is one pull request with one purpose. It passes CI on its own, fits a single review sitting, and comes with a post in this blog. Three rules set the order:

1. **Guardrails first.** CI, linting, secret scanning and dependency policy land before app code, so every line of Swift is held to them from the start.
2. **Cheapest to verify first.** Pure logic, tested on Linux in seconds, comes before UI. UI comes before iCloud sync.
3. **Riskiest work isolated.** Sharing between two iCloud accounts sits behind an interface, so the rest of the app stands on its own.

A **safety-net milestone** anchors the plan: by November 21 the app runs on the maintainer's phone with the real list imported, ready for shopping, independent of sharing.

## This slice

- **README:** what Wishfully is and its design principles.
- **SECURITY.md:** the security model and private vulnerability reporting.
- **CONTRIBUTING.md:** the AI-assisted development policy. The maintainer authors and answers for every commit, and the agent's contribution is disclosed with an `Assisted-by:` trailer, the convention adopted by the Linux kernel.
- **CODEOWNERS:** the maintainer owns every path, with CI configuration called out explicitly.
- **Decision records:** a template, plus the list of decisions awaiting the maintainer's write-up.
- **.gitignore:** generated Xcode projects, build output and every kind of signing key stay out of version control.

## Review model

The agent pushes through the maintainer's GitHub account, so its pull requests appear under the maintainer's name. Changes in the "ask first" category are approved by the maintainer in conversation before the agent proceeds. A dedicated bot account for the agent is a planned improvement; it enables formal pull-request approvals.

## Next

Slice 1: the core CI pipeline.
