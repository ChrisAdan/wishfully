import Foundation
import Testing
@testable import WishfullyCore

@Suite("Record fields")
struct RecordFieldsTests {
    static let full = Wish(
        title: "Linen throw",
        url: URL(string: "https://shop.example/p/7"),
        price: Money(amount: Decimal(string: "1299.99") ?? 0, currencyCode: "eur"),
        store: "shop.example",
        note: "Oat colour",
        desire: .dreamGift,
        category: "Home",
        createdAt: Fixtures.start
    )

    @Test("A wish survives the trip through record fields", arguments: [
        full,
        Wish(title: "Plain", desire: .niceToHave, createdAt: Fixtures.start),
    ])
    func wishRoundTrip(wish: Wish) {
        let fields = wish.recordFields.filter { $0.value != .empty }
        let restored = Wish(recordName: wish.id.description, fields: fields, modifiedAt: Fixtures.start)
        #expect(restored == wish)
    }

    @Test("Missing values become empty fields, so an edit clears them")
    func missingValuesClearFields() {
        let fields = Wish(title: "Plain").recordFields
        for key in [RecordSchema.Field.url, RecordSchema.Field.priceAmount, RecordSchema.Field.store] {
            #expect(fields[key] == .empty)
        }
    }

    @Test("Wishlists and overlays survive the trip through record fields")
    func listAndOverlayRoundTrip() {
        for list in [
            Wishlist(title: "Christmas", createdAt: Fixtures.start),
            Wishlist(title: "Christmas", recipient: "Alex", createdAt: Fixtures.start),
        ] {
            let fields = list.recordFields.filter { $0.value != .empty }
            #expect(Wishlist(recordName: list.id.description, fields: fields) == list)
        }
        let overlay = ShopperOverlay(wishID: Self.full.id, status: .bought, boughtAt: Fixtures.start)
        #expect(ShopperOverlay(fields: overlay.recordFields) == overlay)
    }

    @Test("Records with unreadable identifiers are skipped")
    func rejectsBadIdentifiers() {
        #expect(Wish(recordName: "nope", fields: [:], modifiedAt: nil) == nil)
        #expect(Wishlist(recordName: "nope", fields: [:]) == nil)
        #expect(ShopperOverlay(fields: [RecordSchema.Field.wishID: .int(3)]) == nil)
    }

    @Test("Zone names carry the list's identifier")
    func zoneNames() {
        let list = Wishlist.ID()
        #expect(RecordSchema.listID(fromZoneName: RecordSchema.zoneName(for: list)) == list)
        #expect(RecordSchema.listID(fromZoneName: RecordSchema.shopperZoneName) == nil)
        #expect(RecordSchema.listID(fromZoneName: "list-garbage") == nil)
        #expect(RecordSchema.overlayRecordName(for: Self.full.id).hasSuffix(Self.full.id.description))
    }
}
