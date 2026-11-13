import SwiftUI

/// Sync status for checking on the phone (decision 0016, G2): the iCloud account, the last
/// sync, the last error and where the Share sheet adds wishes.
struct SettingsView: View {
    @Environment(CloudStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("iCloud") {
                    LabeledContent("Account", value: store.accountDescription)
                    LabeledContent("Last synced") {
                        if let date = store.lastSync {
                            Text("\(date, style: .relative) ago")
                        } else {
                            Text("Not yet")
                        }
                    }
                    if let error = store.lastError {
                        Text(error).foregroundStyle(.red)
                    }
                    Button {
                        Task { await store.refresh() }
                    } label: {
                        if store.isSyncing {
                            ProgressView()
                        } else {
                            Text("Sync now")
                        }
                    }
                }
                Section("Share button") {
                    LabeledContent("Adds to", value: ListTarget.loadShareTarget()?.title ?? "No list yet")
                }
                Section("Lists on this iPhone") {
                    ForEach(store.lists) { state in
                        LabeledContent(
                            state.title,
                            value: state.isShopper ? "Shopping" : (state.isShared ? "Mine, shared" : "Mine")
                        )
                    }
                }
                Section {
                    LabeledContent("Version", value: version)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}
