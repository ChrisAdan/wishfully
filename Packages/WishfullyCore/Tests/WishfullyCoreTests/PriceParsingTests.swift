import Foundation
import Testing
@testable import WishfullyCore

@Suite("Price parsing")
struct PriceParsingTests {
    @Test("Common price formats parse to exact amounts", arguments: [
        ("68", "68"),
        ("68.00", "68"),
        ("$68.99", "68.99"),
        ("USD 1,299.99", "1299.99"),
        ("1.299,99 €", "1299.99"),
        ("68,00", "68"),
        ("1,299", "1299"),
        ("1.299,00", "1299"),
        ("  42.5 ", "42.5"),
    ])
    func parsesFormats(raw: String, expected: String) {
        #expect(PriceParsing.amount(from: raw) == Decimal(string: expected))
    }

    @Test("Text that isn't a plausible price is rejected", arguments: [
        "", "Free", "Call for price", "-5", "10-20", "0", "0.00", "9999999", "1.234.567", "...", ",",
    ])
    func rejectsJunk(raw: String) {
        #expect(PriceParsing.amount(from: raw) == nil)
    }

    @Test("Currency codes must be three letters")
    func currencyCodes() {
        #expect(PriceParsing.currencyCode(from: " usd ") == "USD")
        #expect(PriceParsing.currencyCode(from: "EUR") == "EUR")
        #expect(PriceParsing.currencyCode(from: "$") == nil)
        #expect(PriceParsing.currencyCode(from: "DOLLARS") == nil)
        #expect(PriceParsing.currencyCode(from: nil) == nil)
    }
}
