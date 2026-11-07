import Foundation
import Testing
@testable import WishfullyCore

@Suite("Models")
struct ModelTests {
    @Test("Identifiers encode as a bare UUID string")
    func identifierEncodesAsString() throws {
        let uuid = try #require(UUID(uuidString: "6F9619FF-8B86-D011-B42D-00C04FC964FF"))
        let data = try JSONEncoder().encode(Wish.ID(uuid))
        #expect(String(bytes: data, encoding: .utf8) == "\"6F9619FF-8B86-D011-B42D-00C04FC964FF\"")
    }

    @Test("A wish survives a JSON round trip unchanged")
    func wishRoundTrips() throws {
        let original = Wish(
            title: "Linen throw blanket",
            url: URL(string: "https://example.com/blanket"),
            price: Money(amount: Decimal(string: "68.00") ?? 0),
            store: "example.com",
            note: "Oat color",
            desire: .dreamGift,
            category: "Cozy",
            createdAt: Fixtures.start
        )
        let decoded = try JSONDecoder().decode(Wish.self, from: JSONEncoder().encode(original))
        #expect(decoded == original)
    }

    @Test("updatedAt defaults to createdAt")
    func updatedAtDefaults() {
        let wish = Fixtures.wish("Slippers")
        #expect(wish.updatedAt == wish.createdAt)
    }

    @Test("Currency codes are normalized to upper case")
    func currencyCodeUppercased() {
        #expect(Money(amount: 1, currencyCode: "usd").currencyCode == "USD")
    }

    @Test("Decimal money adds exactly where Double would not")
    func decimalIsExact() {
        let total = [Money(amount: Decimal(string: "0.1") ?? 0), Money(amount: Decimal(string: "0.2") ?? 0)]
            .totalsByCurrency()
        #expect(total["USD"] == Decimal(string: "0.3"))
    }

    @Test("Totals never mix currencies")
    func totalsSeparateCurrencies() {
        let totals = [Money(amount: 10), Money(amount: 5, currencyCode: "EUR"), Money(amount: 2)]
            .totalsByCurrency()
        #expect(totals == ["USD": 12, "EUR": 5])
    }

    @Test("Desire levels order from nice-to-have to dream gift")
    func desireOrdering() {
        #expect(Desire.allCases.sorted() == [.niceToHave, .wouldLove, .dreamGift])
        #expect(Desire.dreamGift.label == "Dream gift")
    }
}
