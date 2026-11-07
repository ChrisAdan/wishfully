import Foundation

/// What the shopper sees: the recipient's wish merged with the shopper's
/// private overlay. Every screen in shopper mode reads from this one type.
public struct ShoppingItem: Identifiable, Hashable, Sendable {
    public let wish: Wish
    public let overlay: ShopperOverlay?

    public init(wish: Wish, overlay: ShopperOverlay?) {
        self.wish = wish
        self.overlay = overlay
    }

    public var id: Wish.ID {
        wish.id
    }

    public var status: PurchaseStatus {
        overlay?.status ?? .notBought
    }

    public var isPurchased: Bool {
        status.isPurchased
    }

    /// The shopper's correction wins over the price captured from the store.
    public var effectivePrice: Money? {
        overlay?.priceOverride ?? wish.price
    }

    /// What counts toward the budget: the price actually paid if recorded,
    /// otherwise the best known price. Nil for items not yet purchased.
    public var spend: Money? {
        guard isPurchased else { return nil }
        return overlay?.pricePaid ?? effectivePrice
    }
}
