import Foundation

/// Where the shopper is with a wish.
public enum PurchaseStatus: String, CaseIterable, Codable, Sendable {
    case notBought
    case bought
    case wrapped

    public var isPurchased: Bool {
        self != .notBought
    }
}

/// The shopper's private layer over one wish.
///
/// Stored only in the shopper's own iCloud database, never in the recipient's,
/// so purchases can't leak to the recipient. It points at the wish by ID
/// because Core Data can't relate objects across the private and shared stores.
public struct ShopperOverlay: Hashable, Codable, Sendable {
    public let wishID: Wish.ID
    public var status: PurchaseStatus
    /// The shopper's correction when the listed price is missing or wrong.
    public var priceOverride: Money?
    public var pricePaid: Money?
    public var boughtAt: Date?
    public var privateNote: String

    public init(
        wishID: Wish.ID,
        status: PurchaseStatus = .notBought,
        priceOverride: Money? = nil,
        pricePaid: Money? = nil,
        boughtAt: Date? = nil,
        privateNote: String = ""
    ) {
        self.wishID = wishID
        self.status = status
        self.priceOverride = priceOverride
        self.pricePaid = pricePaid
        self.boughtAt = boughtAt
        self.privateNote = privateNote
    }
}
