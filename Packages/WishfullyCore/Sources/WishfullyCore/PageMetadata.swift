import Foundation

/// What a product page says about itself: a title, a photo, a price and the store.
///
/// Read from untrusted HTML through `HTMLScanner`, as plain text values. Each field is best
/// effort and nil when the page leaves it out; the person adding the wish fills in the rest.
public struct PageMetadata: Equatable, Sendable {
    public var title: String?
    public var imageURL: URL?
    public var price: Money?
    public var store: String?

    public init(title: String? = nil, imageURL: URL? = nil, price: Money? = nil, store: String? = nil) {
        self.title = title
        self.imageURL = imageURL
        self.price = price
        self.store = store
    }

    /// Longest title kept, in characters. Store titles past this length are keyword lists.
    public static let maxTitleCharacters = 200

    private static let titleKeys = ["og:title", "twitter:title"]
    private static let imageKeys = ["og:image:secure_url", "og:image", "twitter:image", "twitter:image:src"]

    /// Reads the page's metadata. `pageURL` resolves relative image links and names the store.
    public static func extract(fromHTML html: String, pageURL: URL?) -> PageMetadata {
        let tags = HTMLScanner.tags(in: String(html.prefix(PriceExtractor.maxHTMLCharacters)))
        let meta = MetaValues(tags: tags)
        let title = meta.first(of: titleKeys)
            ?? tags.first(where: { $0.name == "title" })?.content.map(HTMLScanner.decodeEntities)
        let image = meta.first(of: imageKeys)
            ?? tags.first(where: { $0.name == "link" && $0[attribute: "rel"]?.lowercased() == "image_src" })?[
                attribute: "href"
            ]
        return PageMetadata(
            title: title.flatMap(cleanTitle),
            imageURL: image.flatMap { webURL($0, relativeTo: pageURL) },
            price: PriceExtractor.extract(fromHTML: html)?.price,
            store: meta.first(of: ["og:site_name"]).flatMap(cleanTitle) ?? LinkedTitle.store(for: pageURL)
        )
    }

    /// Collapses whitespace and caps the length.
    static func cleanTitle(_ raw: String) -> String? {
        let words = raw.split(whereSeparator: \.isWhitespace)
        guard !words.isEmpty else { return nil }
        let joined = words.joined(separator: " ")
        guard joined.count > maxTitleCharacters else { return joined }
        return String(joined.prefix(maxTitleCharacters - 1)) + "…"
    }

    /// An absolute `https` URL, resolving `//host/x` and `/x` against the page.
    /// Plain `http` images are upgraded to `https`; other schemes are dropped.
    static func webURL(_ text: String, relativeTo base: URL?) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let resolved = URL(string: trimmed, relativeTo: base)?.absoluteURL,
              var components = URLComponents(url: resolved, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased(), scheme == "https" || scheme == "http",
              components.host?.isEmpty == false
        else { return nil }
        components.scheme = "https"
        return components.url
    }
}

/// `<meta>` values keyed by their lower-cased `property` or `name` attribute; the first one wins.
private struct MetaValues {
    private var values: [String: String] = [:]

    init(tags: [HTMLTag]) {
        for tag in tags where tag.name == "meta" {
            guard let key = (tag[attribute: "property"] ?? tag[attribute: "name"])?.lowercased(),
                  let content = tag[attribute: "content"], values[key] == nil
            else { continue }
            values[key] = content
        }
    }

    func first(of keys: [String]) -> String? {
        keys.lazy.compactMap { values[$0] }.first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}
