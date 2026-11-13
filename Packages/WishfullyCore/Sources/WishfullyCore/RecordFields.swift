import Foundation

/// One value stored in a CloudKit record field. `empty` clears the field.
///
/// The app maps these to `CKRecord` values; keeping the mapping here lets Linux CI test every
/// field name and conversion that the deployed CloudKit schema depends on.
public enum FieldValue: Equatable, Sendable {
    case string(String)
    case int(Int)
    case date(Date)
    case empty

    var string: String? {
        if case let .string(value) = self {
            value
        } else {
            nil
        }
    }

    var int: Int? {
        if case let .int(value) = self {
            value
        } else {
            nil
        }
    }

    var date: Date? {
        if case let .date(value) = self {
            value
        } else {
            nil
        }
    }
}

/// Record type and field names, as declared in `App/CloudKit/schema.ckdb`.
/// A rename here is a schema change: Production keeps every deployed field.
public enum RecordSchema {
    public enum RecordType {
        public static let wishlist = "Wishlist"
        public static let wish = "Wish"
        public static let overlay = "Overlay"
    }

    public enum Field {
        public static let title = "title"
        public static let createdAt = "createdAt"
        public static let url = "url"
        public static let priceAmount = "priceAmount"
        public static let priceCurrency = "priceCurrency"
        public static let store = "store"
        public static let note = "note"
        public static let desire = "desire"
        public static let category = "category"
        public static let image = "image"
        public static let wishID = "wishID"
        public static let status = "status"
        public static let boughtAt = "boughtAt"
        public static let recipient = "recipient"
    }

    /// Each wishlist lives in its own record zone, so one zone-wide share covers the list.
    public static let listZonePrefix = "list-"
    /// The shopper's overlays live in this zone of the shopper's private database.
    public static let shopperZoneName = "Shopper"
    private static let overlayPrefix = "overlay-"

    public static func zoneName(for list: Wishlist.ID) -> String {
        listZonePrefix + list.description
    }

    public static func listID(fromZoneName name: String) -> Wishlist.ID? {
        guard name.hasPrefix(listZonePrefix) else { return nil }
        return UUID(uuidString: String(name.dropFirst(listZonePrefix.count))).map(Wishlist.ID.init)
    }

    public static func overlayRecordName(for wish: Wish.ID) -> String {
        overlayPrefix + wish.description
    }
}

private typealias Field = RecordSchema.Field
private let posix = Locale(identifier: "en_US_POSIX")

public extension Wishlist {
    var recordFields: [String: FieldValue] {
        [
            Field.title: .string(title),
            Field.createdAt: .date(createdAt),
            Field.recipient: recipient.map(FieldValue.string) ?? .empty,
        ]
    }

    init?(recordName: String, fields: [String: FieldValue]) {
        guard let uuid = UUID(uuidString: recordName) else { return nil }
        self.init(
            id: ID(uuid),
            title: fields[Field.title]?.string ?? "",
            recipient: fields[Field.recipient]?.string,
            createdAt: fields[Field.createdAt]?.date ?? Date(timeIntervalSince1970: 0)
        )
    }
}

public extension Wish {
    /// Every field the wish owns, with `empty` for values it lacks, so an edit clears them.
    /// The photo is an asset the app attaches separately.
    var recordFields: [String: FieldValue] {
        [
            Field.title: .string(title),
            Field.url: url.map { .string($0.absoluteString) } ?? .empty,
            Field.priceAmount: price.map { .string($0.amount.description) } ?? .empty,
            Field.priceCurrency: price.map { .string($0.currencyCode) } ?? .empty,
            Field.store: store.map(FieldValue.string) ?? .empty,
            Field.note: .string(note),
            Field.desire: .int(desire.rawValue),
            Field.category: category.map(FieldValue.string) ?? .empty,
            Field.createdAt: .date(createdAt),
        ]
    }

    /// Rebuilds a wish from a record. `modifiedAt` is the server's modification date.
    init?(recordName: String, fields: [String: FieldValue], modifiedAt: Date?) {
        guard let uuid = UUID(uuidString: recordName) else { return nil }
        let amount = fields[Field.priceAmount]?.string.flatMap { Decimal(string: $0, locale: posix) }
        let createdAt = fields[Field.createdAt]?.date ?? modifiedAt ?? Date(timeIntervalSince1970: 0)
        self.init(
            id: ID(uuid),
            title: fields[Field.title]?.string ?? "",
            url: fields[Field.url]?.string.flatMap(URL.init(string:)),
            price: amount.map { Money(amount: $0, currencyCode: fields[Field.priceCurrency]?.string ?? "USD") },
            store: fields[Field.store]?.string,
            note: fields[Field.note]?.string ?? "",
            desire: fields[Field.desire]?.int.flatMap(Desire.init(rawValue:)) ?? .wouldLove,
            category: fields[Field.category]?.string,
            createdAt: createdAt,
            updatedAt: modifiedAt ?? createdAt
        )
    }
}

public extension ShopperOverlay {
    var recordFields: [String: FieldValue] {
        [
            Field.wishID: .string(wishID.description),
            Field.status: .string(status.rawValue),
            Field.boughtAt: boughtAt.map(FieldValue.date) ?? .empty,
        ]
    }

    init?(fields: [String: FieldValue]) {
        guard let uuid = fields[Field.wishID]?.string.flatMap(UUID.init(uuidString:)) else { return nil }
        self.init(
            wishID: Wish.ID(uuid),
            status: fields[Field.status]?.string.flatMap(PurchaseStatus.init(rawValue:)) ?? .notBought,
            boughtAt: fields[Field.boughtAt]?.date
        )
    }
}
