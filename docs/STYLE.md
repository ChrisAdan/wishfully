# Writing style

These rules apply to every document, pull request, commit message and dev-blog post in this repository. The `Docs style` CI check enforces the mechanical rules; reviewers apply the editorial ones.

## Voice

- **Third person, on behalf of the maintainer.** Documents speak for the project and its maintainer. Write "this check verifies the checksum", "the decision was made to use Core Data", "the maintainer approves each release".
- **Decision records are the exception.** Records in `docs/decisions/` are written by the maintainer, in the maintainer's voice.

## Framing

- **State what things do.** Write "the app contains Apple frameworks and project code exclusively" in place of a sentence built around what the app lacks. Describe behavior, guarantees and limits as positive statements.
- **Describe the current state.** Documents describe how the project works today. History lives in git; each document reads as current fact.
- **Call practices design principles.** Working methods (guardrails first, small slices, human authority) are presented plainly as the project's design principles.

## Mechanics

- **Punctuation:** use commas, colons, parentheses or separate sentences. Em dashes are disallowed.
- **Possession:** write plain possessives, such as "the shopper's private iCloud database". The construction `X's own Y` is disallowed.
- **Plain words:** short sentences, specific nouns, numbers with units. Filler, hype and stacked adjectives are cut.

## Enforced by CI

`.github/scripts/docs-style.py` checks every Markdown file (outside code blocks) for em dashes, the `X's own Y` construction, change-tracking words such as `formerly`, and first-person pronouns (decision records excepted).
