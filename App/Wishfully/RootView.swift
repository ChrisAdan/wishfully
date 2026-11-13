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
            section("My lists", lists: store.lists.filter { !$0.isShopper })
            section("Shopping for", lists: store.lists.filter(\.isShopper))
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

/// Shown before any list exists on this phone. A list is for this person, who shares it with
/// whoever shops for them, or for someone else, which this person shops from and shares with them.
struct WelcomeView: View {
    @Environment(CloudStore.self) private var store
    @State private var isForSomeoneElse = false
    @State private var recipient = ""
    @State private var isCreating = false

    private var trimmedRecipient: String {
        recipient.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var title: String {
        isForSomeoneElse ? "\(trimmedRecipient)'s wishlist" : "My wishlist"
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "gift")
                        .font(.largeTitle)
                        .foregroundStyle(Palette.accent)
                        .accessibilityHidden(true)
                    Text("Make a wishlist, then share it with a link in Messages.")
                    Text("Whoever the list is for adds things from any app with the Share button.")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            Section {
                Picker("Who is this list for?", selection: $isForSomeoneElse) {
                    Text("Me").tag(false)
                    Text("Someone else").tag(true)
                }
                .pickerStyle(.segmented)
                if isForSomeoneElse {
                    TextField("Their name", text: $recipient)
                        .textContentType(.givenName)
                }
                Button(action: create) {
                    if isCreating {
                        ProgressView()
                    } else {
                        Text(isForSomeoneElse ? "Create their list" : "Create my list")
                    }
                }
                .disabled(isCreating || (isForSomeoneElse && trimmedRecipient.isEmpty))
            } footer: {
                if isForSomeoneElse {
                    Text(
                        "You shop from this list; your bought marks stay in your iCloud. They see the list without them."
                    )
                }
            }
            Section {
                Text("Someone sent you a list? Open their link in Messages, and it appears here.")
                    .foregroundStyle(.secondary)
            }
            if let error = store.lastError {
                Section { Text(error).foregroundStyle(.red) }
            }
        }
        .navigationTitle("Wishfully")
        .refreshable { await store.refresh() }
    }

    private func create() {
        isCreating = true
        Task {
            await store.createList(title: title, recipient: isForSomeoneElse ? trimmedRecipient : nil)
            isCreating = false
        }
    }
}
