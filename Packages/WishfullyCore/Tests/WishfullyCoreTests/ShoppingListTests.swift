import Foundation
import Testing
@testable import WishfullyCore

@Suite("Shopping list")
struct ShoppingListTests {
    let blanket = Fixtures.wish("Blanket", price: 68, desire: .dreamGift, createdDaysAfterStart: 2)
    let earrings = Fixtures.wish("Earrings", price: 55, desire: .wouldLove, createdDaysAfterStart: 0)
    let cookbook = Fixtures.wish("Cookbook", desire: .wouldLove, createdDaysAfterStart: 1)
    let socks = Fixtures.wish("Socks", price: 12, desire: .niceToHave, createdDaysAfterStart: 0)

    var wishes: [Wish] {
        [socks, cookbook, earrings, blanket]
    }

    @Test("Items are ordered most-wanted first, then oldest first")
    func ordering() {
        let list = ShoppingList(wishes: wishes, overlays: [])
        #expect(list.items.map(\.wish.title) == ["Blanket", "Earrings", "Cookbook", "Socks"])
    }

    @Test("Wishes without an overlay count as not bought")
    func noOverlayMeansNotBought() {
        let list = ShoppingList(wishes: wishes, overlays: [])
        #expect(list.toBuy.count == 4)
        #expect(list.purchased.isEmpty)
        #expect(list.spentByCurrency.isEmpty)
    }

    @Test("Bought and wrapped items move to purchased")
    func purchasedSplit() {
        let overlays = [
            ShopperOverlay(wishID: blanket.id, status: .bought),
            ShopperOverlay(wishID: socks.id, status: .wrapped),
        ]
        let list = ShoppingList(wishes: wishes, overlays: overlays)
        #expect(list.purchased.map(\.wish.title) == ["Blanket", "Socks"])
        #expect(list.toBuy.map(\.wish.title) == ["Earrings", "Cookbook"])
    }

    @Test("The shopper's price override wins over the captured price")
    func priceOverrideWins() {
        let overlay = ShopperOverlay(wishID: earrings.id, priceOverride: Money(amount: 49))
        let item = ShoppingItem(wish: earrings, overlay: overlay)
        #expect(item.effectivePrice == Money(amount: 49))
    }

    @Test("Spend uses price paid, falling back to the effective price")
    func spendTotals() {
        let overlays = [
            ShopperOverlay(wishID: blanket.id, status: .bought, pricePaid: Money(amount: 60)),
            ShopperOverlay(wishID: earrings.id, status: .bought),
            ShopperOverlay(wishID: cookbook.id, status: .bought), // no price known anywhere
        ]
        let list = ShoppingList(wishes: wishes, overlays: overlays)
        #expect(list.spentByCurrency == ["USD": 115])
    }

    @Test("Overlays for deleted wishes are ignored")
    func orphanedOverlaysIgnored() {
        let orphan = ShopperOverlay(wishID: Wish.ID(), status: .bought, pricePaid: Money(amount: 999))
        let list = ShoppingList(wishes: wishes, overlays: [orphan])
        #expect(list.items.count == 4)
        #expect(list.spentByCurrency.isEmpty)
    }
}
