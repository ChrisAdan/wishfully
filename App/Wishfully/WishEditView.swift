import SwiftUI
import WishfullyCore

/// Adds a wish by hand, or edits one. A pasted link fills in the empty fields.
struct WishEditView: View {
    let listID: String
    let wish: Wish?
    @Environment(CloudStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var draft = WishDraft()
    @State private var isFetching = false
    @State private var hasLoaded = false

    var body: some View {
        NavigationStack {
            Form {
                WishFormFields(draft: $draft, isFetching: isFetching, fetch: fetch)
            }
            .navigationTitle(wish == nil ? "New wish" : "Edit wish")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!draft.canSave)
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !hasLoaded else { return }
        hasLoaded = true
        if let wish {
            draft = WishDraft(wish: wish, photo: PhotoStore.photo(for: wish.id))
        }
    }

    private func fetch() {
        guard let url = draft.url else { return }
        isFetching = true
        Task {
            let page = await PageFetcher.fetch(url)
            draft.fill(from: page)
            isFetching = false
        }
    }

    private func save() {
        let original = wish.flatMap { PhotoStore.photo(for: $0.id) }
        let finished = draft.wish(updating: wish)
        // The photo is sent only when it changed. A removed photo leaves this phone in v0;
        // iCloud keeps its copy.
        let photo = draft.photo == original ? nil : draft.photo
        if wish != nil, draft.photo == nil, original != nil {
            PhotoStore.remove(finished.id)
        }
        Task { await store.save(finished, photo: photo, in: listID) }
        dismiss()
    }
}
