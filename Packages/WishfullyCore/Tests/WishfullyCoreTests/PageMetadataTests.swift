import Foundation
import Testing
@testable import WishfullyCore

/// Product pages here are invented and trimmed to the parts that matter.
@Suite("Page metadata")
struct PageMetadataTests {
    struct Case: Sendable, CustomTestStringConvertible {
        let name: String
        let html: String
        var page = "https://www.shop.example/p/7"
        let title: String?
        let image: String?
        var store: String? = "shop.example"
        var price: String?

        var testDescription: String {
            name
        }
    }

    @Test("Reads the title, photo, store and price of a product page", arguments: [
        Case(
            name: "Open Graph tags with a JSON-LD price",
            html: """
            <title>Ignored when og:title exists</title>
            <meta property="og:title" content="Linen   throw &amp; pillow">
            <meta property="og:image" content="http://cdn.shop.example/throw.jpg">
            <meta property="og:site_name" content="Shop Example">
            <script type="application/ld+json">{"@type":"Product","offers":{"price":"68.00"}}</script>
            """,
            title: "Linen throw & pillow",
            image: "https://cdn.shop.example/throw.jpg",
            store: "Shop Example",
            price: "68"
        ),
        Case(name: "Title tag and a relative image_src link", html: """
        <TITLE> Wool scarf | Shop </TITLE><link rel="image_src" href="/img/scarf.png">
        """, title: "Wool scarf | Shop", image: "https://www.shop.example/img/scarf.png"),
        Case(name: "Twitter tags and a protocol-relative image", html: """
        <meta name="twitter:title" content="Candle"><meta name="twitter:image" content="//img.shop.example/c.jpg">
        """, title: "Candle", image: "https://img.shop.example/c.jpg"),
        Case(name: "Unsafe image schemes and empty values are dropped", html: """
        <meta property="og:title" content="  "><meta property="og:image" content="javascript:alert(1)">
        """, title: nil, image: nil),
        Case(
            name: "A page with nothing to read",
            html: "<p>Hello</p>",
            page: "not a url",
            title: nil,
            image: nil,
            store: nil
        ),
    ])
    func extractsMetadata(testCase: Case) {
        let metadata = PageMetadata.extract(fromHTML: testCase.html, pageURL: URL(string: testCase.page))
        #expect(metadata.title == testCase.title)
        #expect(metadata.imageURL?.absoluteString == testCase.image)
        #expect(metadata.store == testCase.store)
        #expect(metadata.price?.amount == testCase.price.flatMap { Decimal(string: $0) })
    }

    @Test("Caps long titles with an ellipsis")
    func capsTitles() throws {
        let long = String(repeating: "word ", count: 100)
        let title = try #require(PageMetadata.cleanTitle(long))
        #expect(title.count == PageMetadata.maxTitleCharacters)
        #expect(title.hasSuffix("…"))
    }
}
