import Foundation
import Testing
@testable import WishfullyCore

/// Product pages here are invented and trimmed to the parts that matter.
@Suite("Price extractor")
struct PriceExtractorTests {
    private func extract(_ html: String) -> PriceExtraction? {
        PriceExtractor.extract(fromHTML: html)
    }

    private func usd(_ amount: String) -> Money {
        Money(amount: Decimal(string: amount) ?? 0, currencyCode: "USD")
    }

    @Test("JSON-LD Product with a single Offer")
    func jsonLDOffer() {
        let html = """
        <html><head><script type="application/ld+json">
        {"@context":"https://schema.org","@type":"Product","name":"Linen throw",
         "offers":{"@type":"Offer","price":"68.00","priceCurrency":"USD"}}
        </script></head></html>
        """
        #expect(extract(html) == PriceExtraction(price: usd("68"), source: .structuredData))
    }

    @Test("JSON-LD numeric price, AggregateOffer and an @graph wrapper")
    func jsonLDGraphAggregate() {
        let html = """
        <script type="application/ld+json">
        {"@graph":[{"@type":"WebPage"},
          {"@type":["Product"],"offers":{"@type":"AggregateOffer","lowPrice":42.5,"priceCurrency":"eur"}}]}
        </script>
        """
        #expect(extract(html)?.price == Money(amount: Decimal(string: "42.5") ?? 0, currencyCode: "EUR"))
    }

    @Test("JSON-LD price nested in a PriceSpecification")
    func jsonLDPriceSpecification() {
        let html = """
        <script type="application/ld+json">
        {"@type":"Product","offers":[{"@type":"Offer",
          "priceSpecification":{"price":"19.99","priceCurrency":"USD"}}]}
        </script>
        """
        #expect(extract(html)?.price == usd("19.99"))
    }

    @Test("Open Graph / product meta tags when there's no structured data")
    func metaTags() {
        let html = """
        <meta property="product:price:currency" content="GBP">
        <meta content="55.00" property="product:price:amount">
        """
        #expect(extract(html) == PriceExtraction(price: Money(amount: 55, currencyCode: "GBP"), source: .metaTags))
    }

    @Test("Microdata as the last resort")
    func microdata() {
        let html = #"<div itemscope><span itemprop="price" content="12.00">$12</span></div>"#
        #expect(extract(html) == PriceExtraction(price: usd("12"), source: .microdata))
    }

    @Test("Structured data wins over meta tags")
    func priority() {
        let html = """
        <meta property="og:price:amount" content="99.00">
        <script type="application/ld+json">{"@type":"Product","offers":{"price":"68.00"}}</script>
        """
        #expect(extract(html)?.source == .structuredData)
        #expect(extract(html)?.price == usd("68"))
    }

    @Test("Missing currency falls back to the default")
    func defaultCurrency() {
        let html = #"<meta property="og:price:amount" content="10">"#
        #expect(PriceExtractor.extract(fromHTML: html, defaultCurrency: "cad")?.price.currencyCode == "CAD")
    }

    @Test("Pages without a usable price return nil", arguments: [
        "<html><body>No price here</body></html>",
        #"<script type="application/ld+json">{"@type":"Product","offers":{"price":"Free"}}</script>"#,
        #"<script type="application/ld+json">not json at all</script>"#,
        #"<script type="application/ld+json">{"@type":"Recipe","offers":{"price":"5"}}</script>"#,
        #"<meta property="og:price:amount" content="-5">"#,
    ])
    func noPrice(html: String) {
        #expect(extract(html) == nil)
    }

    @Test("Deeply nested JSON stops at the depth limit instead of recursing forever")
    func depthLimit() {
        let depth = PriceExtractor.maxJSONDepth + 5
        let nested = String(repeating: "[", count: depth)
            + #"{"@type":"Product","offers":{"price":"1"}}"#
            + String(repeating: "]", count: depth)
        let html = #"<script type="application/ld+json">"# + nested + "</script>"
        #expect(extract(html) == nil)
    }
}
