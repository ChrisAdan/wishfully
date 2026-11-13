import SwiftUI
import WishfullyCore

/// One list. The owner sees it as written; a shopper sees what is left to buy and what is
/// bought, with bought marks that stay on the shopper's phone and iCloud.
struct ListScreen: View {
    let listID: String
    @Environment(CloudStore.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var sheet: ListSheet?
    @State private var shareError: String?

    var body: some View {
        if let state = store.list(withID: listID) {
            list(state)
        } else {
            ContentUnavailableView("List unavailable", systemImage: "gift")
        }
    }

    private func list(_ state: ListState) -> some View {
        let shopping = ShoppingList(
            wishes: Array(state.wishes.values),
            overlays: state.isShopper ? Array(store.overlays.values) : []
        )
        return List {
            if let error = store.lastError ?? shareError {
                Text(error).font(.footnote).foregroundStyle(.red)
            }
            if !state.isShopper {
                rows(shopping.items, state: state)
            } else {
                ShoppingSummary(list: shopping)
                Section("To buy") { rows(shopping.toBuy, state: state) }
                if !shopping.purchased.isEmpty {
                    Section("Bought") { rows(shopping.purchased, state: state) }
                }
            }
        }
        .overlay {
            if state.wishes.isEmpty {
                EmptyListView(isRecipient: !state.isShopper)
            }
        }
        .navigationTitle(state.title)
        .refreshable { await store.refresh() }
        .navigationDestination(for: Wish.ID.self) { WishDetailView(wishID: $0, listID: listID) }
        .toolbar { toolbar(state) }
        .sheet(item: $sheet) { sheet in
            switch sheet {
            case .add: WishEditView(listID: listID, wish: nil)
            case .importNote: ImportView(listID: listID)
            case .settings: SettingsView()
            }
        }
    }

    private func rows(_ items: [ShoppingItem], state: ListState) -> some View {
        ForEach(items) { item in
            NavigationLink(value: item.id) {
                WishRow(item: item, showsPurchase: state.isShopper) {
                    Task { await store.setPurchased(!item.isPurchased, for: item.id) }
                }
            }
            .swipeActions(edge: .leading) {
                if let url = item.wish.url {
                    Button("Open", systemImage: "safari") { openURL(url) }
                        .tint(.blue)
                }
            }
            .swipeActions(edge: .trailing) {
                if state.canWrite {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        Task { await store.delete(item.id, from: listID) }
                    }
                }
            }
        }
    }

    @ToolbarContentBuilder
    private func toolbar(_ state: ListState) -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if state.canWrite {
                Button("Add", systemImage: "plus") { sheet = .add }
            }
        }
        ToolbarItem(placement: .topBarLeading) {
            Menu("More", systemImage: "ellipsis.circle") {
                if state.isOwner {
                    Button(
                        state.isShared ? "Manage sharing" : "Share list",
                        systemImage: "person.crop.circle.badge.plus"
                    ) {
                        presentSharing(state)
                    }
                }
                if state.canWrite {
                    Button("Import from a note", systemImage: "square.and.arrow.down") { sheet = .importNote }
                }
                Button("Settings", systemImage: "gearshape") { sheet = .settings }
            }
        }
    }

    private func presentSharing(_ state: ListState) {
        Task {
            do {
                let share = try await store.share(for: state.id)
                shareError = nil
                CloudSharing.present(share: share, title: state.title)
            } catch {
                shareError = CloudStore.describe(error)
            }
        }
    }
}

enum ListSheet: String, Identifiable {
    case add
    case importNote
    case settings

    var id: String {
        rawValue
    }
}

/// How far the shopping has got, and what it has cost.
struct ShoppingSummary: View {
    let list: ShoppingList

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(list.purchased.count) of \(list.items.count) bought")
                .font(.headline)
            let spent = list.spentByCurrency.sorted { $0.key < $1.key }
            if !spent.isEmpty {
                Text(spent.map { $0.value.formatted(.currency(code: $0.key)) }.joined(separator: " · ") + " spent")
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct EmptyListView: View {
    let isRecipient: Bool

    var body: some View {
        if isRecipient {
            ContentUnavailableView {
                Label("Nothing here yet", systemImage: "gift")
            } description: {
                Text("In Safari or a store's app, tap Share, then Wishfully. Or tap + to add something by hand.")
            }
        } else {
            ContentUnavailableView(
                "Nothing on the list yet",
                systemImage: "gift",
                description: Text("Wishes appear here as they are added. Tap + or ⋯, Import from a note, to add some.")
            )
        }
    }
}
