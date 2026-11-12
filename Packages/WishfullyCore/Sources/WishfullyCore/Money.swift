import Foundation

/// An amount of money in a specific currency.
///
/// Uses `Decimal`, never `Double`: binary floating point can't represent most
/// cent values exactly (0.1 + 0.2 != 0.3), and totals would drift.
public struct Money: Hashable, Codable, Sendable {
    public var amount: Decimal
    /// ISO 4217 code, for example "USD".
    public var currencyCode: String

    public init(amount: Decimal, currencyCode: String = "USD") {
        self.amount = amount
        self.currencyCode = currencyCode.uppercased()
    }
}

public extension [Money] {
    /// Sums amounts per currency. Different currencies are never added together.
    func totalsByCurrency() -> [String: Decimal] {
        reduce(into: [:]) { totals, money in
            totals[money.currencyCode, default: 0] += money.amount
        }
    }
}

public extension Money {
    /// Reads a price typed by hand ("68", "$1,299.99", "68,00"); nil for anything else.
    init?(parsing text: String, currencyCode: String = "USD") {
        guard let amount = PriceParsing.amount(from: text) else { return nil }
        self.init(amount: amount, currencyCode: currencyCode)
    }
}
