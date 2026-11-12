import Foundation
import WishfullyCore

/// Wishes the Share extension saved on the phone because iCloud was unreachable.
/// The app sends them to iCloud on its next sync.
struct InboxEntry: Codable, Sendable {
    var wish: Wish
    var target: ListTarget
}

enum Inbox {
    private static var folder: URL {
        AppConfig.sharedFolder.appendingPathComponent("Inbox", isDirectory: true)
    }

    static func add(_ entry: InboxEntry, photo: Data?) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let base = folder.appendingPathComponent(entry.wish.id.description)
        try photo?.write(to: base.appendingPathExtension("jpg"), options: .atomic)
        try JSONEncoder().encode(entry).write(to: base.appendingPathExtension("json"), options: .atomic)
    }

    /// Every waiting entry with its photo, oldest first.
    static func entries() -> [(entry: InboxEntry, photo: Data?)] {
        let files = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { file in
                guard let data = try? Data(contentsOf: file),
                      let entry = try? JSONDecoder().decode(InboxEntry.self, from: data)
                else { return nil }
                return (entry, try? Data(contentsOf: file.deletingPathExtension().appendingPathExtension("jpg")))
            }
            .sorted { $0.entry.wish.createdAt < $1.entry.wish.createdAt }
    }

    static func remove(_ wish: Wish.ID) {
        let base = folder.appendingPathComponent(wish.description)
        for ext in ["json", "jpg"] {
            try? FileManager.default.removeItem(at: base.appendingPathExtension(ext))
        }
    }
}
