import SwiftUI
import UIKit
import WishfullyCore

/// A wish in full, with the link to the store. A shopper marks it bought here; anyone who may
/// write edits it.
struct WishDetailView: View {
    let wishID: Wish.ID
    let listID: String
    @Environment(CloudStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var isEditing = false
    @State private var confirmsDelete = false

    var body: some View {
        if let state = store.list(withID: listID), let wish = state.wishes[wishID] {
            detail(wish, state: state)
        } else {
            ContentUnavailableView("This wish was removed", systemImage: "gift")
        }
    }

    private func detail(_ wish: Wish, state: ListState) -> some View {
        let bought = store.overlay(for: wish.id)?.status.isPurchased ?? false
        return List {
            Section {
                WishPhoto(wishID: wish.id, side: 260)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }
            WishFacts(wish: wish)
            if !state.isOwner {
                Section {
                    Toggle("Bought", isOn: Binding(
                        get: { bought },
                        set: { value in Task { await store.setPurchased(value, for: wish.id) } }
                    ))
                } footer: {
                    Text("Bought marks stay in your iCloud. The list's owner never sees them.")
                }
            }
            if state.canWrite {
                Section {
                    Button("Delete wish", role: .destructive) { confirmsDelete = true }
                }
            }
        }
        .navigationTitle(wish.store ?? "Wish")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if state.canWrite {
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) { WishEditView(listID: listID, wish: wish) }
        .confirmationDialog("Delete this wish?", isPresented: $confirmsDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    await store.delete(wish.id, from: listID)
                    dismiss()
                }
            }
        }
    }
}

/// The wish's details and its link to the store.
struct WishFacts: View {
    let wish: Wish

    var body: some View {
        Section {
            Text(wish.title).font(.title3.weight(.semibold))
            if let price = wish.price {
                LabeledContent("Price", value: price.formatted)
            }
            if let store = wish.store {
                LabeledContent("Store", value: store)
            }
            LabeledContent("Wanted", value: wish.desire.label)
            if !wish.note.isEmpty {
                Text(wish.note)
            }
        }
        if let url = wish.url {
            Section {
                Link(destination: url) {
                    Label("Open at \(wish.store ?? "the store")", systemImage: "safari")
                }
            }
        }
    }
}
