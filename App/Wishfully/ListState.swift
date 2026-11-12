import Foundation
import WishfullyCore

/// One list as this phone knows it: where it lives, its wishes and what this person may do.
struct ListState: Codable, Identifiable, Sendable {
    var target: ListTarget
    var list: Wishlist
    var wishes: [Wish.ID: Wish] = [:]
    /// True when this person may add, edit and delete wishes.
    var canWrite: Bool
    /// True once the owner has shared the list with someone.
    var isShared = false
    /// The CloudKit change token for the list's zone, archived.
    var changeToken: Data?

    var id: String {
        target.zoneName + "/" + target.ownerName
    }

    /// The owner sees the list as written; everyone it is shared with shops from it.
    var isOwner: Bool {
        target.scope == .owned
    }

    var title: String {
        list.title.isEmpty ? "Wishlist" : list.title
    }
}

/// A write that has not reached iCloud yet. Sent again on the next sync.
enum PendingWrite: Codable, Hashable, Sendable {
    case saveWish(Wish.ID, listID: String)
    case deleteWish(Wish.ID, listID: String)
    case overlay(Wish.ID)

    var wishID: Wish.ID {
        switch self {
        case let .saveWish(id, _), let .deleteWish(id, _), let .overlay(id): id
        }
    }
}

/// Everything the app keeps between launches, so the list shows before iCloud answers.
struct LocalSnapshot: Codable, Sendable {
    var lists: [ListState] = []
    var overlays: [Wish.ID: ShopperOverlay] = [:]
    var overlayToken: Data?
    var pending: [PendingWrite] = []
    var lastSync: Date?

    private static var file: URL {
        AppConfig.sharedFolder.appendingPathComponent("snapshot.json")
    }

    static func load() -> LocalSnapshot {
        guard let data = try? Data(contentsOf: file),
              let snapshot = try? JSONDecoder().decode(LocalSnapshot.self, from: data)
        else { return LocalSnapshot() }
        return snapshot
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}

/// Product photos on disk, one JPEG per wish.
enum PhotoStore {
    private static var folder: URL {
        AppConfig.sharedFolder.appendingPathComponent("Photos", isDirectory: true)
    }

    static func url(for wish: Wish.ID) -> URL {
        folder.appendingPathComponent(wish.description + ".jpg")
    }

    static func photo(for wish: Wish.ID) -> Data? {
        try? Data(contentsOf: url(for: wish))
    }

    static func store(_ data: Data, for wish: Wish.ID) {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? data.write(to: url(for: wish), options: .atomic)
    }

    static func copy(from file: URL, for wish: Wish.ID) {
        guard let data = try? Data(contentsOf: file) else { return }
        store(data, for: wish)
    }

    static func remove(_ wish: Wish.ID) {
        try? FileManager.default.removeItem(at: url(for: wish))
    }
}
