import SwiftUI

enum Palette {
    static let accent = Color("AccentColor")
}

/// The first screen: a welcome while there is no list, the list itself when there is one,
/// and a list of lists when there are several.
struct RootView: View {
    @Environment(CloudStore.self) private var store

    /// Seconds between syncs while the app is open, so a new wish appears on the other phone.
    private static let syncInterval = 60

    var body: some View {
        NavigationStack {
            content
        }
        .task {
            await store.refresh()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.syncInterval))
                await store.refresh()
            }
        }
    }

    @ViewBuilder private var content: some View {
        if store.lists.isEmpty {
            if store.hasSynced {
                WelcomeView()
            } else {
                ProgressView("Opening your lists")
            }
        } else if store.lists.count == 1, let only = store.lists.first {
            ListScreen(listID: only.id)
        } else {
            HomeView()
        }
    }
}

/// Every list on this phone: the ones this person owns and the ones shared with them.
struct HomeView: View {
    @Environment(CloudStore.self) private var store
    @State private var showsSettings = false

    var body: some View {
        List {
            section("My lists", lists: store.lists.filter(\.isOwner))
            section("Shopping for", lists: store.lists.filter { !$0.isOwner })
        }
        .navigationTitle("Wishfully")
        .refreshable { await store.refresh() }
        .toolbar {
            Button("Settings", systemImage: "gearshape") { showsSettings = true }
        }
        .sheet(isPresented: $showsSettings) { SettingsView() }
        .navigationDestination(for: String.self) { ListScreen(listID: $0) }
    }

    @ViewBuilder
    private func section(_ title: String, lists: [ListState]) -> some View {
        if !lists.isEmpty {
            Section(title) {
                ForEach(lists) { state in
                    NavigationLink(value: state.id) {
                        LabeledContent(state.title, value: "\(state.wishes.count)")
                    }
                }
            }
        }
    }
}

/// Shown before any list exists on this phone.
struct WelcomeView: View {
    @Environment(CloudStore.self) private var store
    @State private var title = "My wishlist"
    @State private var isCreating = false

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "gift")
                        .font(.largeTitle)
                        .foregroundStyle(Palette.accent)
                        .accessibilityHidden(true)
                    Text("Make a list, then share it with the person shopping for you.")
                    Text("Add things from any app with the Share button: tap Wishfully in the row of apps.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            Section("Your list") {
                TextField("Name", text: $title)
                Button {
                    isCreating = true
                    Task {
                        await store.createList(title: title.trimmingCharacters(in: .whitespacesAndNewlines))
                        isCreating = false
                    }
                } label: {
                    if isCreating {
                        ProgressView()
                    } else {
                        Text("Create my list")
                    }
                }
                .disabled(isCreating || title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            Section {
                Text("Shopping for someone? Open the link they sent you in Messages, and their list appears here.")
                    .foregroundStyle(.secondary)
            }
            if let error = store.lastError {
                Section { Text(error).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Wishfully")
        .refreshable { await store.refresh() }
    }
}
