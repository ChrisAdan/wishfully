# 003 · Reading prices from hostile pages

*November 7, 2026 · Slice 3: price extraction · Drafted by Claude for the maintainer*

## The job

When the recipient shares a product page, Wishfully fills in the price. Stores publish prices in different ways, and every page is **untrusted input**. This slice adds a small, defensive parser that returns a price when the page states one clearly and returns nil otherwise. A blank price is a normal state: the shopper can add it later.

## Where prices live

The extractor checks three sources, in order of reliability:

1. **Structured data (JSON-LD).** Most large stores embed a schema.org `Product` in a script block, with `offers` holding the price and currency. The extractor reads single offers, offer lists, "from" prices (`AggregateOffer.lowPrice`), prices inside a `priceSpecification`, and the common `@graph` wrapper.
2. **Meta tags.** `product:price:amount` and `og:price:amount`, with their currency tags.
3. **Microdata.** The `content` value of `itemprop="price"` elements.

## Defences

| Risk | Defence |
|---|---|
| Huge pages | The first 2 million characters are read; JSON blocks above 500 KB are skipped |
| Malformed HTML | A hand-written scanner whose every loop advances the cursor, so it always terminates; eleven kinds of malformed input are tested |
| Deeply nested JSON | Recursion stops at depth 12, with a test proving it |
| Scripts | Script text is parsed as data and stays inert |
| Junk values | "Free", "Call for price", negative numbers, ranges such as "10-20" and amounts outside $0.01 to $1,000,000 are rejected |
| International formats | "1,299.99", "1.299,99", "68,00" and "68" all parse to exact decimal amounts |

The scanner is hand-written because the app ships with Apple frameworks and project code exclusively, and the need is narrow: tags and attributes. It walks the text once, collects start tags, and comes to about 170 lines written for readability.

## Edge cases covered

- A page that ends in `<script` without a closing `>`: cursor positions are clamped, so slicing stays in bounds.
- A minus sign anywhere in the value rejects it, which covers negatives and ranges.
- "1.299.000" parses to 1.3 million and is rejected as implausible.

## Slice size and result

About 560 lines: three source files (scanner, number parsing, extractor) and three test files with 18 new tests that expand to 51 cases through parameterized inputs. That sits at the top of the target range, but it is one concept, and the scanner reads best reviewed beside the code that uses it.

CI result: 31 tests across 5 suites pass on Linux in about a second.

## Next

Slice 4: the MIT license and the house writing style.
