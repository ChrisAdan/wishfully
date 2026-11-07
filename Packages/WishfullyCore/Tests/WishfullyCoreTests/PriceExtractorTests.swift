import Foundation
import Testing
@testable import WishfullyCore

/// Product pages here are invented and trimmed to the parts that matter.
@Suite("Price extractor")
struct PriceExtractorTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let name: String
        let html: String
        var defaultCurrency = "USD"
        /// Expected amount and currency, or nil when the page has no usable price.
        let amount: String?
        var currency = "USD"
        var source: PriceExtraction.Source?

        var testDescription: String {
            name
        }

        var expected: PriceExtraction? {
            guard let amount, let source, let value = Decimal(string: amount) else { return nil }
            return PriceExtraction(price: Money(amount: value, currencyCode: currency), source: source)
        }
    }

    static let cases: [Case] = [
        Case(name: "JSON-LD Product with a single Offer", html: """
        <script type="application/ld+json">
        {"@context":"https://schema.org","@type":"Product","name":"Linen throw",
         "offers":{"@type":"Offer","price":"68.00","priceCurrency":"USD"}}
        </script>
        """, amount: "68", source: .structuredData),
        Case(name: "JSON-LD numeric price, AggregateOffer, @graph", html: """
        <script type="application/ld+json">
        {"@graph":[{"@type":"WebPage"},
          {"@type":["Product"],"offers":{"@type":"AggregateOffer","lowPrice":42.5,"priceCurrency":"eur"}}]}
        </script>
        """, amount: "42.5", currency: "EUR", source: .structuredData),
        Case(name: "JSON-LD price in a PriceSpecification", html: """
        <script type="application/ld+json">
        {"@type":"Product","offers":[{"@type":"Offer",
          "priceSpecification":{"price":"19.99","priceCurrency":"USD"}}]}
        </script>
        """, amount: "19.99", source: .structuredData),
        Case(name: "Product meta tags", html: """
        <meta property="product:price:currency" content="GBP">
        <meta content="55.00" property="product:price:amount">
        """, amount: "55", currency: "GBP", source: .metaTags),
        Case(
            name: "Microdata",
            html: #"<div itemscope><span itemprop="price" content="12.00">$12</span></div>"#,
            amount: "12",
            source: .microdata
        ),
        Case(name: "Structured data wins over meta tags", html: """
        <meta property="og:price:amount" content="99.00">
        <script type="application/ld+json">{"@type":"Product","offers":{"price":"68.00"}}</script>
        """, amount: "68", source: .structuredData),
        Case(
            name: "Missing currency takes the default",
            html: #"<meta property="og:price:amount" content="10">"#,
            defaultCurrency: "cad",
            amount: "10",
            currency: "CAD",
            source: .metaTags
        ),
        Case(name: "No price on the page", html: "<html><body>No price here</body></html>", amount: nil),
        Case(
            name: "Price text that is not a number",
            html: #"<script type="application/ld+json">{"@type":"Product","offers":{"price":"Free"}}</script>"#,
            amount: nil
        ),
        Case(name: "Invalid JSON", html: #"<script type="application/ld+json">not json at all</script>"#, amount: nil),
        Case(
            name: "Non-product type",
            html: #"<script type="application/ld+json">{"@type":"Recipe","offers":{"price":"5"}}</script>"#,
            amount: nil
        ),
        Case(name: "Negative price", html: #"<meta property="og:price:amount" content="-5">"#, amount: nil),
    ]

    @Test("Finds the price and its source, or nil", arguments: PriceExtractorTests.cases)
    func extracts(_ testCase: Case) {
        let result = PriceExtractor.extract(fromHTML: testCase.html, defaultCurrency: testCase.defaultCurrency)
        #expect(result == testCase.expected)
    }

    @Test("Deeply nested JSON stops at the depth limit instead of recursing forever")
    func depthLimit() {
        let depth = PriceExtractor.maxJSONDepth + 5
        let nested = String(repeating: "[", count: depth)
            + #"{"@type":"Product","offers":{"price":"1"}}"#
            + String(repeating: "]", count: depth)
        let html = #"<script type="application/ld+json">"# + nested + "</script>"
        #expect(PriceExtractor.extract(fromHTML: html) == nil)
    }
}
