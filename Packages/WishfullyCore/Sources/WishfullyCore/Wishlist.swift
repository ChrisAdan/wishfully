import Foundation

/// A list of wishes owned by one person, such as "Christmas 2026".
/// This is the object that gets shared with the shopper.
public struct Wishlist: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = Identifier<Wishlist>

    public let id: ID
    public var title: String
    public var occasion: String?
    public var eventDate: Date?
    public let createdAt: Date

    public init(
        id: ID = ID(),
        title: String,
        occasion: String? = nil,
        eventDate: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.occasion = occasion
        self.eventDate = eventDate
        self.createdAt = createdAt
    }
}
