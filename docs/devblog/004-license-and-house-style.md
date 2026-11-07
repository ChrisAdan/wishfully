# 004 · License and house style

*November 7, 2026 · Slice 4: MIT license and writing style · Drafted by Claude for the maintainer*

## License

Wishfully is MIT licensed. The code is open for anyone to use, and the project's value rests on the Wishfully name, the design and the people who use it. The decision record (0006) awaits the maintainer's write-up.

## House style

Documentation follows a single style guide, `docs/STYLE.md`. The core rules:

- **Third person, on behalf of the maintainer.** Documents speak for the project; decision records carry the maintainer's voice.
- **Positive framing.** Documents state what things do and guarantee.
- **Current state.** Documents describe the project as it stands; git holds the history.
- **Design principles.** Working methods are presented plainly as principles.
- **Mechanics:** commas, colons and parentheses in place of em dashes, and plain possessives.

## Style as a CI check

Style rules that a machine can check run in CI, beside formatting and lint. `docs-style.py` scans every Markdown file, skipping code blocks and inline code, for em dashes, the `X's own Y` construction, change-tracking words and first-person pronouns (decision records excepted). Editorial rules such as positive framing are applied in review.

Every document in the repository follows the guide, and the check runs green.

## Next

Slice 5: the note importer, built around the format of the real list.
