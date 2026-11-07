# 000 · Building a gift-list app with an agent, in the open

*November 7, 2026 · Slice 0: repository foundations · Drafted with Claude, edited by Chris*

## The problem

I hate shopping for gifts. My wife keeps a beautifully organized Christmas list in an iCloud note, but a note is a dead end: she can't add to it from Safari, I can't mark what I've bought, and anything I write down risks spoiling the surprise.

So we're building **Wishfully**: she shares products to it from any app; I shop from the same list on my phone; my purchases stay invisible to her.

## The constraints

These shaped every decision that follows:

- **Deadline: Christmas.** Seven weeks from today.
- **No Mac.** iOS apps have to be built on macOS. Every build runs on a cloud Mac in GitHub Actions; neither the agent nor I can run a debugger or a simulator.
- **It's going on my wife's phone.** Security isn't a feature here, it's the precondition.
- **I'm learning Swift as we go,** and I want the result to be an example of how agentic development should be done.

## How the agent decomposes the work

The agent works in **slices**. A slice is one pull request with one purpose. It has to pass CI on its own and be reviewable in one sitting, and each one ends with a post here. Two rules decide the order:

1. **Guardrails before code.** CI, linting, secret scanning and dependency policy land before any app code exists. Code written into a repo without guardrails gets grandfathered past them.
2. **Cheapest-to-verify first, riskiest last but isolated.** Pure logic that can be tested on Linux in seconds comes before UI. UI comes before iCloud sync, and the hardest piece (sharing between two iCloud accounts) sits behind an interface so it can't take the rest of the app down with it.

There's also a **safety net**: by about November 21 the app runs on my phone with her real list imported, so even if sharing slips, I can still shop.

## This slice: foundations

No app code yet. This slice adds:

- **README**: what Wishfully is and how it's built.
- **SECURITY.md**: the security model, and how to report problems privately.
- **CONTRIBUTING.md**: the AI-assisted development policy. I'm the author of every commit and accountable for it, and the agent's help is disclosed with an `Assisted-by:` trailer, the convention the Linux kernel adopted. No AI co-author lines.
- **CODEOWNERS**: everything, especially CI configuration, is mine to review.
- **Decision records**: a template, plus a list of the decisions I owe a write-up for. The agent supplies facts; the reasoning is mine.
- **.gitignore**: the Xcode project, build output and every kind of signing key are kept out of the repo by default.

One decision worth calling out: **no license yet**. The repo is public, but "public" and "open source" aren't the same thing. Until a license is added, the code is readable but all rights are reserved. Adding a permissive license later is easy; taking one back isn't.

## A wrinkle worth noting

The agent pushes through my GitHub account, so its pull requests show up as mine, and GitHub doesn't let you approve your own pull request. That means "required reviews" can't be enforced on the agent's work the usual way. For now the agent asks me in chat before anything in the "ask first" category. The cleaner, more exemplary setup is a separate bot account that opens PRs I then approve, and that's on the list for later.

## Next

Slice 1: the core CI pipeline: formatting, linting, duplicate-code detection, secret scanning and Linux tests, with every third-party action pinned to an exact commit.
