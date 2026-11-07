import Foundation

/// One thing the recipient would like. Written only by the list's owner.
public struct Wish: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = Identifier<Wish>

    public let id: ID
    public var title: String
    public var url: URL?
    public var price: Money?
    public var store: String?
    /// Details for the shopper, such as size or color.
    public var note: String
    public var desire: Desire
    public var category: String?
    public let createdAt: Date
    public var updatedAt: Date

    public init(
        id: ID = ID(),
        title: String,
        url: URL? = nil,
        price: Money? = nil,
        store: String? = nil,
        note: String = "",
        desire: Desire = .wouldLove,
        category: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.url = url
        self.price = price
        self.store = store
        self.note = note
        self.desire = desire
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }
}
