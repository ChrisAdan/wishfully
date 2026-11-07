import Foundation

/// The shopper's view of a whole wishlist: merging, ordering and totals.
public struct ShoppingList: Sendable {
    public let items: [ShoppingItem]

    /// Pairs each wish with its overlay. Overlays for wishes that no longer
    /// exist (the recipient deleted the wish) are ignored.
    public init(wishes: [Wish], overlays: [ShopperOverlay]) {
        let overlaysByWish = Dictionary(
            overlays.map { ($0.wishID, $0) },
            uniquingKeysWith: { _, latest in latest }
        )
        items = wishes
            .map { ShoppingItem(wish: $0, overlay: overlaysByWish[$0.id]) }
            .sorted(by: Self.displayOrder)
    }

    public var toBuy: [ShoppingItem] {
        items.filter { !$0.isPurchased }
    }

    public var purchased: [ShoppingItem] {
        items.filter(\.isPurchased)
    }

    /// Money spent so far, per currency.
    public var spentByCurrency: [String: Decimal] {
        items.compactMap(\.spend).totalsByCurrency()
    }

    /// Most-wanted first; within the same desire level, oldest first, so the
    /// order stays stable as new wishes arrive.
    static func displayOrder(_ lhs: ShoppingItem, _ rhs: ShoppingItem) -> Bool {
        if lhs.wish.desire != rhs.wish.desire {
            return lhs.wish.desire > rhs.wish.desire
        }
        return lhs.wish.createdAt < rhs.wish.createdAt
    }
}
