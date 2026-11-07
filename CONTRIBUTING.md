# Contributing

## AI-assisted development policy

Wishfully is built with an AI coding agent under human direction. These rules apply to every change:

1. **A human is the author and is accountable.** Commits are authored by the maintainer, who reviews and approves every change before it reaches `main`.
2. **AI help is disclosed in a trailer**, following the Linux kernel's convention:
   ```
   Assisted-by: Claude:claude-opus-5-5
   ```
   AI tools are never listed as `Co-authored-by` or `Signed-off-by`.
3. **Decisions are written by humans.** Records in `docs/decisions/` capture the maintainer's reasoning in their own words.
4. **The agent works in slices.** Each slice is one pull request with one purpose, passing CI, with a dev-blog post explaining what was done and why.

## Workflow

- Branch from `main`: `slice/<number>-<short-name>` or `fix/<short-name>`.
- Open a pull request. Every required check must pass; checks are never skipped or disabled to get a green build.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org): `feat:`, `fix:`, `chore:`, `docs:`, `ci:`, `test:`, `refactor:`.

## Code standards

- Swift 6 language mode; warnings are errors.
- No force unwraps (`!`), force casts (`as!`) or `try!`.
- SwiftFormat and SwiftLint must pass; duplicated code blocks fail CI (DRY).
- Logic belongs in `WishfullyCore` (pure Swift, no UI) with tests.
- No new third-party dependency without a decision record.
