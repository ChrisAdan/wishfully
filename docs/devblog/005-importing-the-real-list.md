# 005 · Importing the real list

*November 7, 2026 · Slice 5: note importer · Drafted by Claude for the maintainer*

## Why now

The safety-net milestone puts the recipient's real list on the shopper's phone by November 21. The importer is the piece that gets it there: paste the note, and the wishes appear. The real list sets the format, so the importer is built around its actual structure.

## The format

The source is an Apple Notes checklist with this shape:

```
🎄 list title 🎄

Section 🎀
- [ ] Item
- [ ]  Item with uneven spacing 
- [ ] Item  with a double space

Another section 💄
- [ ] Item


- [ ] Item in a block without its own heading

----
```

The importer's rules follow from it:

| Line | Becomes |
|---|---|
| `- [ ]`, `- [x]`, `-`, `*`, `•`, `☐` followed by text | A wish, with whitespace tidied |
| Any other text | A heading; its text, minus emoji, becomes the category ("Section 🎀" becomes "Section") |
| A heading followed directly by another heading | The list title, emoji kept |
| Blank lines, `----`, `***`, `___` | Skipped |

**A decision made for this format:** a heading stays in effect until the next heading, across blank lines. In the real list, a block of baking items sits below the Home section with no heading of its own, so those items join Home. Wishes can be recategorized in the app.

Checked items (`- [x]`) import like any other wish. Imported wishes start with the default desire ("Would love"), no price and no note, and they keep the order of the note.

## Privacy

The real list stays out of the repository. Tests use an invented note with the same structure: emoji title, emoji headings, uneven spacing, a block without a heading, a separator, and checked items. The import itself runs on the device.

## Tests

Eleven new tests (13 cases) cover the title, item text, categories, the headless block, order through the shopping-list sort, defaults, notes without a title, uncategorized items, Windows line endings, trailing whitespace, empty markers, separators, emoji-only headings and the empty note.

## Next

The remaining Core work is complete. The next slices bring the app itself: the design system and screens on GitHub's macOS runners, which need the snapshot-testing dependency approved, and the Xcode project and TestFlight pipeline, which need the Apple Developer account.
