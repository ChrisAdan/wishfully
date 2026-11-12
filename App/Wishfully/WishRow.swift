import SwiftUI
import UIKit
import WishfullyCore

/// One wish in a list: photo, title, store and price, how much it is wanted, and for a
/// shopper the bought checkbox.
struct WishRow: View {
    let item: ShoppingItem
    let showsPurchase: Bool
    let togglePurchase: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if showsPurchase {
                Button(action: togglePurchase) {
                    Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(item.isPurchased ? Palette.accent : .secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(item.isPurchased ? "Bought" : "Not bought")
                .accessibilityHint("Marks this as bought or not bought")
            }
            WishPhoto(wishID: item.id, side: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.wish.title)
                    .strikethrough(item.isPurchased)
                    .lineLimit(2)
                Text(item.wish.detailLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            DesireMark(desire: item.wish.desire)
        }
    }
}

extension Wish {
    /// "shop.example · $68.00", leaving out whatever is missing.
    var detailLine: String {
        [store, price.map(\.formatted)].compactMap(\.self).joined(separator: " · ")
    }
}

extension Money {
    var formatted: String {
        amount.formatted(.currency(code: currencyCode))
    }
}

/// Hearts for how much a wish is wanted: one, two or three.
struct DesireMark: View {
    let desire: Desire

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0 ..< desire.rawValue, id: \.self) { _ in
                Image(systemName: "heart.fill")
            }
        }
        .font(.caption2)
        .foregroundStyle(Palette.accent)
        .accessibilityElement()
        .accessibilityLabel(desire.label)
    }
}

/// A wish's product photo, or a gift symbol when it has none.
struct WishPhoto: View {
    let wishID: Wish.ID
    let side: CGFloat
    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image(systemName: "gift").foregroundStyle(.secondary)
            }
        }
        .frame(width: side, height: side)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: side / 6))
        .accessibilityHidden(true)
        .task(id: wishID) {
            image = PhotoStore.photo(for: wishID).flatMap(UIImage.init(data:))
        }
    }
}
