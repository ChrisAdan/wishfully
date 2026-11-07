import Foundation

/// A price found on a product page, and where on the page it came from.
public struct PriceExtraction: Equatable, Sendable {
    public enum Source: String, Sendable {
        /// schema.org Product data in a JSON-LD script block.
        case structuredData
        /// Open Graph / product meta tags.
        case metaTags
        /// schema.org microdata attributes (`itemprop="price"`).
        case microdata
    }

    public let price: Money
    public let source: Source
}

/// Finds a product's price in a page's HTML, best effort.
///
/// Pages are untrusted input. The extractor reads only plain text values, never
/// runs page scripts, caps how much of the page it looks at, and returns nil
/// rather than guessing. A missing price is normal: the shopper can fill it in.
public enum PriceExtractor {
    /// Characters of HTML considered. Product data sits near the top of a page.
    public static let maxHTMLCharacters = 2_000_000
    static let maxJSONBlockCharacters = 500_000
    static let maxJSONDepth = 12

    private static let metaAmountKeys = ["product:price:amount", "og:price:amount"]
    private static let metaCurrencyKeys = ["product:price:currency", "og:price:currency"]
    private static let productTypes: Set = ["Product", "ProductGroup", "IndividualProduct"]

    /// Strategies in order of reliability: structured data, then meta tags, then microdata.
    public static func extract(fromHTML html: String, defaultCurrency: String = "USD") -> PriceExtraction? {
        let tags = HTMLScanner.tags(in: String(html.prefix(maxHTMLCharacters)))
        let fallbackCurrency = PriceParsing.currencyCode(from: defaultCurrency) ?? "USD"

        if let price = structuredDataPrice(in: tags, fallbackCurrency: fallbackCurrency) {
            return PriceExtraction(price: price, source: .structuredData)
        }
        if let price = metaTagPrice(in: tags, fallbackCurrency: fallbackCurrency) {
            return PriceExtraction(price: price, source: .metaTags)
        }
        if let price = microdataPrice(in: tags, fallbackCurrency: fallbackCurrency) {
            return PriceExtraction(price: price, source: .microdata)
        }
        return nil
    }

    // MARK: - Strategies

    static func structuredDataPrice(in tags: [HTMLTag], fallbackCurrency: String) -> Money? {
        let blocks = tags.lazy
            .filter { $0.name == "script" && ($0[attribute: "type"] ?? "").lowercased().contains("ld+json") }
            .compactMap(\.content)
            .filter { $0.count <= maxJSONBlockCharacters }
        for block in blocks {
            guard let json = try? JSONSerialization.jsonObject(with: Data(block.utf8)),
                  let price = productPrice(in: json, depth: 0, fallbackCurrency: fallbackCurrency)
            else { continue }
            return price
        }
        return nil
    }

    static func metaTagPrice(in tags: [HTMLTag], fallbackCurrency: String) -> Money? {
        let metaTags = tags.filter { $0.name == "meta" }
        func content(forAnyOf keys: [String]) -> String? {
            metaTags.first(where: { tag in
                keys.contains((tag[attribute: "property"] ?? tag[attribute: "name"] ?? "").lowercased())
            })?[attribute: "content"]
        }
        return money(
            amountText: content(forAnyOf: metaAmountKeys),
            currencyText: content(forAnyOf: metaCurrencyKeys),
            fallbackCurrency: fallbackCurrency
        )
    }

    static func microdataPrice(in tags: [HTMLTag], fallbackCurrency: String) -> Money? {
        func content(forItemProp name: String) -> String? {
            tags.first(where: { $0[attribute: "itemprop"]?.lowercased() == name })?[attribute: "content"]
        }
        return money(
            amountText: content(forItemProp: "price"),
            currencyText: content(forItemProp: "pricecurrency"),
            fallbackCurrency: fallbackCurrency
        )
    }

    // MARK: - JSON-LD walking

    /// Depth-first search for the first schema.org Product that has a usable offer price.
    static func productPrice(in node: Any, depth: Int, fallbackCurrency: String) -> Money? {
        guard depth < maxJSONDepth else { return nil }
        if let array = node as? [Any] {
            return array.lazy.compactMap { productPrice(in: $0, depth: depth + 1, fallbackCurrency: fallbackCurrency) }
                .first
        }
        guard let object = node as? [String: Any] else { return nil }
        if isProduct(object), let offers = object["offers"],
           let price = offerPrice(in: offers, depth: depth + 1, fallbackCurrency: fallbackCurrency)
        {
            return price
        }
        // Sorted keys keep the search deterministic; "@graph" sorts first.
        return object.keys.sorted().lazy
            .compactMap { key in object[key] }
            .compactMap { productPrice(in: $0, depth: depth + 1, fallbackCurrency: fallbackCurrency) }
            .first
    }

    /// Reads Offer, AggregateOffer or PriceSpecification objects, or arrays of them.
    static func offerPrice(in node: Any, depth: Int, fallbackCurrency: String) -> Money? {
        guard depth < maxJSONDepth else { return nil }
        if let array = node as? [Any] {
            return array.lazy.compactMap { offerPrice(in: $0, depth: depth + 1, fallbackCurrency: fallbackCurrency) }
                .first
        }
        guard let offer = node as? [String: Any] else { return nil }
        let currencyText = offer["priceCurrency"] as? String
        for key in ["price", "lowPrice"] {
            if let price = money(
                amountText: text(from: offer[key]),
                currencyText: currencyText,
                fallbackCurrency: fallbackCurrency
            ) {
                return price
            }
        }
        if let specification = offer["priceSpecification"] {
            return offerPrice(in: specification, depth: depth + 1, fallbackCurrency: fallbackCurrency)
        }
        return nil
    }

    // MARK: - Helpers

    private static func isProduct(_ object: [String: Any]) -> Bool {
        switch object["@type"] {
        case let type as String:
            productTypes.contains(type)
        case let types as [Any]:
            types.contains { element in
                guard let type = element as? String else { return false }
                return productTypes.contains(type)
            }
        default:
            false
        }
    }

    /// JSON numbers and strings both appear as prices in the wild.
    private static func text(from value: Any?) -> String? {
        guard let value else { return nil }
        switch value {
        case let string as String: return string
        case let number as NSNumber: return number.stringValue
        case let integer as Int: return String(integer)
        case let double as Double: return String(double)
        default: return nil
        }
    }

    private static func money(amountText: String?, currencyText: String?, fallbackCurrency: String) -> Money? {
        guard let amountText, let amount = PriceParsing.amount(from: amountText) else { return nil }
        let currency = PriceParsing.currencyCode(from: currencyText) ?? fallbackCurrency
        return Money(amount: amount, currencyCode: currency)
    }
}
