import SwiftUI
import UIKit
import WishfullyCore

/// A wish being written: from the Share sheet, the add screen or an edit.
struct WishDraft: Sendable {
    var title = ""
    var urlText = ""
    var priceText = ""
    var currencyCode = "USD"
    var store: String?
    var note = ""
    var desire = Desire.wouldLove
    var category: String?
    var photo: Data?

    init() {}

    init(wish: Wish, photo: Data?) {
        title = wish.title
        urlText = wish.url?.absoluteString ?? ""
        priceText = wish.price.map { "\($0.amount)" } ?? ""
        currencyCode = wish.price?.currencyCode ?? "USD"
        store = wish.store
        note = wish.note
        desire = wish.desire
        category = wish.category
        self.photo = photo
    }

    var url: URL? {
        SharedText(urlText).url
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Fills the empty fields from a fetched page; anything typed already stays.
    mutating func fill(from page: FetchedPage) {
        if title.isEmpty, let pageTitle = page.metadata.title {
            title = pageTitle
        }
        if priceText.isEmpty, let price = page.metadata.price {
            priceText = "\(price.amount)"
            currencyCode = price.currencyCode
        }
        store = store ?? page.metadata.store
        photo = photo ?? page.photo
    }

    /// The finished wish. `base` keeps the identity and creation date of an edited wish.
    func wish(updating base: Wish? = nil) -> Wish {
        let link = url
        return Wish(
            id: base?.id ?? Wish.ID(),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            url: link,
            price: Money(parsing: priceText, currencyCode: currencyCode),
            store: link == nil ? nil : store ?? link?.host(),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            desire: desire,
            category: category,
            createdAt: base?.createdAt ?? Date()
        )
    }
}

/// The fields of a wish, shared by the Share extension and the app's add and edit screens.
struct WishFormFields: View {
    @Binding var draft: WishDraft
    var isFetching: Bool
    /// Reads the page at the link into empty fields; nil hides the button.
    var fetch: (() -> Void)?

    var body: some View {
        if let photo = draft.photo, let image = UIImage(data: photo) {
            Section {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 220)
                    .accessibilityLabel("Product photo")
                Button("Remove photo", role: .destructive) { draft.photo = nil }
            }
        }
        Section("Item") {
            TextField("What is it?", text: $draft.title, axis: .vertical)
                .lineLimit(1 ... 4)
            HStack {
                TextField("Link", text: $draft.urlText)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if let fetch {
                    if isFetching {
                        ProgressView()
                    } else {
                        Button("Fill in", action: fetch)
                            .disabled(draft.url == nil)
                    }
                }
            }
            TextField("Price", text: $draft.priceText)
                .keyboardType(.decimalPad)
        }
        Section {
            Picker("How much?", selection: $draft.desire) {
                ForEach(Desire.allCases.reversed(), id: \.self) { desire in
                    Text(desire.label).tag(desire)
                }
            }
            TextField("Size, colour, anything that helps", text: $draft.note, axis: .vertical)
                .lineLimit(1 ... 5)
        }
    }
}
