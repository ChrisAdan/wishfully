import Foundation
@testable import WishfullyCore

/// Shared test data. Invented items only: real list data never enters the repo.
enum Fixtures {
    static let day: TimeInterval = 86400
    static let start = Date(timeIntervalSince1970: 1_793_000_000)

    static func wish(
        _ title: String,
        price: Decimal? = nil,
        desire: Desire = .wouldLove,
        createdDaysAfterStart days: Double = 0
    ) -> Wish {
        Wish(
            title: title,
            price: price.map { Money(amount: $0) },
            desire: desire,
            createdAt: start.addingTimeInterval(days * day)
        )
    }
}
