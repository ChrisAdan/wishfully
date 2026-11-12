import Foundation

/// The text another app hands to the Share sheet, split into a title and a product link.
///
/// Store apps share text such as "Linen throw https://shop.example/p/7" or a bare link; Safari
/// shares a URL and the page title separately. Both arrive here as one string.
public struct SharedText: Equatable, Sendable {
    public let title: String?
    public let url: URL?

    public init(_ text: String) {
        let linked = LinkedTitle(parsing: text.trimmingCharacters(in: .whitespacesAndNewlines))
        url = linked.url
        let store = LinkedTitle.store(for: linked.url)
        // A title that is only the store's name came from a bare link: nothing to keep.
        title = linked.title.isEmpty || linked.title == store ? nil : linked.title
    }
}
