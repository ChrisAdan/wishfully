# 003 · Reading prices from hostile pages

*November 7, 2026 · Slice 3: price extraction · Drafted with Claude, edited by Chris*

## The job

When my wife shares a product page, Wishfully should fill in the price. Stores don't agree on how to publish one, and some don't publish it at all. Every page is also **untrusted input**: anyone can put anything in HTML. So this slice is a small, defensive parser that finds a price when one is clearly stated, and otherwise returns nothing rather than guessing.

## Three places a price can hide

The extractor checks, in order of reliability:

1. **Structured data (JSON-LD).** Most large stores embed a machine-readable schema.org `Product` in a script block, with `offers` holding the price and currency. The extractor handles single offers, lists of offers, "from" prices (`AggregateOffer.lowPrice`), prices nested in a `priceSpecification`, and the common `@graph` wrapper.
2. **Meta tags.** Open Graph style `product:price:amount` and `og:price:amount`, with their currency tags.
3. **Microdata.** `itemprop="price"` attributes, read from their `content` value.

If none of these yields a plausible price, the field stays empty. Chris can add the price from his side later, so a blank isn't a failure.

## Treating the page as hostile

| Risk | Defence |
|---|---|
| Huge pages | Only the first 2 million characters are read; JSON blocks over 500 KB are skipped |
| Malformed HTML (unclosed quotes, stray `<`, unterminated scripts) | A hand-written scanner where every loop advances the cursor, so it always terminates. Tests feed it eleven kinds of garbage |
| Deeply nested JSON built to exhaust the stack | Recursion stops at depth 12, with a test that proves it |
| Scripts | Script text is only ever parsed as data. Nothing on the page is executed, rendered or followed |
| Junk values ("Free", "Call for price", negative numbers, ranges like "10-20", $9,999,999) | Rejected. Accepted prices must fall between $0.01 and $1,000,000 |
| International formats | "1,299.99", "1.299,99", "68,00" and "68" all parse to exact decimal amounts |

Why a hand-written scanner rather than a library? The project rule is no third-party code in the app, and a real HTML parser is far more machinery than "find a few tags and attributes" needs. The scanner is about 170 lines, never builds a document tree, and was written to be read.

## Slice size and shape

About 560 lines: three source files (the scanner, number parsing, and the extractor) and three matching test files: 18 new tests that expand to 51 cases with parameterized inputs. That's at the top of the target range, but it's one concept, and the scanner wouldn't make sense to review without the thing that uses it.

## Caught before CI

Reviewing its own code before pushing, the agent found and fixed three bugs no linter would catch:

- A page ending in `<script` with no closing `>` would have made the scanner slice an array out of bounds, which crashes in Swift. Positions are now clamped, and that exact input is a test case.
- A minus sign was silently dropped, so "-5" parsed as 5. Any minus sign now rejects the value, which also rules out ranges.
- A test case expected "1.299.000" to parse, but at 1.3 million it's correctly rejected as implausible. The test was wrong, not the code.

## Next

Slice 4 depends on what my wife's real note looks like. The importer that turns her iCloud note into a Wishfully list gets built around its actual format. Until I paste a sample, the agent moves on to whatever isn't blocked.

## Result

First compile in CI: green. 31 tests across 5 suites now pass on Linux in about a second.
