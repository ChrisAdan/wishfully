import Foundation

/// A type-safe identifier. `Identifier<Wish>` and `Identifier<Wishlist>` are
/// different types, so the compiler rejects passing a wishlist's ID where a
/// wish's ID is expected. One generic type serves every model (DRY).
public struct Identifier<Owner>: Hashable, Sendable, CustomStringConvertible {
    public let rawValue: UUID

    public init(_ rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }

    public var description: String {
        rawValue.uuidString
    }
}

/// Encodes as a bare UUID string rather than {"rawValue": "..."}.
extension Identifier: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        rawValue = try container.decode(UUID.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
