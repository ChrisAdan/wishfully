# Contributing

## AI-assisted development

Wishfully is implemented by an AI coding agent under the direction of the maintainer. These rules apply to every change:

1. **The maintainer is the author and is accountable.** Commits are authored by the maintainer, who reviews and approves every change before it reaches `main`.
2. **AI assistance is disclosed in a trailer**, following the Linux kernel convention:
   ```
   Assisted-by: Claude:claude-opus-5-5
   ```
   Authorship trailers (`Co-authored-by`, `Signed-off-by`) are reserved for people.
3. **Decision records are written by the maintainer.** Records in `docs/decisions/` hold the maintainer's reasoning; the agent supplies facts and links.
4. **Work arrives in slices.** Each slice is one pull request with one purpose, passes CI, and comes with a dev-blog post explaining what was built and why.

## Workflow

- Branch from `main`: `slice/<number>-<short-name>` or `fix/<short-name>`.
- Open a pull request. Every required check passes before merge, and checks stay enabled at all times.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org): `feat:`, `fix:`, `chore:`, `docs:`, `ci:`, `test:`, `refactor:`.

## Code standards

- Swift 6 language mode, with warnings treated as errors.
- Optionals are unwrapped safely (`if let`, `guard let`, `??`). SwiftLint treats force unwraps, force casts and `try!` as errors.
- SwiftFormat and SwiftLint pass, and jscpd keeps duplicated code under 1% (DRY).
- Logic belongs in `WishfullyCore`, with tests.
- A new third-party dependency requires a decision record and the maintainer's approval.

## Writing style

All documentation follows the writing rules and pattern table in [AGENTS.md](AGENTS.md).
