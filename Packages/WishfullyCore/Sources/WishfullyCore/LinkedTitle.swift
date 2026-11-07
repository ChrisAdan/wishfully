import Foundation

/// A wish title and its optional product link, parsed from one line of text.
///
/// Recognizes Markdown links (`[Silver bangle](https://shop.example/bangle)`) and
/// bare `http`/`https` URLs. Other schemes stay in the title as plain text.
struct LinkedTitle: Equatable, Sendable {
    let title: String
    let url: URL?

    private static let trailingPunctuation = CharacterSet(charactersIn: ".,;:!?)")

    init(parsing text: String) {
        let markdownLink = #/\[(?<label>[^\]]*)\]\((?<target>https?://[^\s)]+)\)/#
        let bareLink = #/https?://\S+/#

        var link = text.firstMatch(of: markdownLink).flatMap { Self.webURL(String($0.output.target)) }
        let withoutMarkdown = text.replacing(markdownLink) { String($0.output.label) }
        if link == nil, let match = withoutMarkdown.firstMatch(of: bareLink) {
            link = Self.webURL(String(match.output).trimmingCharacters(in: Self.trailingPunctuation))
        }
        let words = withoutMarkdown.replacing(bareLink, with: "").split(whereSeparator: \.isWhitespace)

        url = link
        title = words.isEmpty ? (Self.store(for: link) ?? text) : words.joined(separator: " ")
    }

    /// The link's host without a leading "www.", used as the store name.
    static func store(for url: URL?) -> String? {
        guard let url, let host = URLComponents(url: url, resolvingAgainstBaseURL: false)?.host else { return nil }
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    private static func webURL(_ text: String) -> URL? {
        guard let url = URL(string: text),
              let scheme = url.scheme?.lowercased(), scheme == "https" || scheme == "http",
              store(for: url) != nil
        else { return nil }
        return url
    }
}
