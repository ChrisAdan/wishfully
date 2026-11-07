# 007 · Product links in the import

*November 7, 2026 · Slice 7: links in the note importer · Drafted by Claude for the maintainer*

## From the maintainer

> **Maintainer:** Oh the list included all the URLs at hyperlinks but I guess those didn't come through in the paste.

## The situation

Each item in the real list links to its product page. In Apple Notes the links are rich-text attributes on the item text, so a plain-text copy carries the words and drops the links. The import pipeline keeps them in two steps:

1. **In the app (a later slice):** the Import screen reads the pasteboard as rich text and writes each linked run in Markdown form, `[item text](url)`.
2. **In `WishfullyCore` (this slice):** the importer reads Markdown links and bare URLs from each item line.

The split keeps the parsing logic in pure Swift, tested on Linux, and leaves the app layer one small conversion.

## Rules

| Item line | Title | Link | Store |
|---|---|---|---|
| `[Wool scarf](https://www.shop.example/scarf)` | Wool scarf | the URL | shop.example |
| `Candle https://shop.example/candle.` | Candle | the URL, trailing punctuation trimmed | shop.example |
| `https://www.shop.example/item/42` | shop.example | the URL | shop.example |
| `[Click](javascript:alert(1))` | the text as written | none | none |

Links are accepted for the `http` and `https` schemes exclusively; `javascript:`, `mailto:` and `file:` stay as plain text. The store name is the link's host, minus a leading `www.`.

## Facts and inferences

| Statement | Confidence |
|---|---|
| The importer extracts Markdown and bare web links, verified in CI by the link-parsing table (8 cases) and the importer integration test | 100% |
| Apple Notes places linked text on the pasteboard as rich text with link attributes, which the app can read | 80% |
| The real list's links all point to product pages that `PriceExtractor` can read for a price | 50% (store-dependent) |

## Next

Slice 8: the test policy, coverage reporting and recursive dependency reviews.
