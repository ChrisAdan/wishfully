import CloudKit
import Foundation
import WishfullyCore

/// Where a list lives in iCloud: the database scope and the record zone.
///
/// The person who created the list reads it from their private database (`owned`); everyone
/// it is shared with reads it from their shared database (`shared`).
struct ListTarget: Codable, Hashable, Sendable {
    enum Scope: String, Codable, Sendable {
        case owned
        case shared
    }

    var scope: Scope
    var zoneName: String
    var ownerName: String
    /// The list's title, shown by the Share extension as the place a wish goes.
    var title: String

    var zoneID: CKRecordZone.ID {
        CKRecordZone.ID(zoneName: zoneName, ownerName: ownerName)
    }

    var listID: Wishlist.ID? {
        RecordSchema.listID(fromZoneName: zoneName)
    }

    func database(in container: CKContainer) -> CKDatabase {
        scope == .owned ? container.privateCloudDatabase : container.sharedCloudDatabase
    }

    // MARK: - The Share extension's target

    private static let defaultsKey = "shareTarget"

    /// The list the Share extension adds to, chosen by the app after each sync.
    static func loadShareTarget() -> ListTarget? {
        guard let data = AppConfig.sharedDefaults.data(forKey: defaultsKey) else { return nil }
        return try? JSONDecoder().decode(ListTarget.self, from: data)
    }

    static func saveShareTarget(_ target: ListTarget?) {
        let data = target.flatMap { try? JSONEncoder().encode($0) }
        AppConfig.sharedDefaults.set(data, forKey: defaultsKey)
    }
}
