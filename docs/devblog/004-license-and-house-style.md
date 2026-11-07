# 004 · License and house style

*November 7, 2026 · Slice 4: MIT license and writing style · Drafted by Claude for the maintainer*

## License

Wishfully is MIT licensed. The code is open for anyone to use, and the project's value rests on the Wishfully name, the design and the people who use it. Decision record 0006 logs the choice.

## House style

Documentation follows the writing rules in `AGENTS.md`. The core rules:

- **Third person, on behalf of the maintainer.** Documents speak for the project; decision records quote the maintainer verbatim.
- **Positive framing.** Documents state what things do and guarantee.
- **Current state.** Documents describe the project as it stands; git holds the history.
- **Design principles.** Working methods are presented plainly as principles.
- **Mechanics:** commas, colons and parentheses in place of em dashes, and plain possessives.

## Style as a CI check

Style rules that a machine can check run in CI, beside formatting and lint. `docs-style.py` scans every Markdown file, skipping code blocks and inline code, for the CI rows of the pattern table in `AGENTS.md`. Editorial rules such as positive framing are applied in review.

Every document in the repository follows the guide, and the check runs green.

## Next

Slice 5: the note importer.
