import CloudKit
import Foundation
import Observation
import WishfullyCore

/// The app's model: every list on this phone, kept in step with iCloud (decision 0017).
///
/// Each list is one record zone in its owner's private database. The owner shares the whole
/// zone, so the shopper reads it from their shared database. The shopper's bought marks live
/// in the `Shopper` zone of the shopper's private database, which the owner has no access to
/// (decision 0003).
@MainActor
@Observable
final class CloudStore {
    static let shared = CloudStore()

    var lists: [ListState]
    var overlays: [Wish.ID: ShopperOverlay]
    private(set) var lastSync: Date?
    var lastError: String?
    private(set) var isSyncing = false
    private(set) var hasSynced = false
    private(set) var accountDescription = "Checking"

    @ObservationIgnored let container = AppConfig.container
    @ObservationIgnored var snapshot: LocalSnapshot

    private init() {
        snapshot = LocalSnapshot.load()
        lists = snapshot.lists
        overlays = snapshot.overlays
        lastSync = snapshot.lastSync
    }

    func list(withID id: String) -> ListState? {
        lists.first { $0.id == id }
    }

    func overlay(for wish: Wish.ID) -> ShopperOverlay? {
        overlays[wish]
    }

    // MARK: - Sync

    /// Sends waiting writes, then reads every change since the last sync.
    func refresh() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer {
            isSyncing = false
            hasSynced = true
        }
        do {
            guard try await accountIsAvailable() else { return }
            await sendInbox()
            await sendPending()
            try await refreshLists(scope: .owned)
            try await refreshLists(scope: .shared)
            try await refreshOverlays()
            chooseShareTarget()
            snapshot.lastSync = Date()
            lastSync = snapshot.lastSync
            lastError = nil
            Log.sync.info("Synced \(self.lists.count) lists")
        } catch {
            lastError = Self.describe(error)
            Log.sync.error("Sync failed: \(error.localizedDescription, privacy: .public)")
        }
        persist()
    }

    private func accountIsAvailable() async throws -> Bool {
        let status = try await container.accountStatus()
        switch status {
        case .available:
            accountDescription = "Signed in"
            return true
        case .noAccount:
            accountDescription = "Not signed in"
            lastError = "Sign in to iCloud in Settings to sync your lists."
        case .restricted:
            accountDescription = "Restricted"
            lastError = "iCloud is restricted on this iPhone."
        case .temporarilyUnavailable:
            accountDescription = "Temporarily unavailable"
            lastError = "iCloud is temporarily unavailable. Try again in a moment."
        default:
            accountDescription = "Unknown"
            lastError = "iCloud status is unknown."
        }
        return false
    }

    private func refreshLists(scope: ListTarget.Scope) async throws {
        let database = scope == .owned ? container.privateCloudDatabase : container.sharedCloudDatabase
        let zones = try await database.allRecordZones()
            .filter { RecordSchema.listID(fromZoneName: $0.zoneID.zoneName) != nil }
        let zoneIDs = Set(zones.map(\.zoneID))
        // Lists whose zone has gone (deleted, or the share was left) leave this phone.
        lists.removeAll { $0.target.scope == scope && !zoneIDs.contains($0.target.zoneID) }
        for zone in zones {
            try await refreshList(in: zone.zoneID, scope: scope, database: database)
        }
        lists.sort { $0.list.createdAt < $1.list.createdAt }
    }

    private func refreshList(in zoneID: CKRecordZone.ID, scope: ListTarget.Scope, database: CKDatabase) async throws {
        guard let listID = RecordSchema.listID(fromZoneName: zoneID.zoneName) else { return }
        let target = ListTarget(scope: scope, zoneName: zoneID.zoneName, ownerName: zoneID.ownerName, title: "")
        var state = lists.first { $0.target.zoneID == zoneID } ?? ListState(
            target: target,
            list: Wishlist(id: listID, title: ""),
            canWrite: scope == .owned
        )
        let pendingIDs = Set(snapshot.pending.map(\.wishID))
        let changes = try await fetchChanges(in: zoneID, database: database, token: state.changeToken)
        if changes.isComplete {
            state.wishes = [:]
        }
        changes.records.forEach { Self.apply($0, to: &state, skipping: pendingIDs) }
        for recordID in changes.deletions {
            guard let uuid = UUID(uuidString: recordID.recordName) else { continue }
            state.wishes[Wish.ID(uuid)] = nil
            PhotoStore.remove(Wish.ID(uuid))
        }
        state.changeToken = changes.token
        try await readShare(in: zoneID, database: database, into: &state)
        state.target.title = state.title
        if let index = lists.firstIndex(where: { $0.target.zoneID == zoneID }) {
            lists[index] = state
        } else {
            lists.append(state)
        }
    }

    private static func apply(_ record: CKRecord, to state: inout ListState, skipping pending: Set<Wish.ID>) {
        switch record.recordType {
        case RecordSchema.RecordType.wishlist:
            if let list = Wishlist(recordName: record.recordID.recordName, fields: record.fieldValues) {
                state.list = list
            }
        case RecordSchema.RecordType.wish:
            guard let wish = Wish(
                recordName: record.recordID.recordName,
                fields: record.fieldValues,
                modifiedAt: record.modificationDate
            ), !pending.contains(wish.id) else { return }
            state.wishes[wish.id] = wish
            if let file = (record[RecordSchema.Field.image] as? CKAsset)?.fileURL {
                PhotoStore.copy(from: file, for: wish.id)
            }
        default:
            break
        }
    }

    /// Reads the zone-wide share: whether the owner has shared, and what this person may do.
    private func readShare(in zoneID: CKRecordZone.ID, database: CKDatabase, into state: inout ListState) async throws {
        let shareID = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zoneID)
        do {
            guard let share = try await database.record(for: shareID) as? CKShare else { return }
            state.isShared = share.participants.count > 1
            if state.target.scope == .shared {
                state.canWrite = share.currentUserParticipant?.permission == .readWrite
            }
        } catch let error as CKError where error.code == .unknownItem {
            state.isShared = false
        }
    }

    private func refreshOverlays() async throws {
        let database = container.privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: RecordSchema.shopperZoneName, ownerName: CKCurrentUserDefaultName)
        let pendingIDs = Set(snapshot.pending.map(\.wishID))
        var fetched = overlays
        do {
            let changes = try await fetchChanges(in: zoneID, database: database, token: snapshot.overlayToken)
            if changes.isComplete {
                fetched = [:]
            }
            for overlay in changes.records.compactMap({ ShopperOverlay(fields: $0.fieldValues) })
                where !pendingIDs.contains(overlay.wishID)
            {
                fetched[overlay.wishID] = overlay
            }
            snapshot.overlayToken = changes.token
        } catch let error as CKError where error.code == .zoneNotFound {
            // The zone appears with the first bought mark.
            snapshot.overlayToken = nil
        }
        overlays = fetched
    }

    /// Every change in a zone since a token. `isComplete` is true when the read started from
    /// nothing, so the caller replaces what it holds instead of merging.
    struct ZoneChanges {
        var records: [CKRecord] = []
        var deletions: [CKRecord.ID] = []
        var token: Data?
        var isComplete = false
    }

    /// Reads every change in a zone since `token`, page by page.
    func fetchChanges(in zoneID: CKRecordZone.ID, database: CKDatabase, token archived: Data?) async throws
        -> ZoneChanges
    {
        var token = archived.flatMap(Self.unarchiveToken)
        var result = ZoneChanges(isComplete: token == nil)
        var moreComing = true
        while moreComing {
            do {
                let changes = try await database.recordZoneChanges(inZoneWith: zoneID, since: token)
                for outcome in changes.modificationResultsByID.values {
                    if case let .success(modification) = outcome {
                        result.records.append(modification.record)
                    }
                }
                result.deletions += changes.deletions.map(\.recordID)
                token = changes.changeToken
                moreComing = changes.moreComing
            } catch let error as CKError where error.code == .changeTokenExpired && token != nil {
                // The server forgot the token: read the whole zone again.
                token = nil
                result = ZoneChanges(isComplete: true)
            }
        }
        result.token = token
            .flatMap { try? NSKeyedArchiver.archivedData(withRootObject: $0, requiringSecureCoding: true) }
        return result
    }

    private static func unarchiveToken(_ data: Data) -> CKServerChangeToken? {
        try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: data)
    }

    /// The Share extension adds to the first list this person owns, or else the first shared
    /// list they may write to.
    func chooseShareTarget() {
        let target = lists.first(where: \.isOwner) ?? lists.first(where: \.canWrite)
        ListTarget.saveShareTarget(target?.target)
    }

    func persist() {
        snapshot.lists = lists
        snapshot.overlays = overlays
        snapshot.save()
    }

    static func describe(_ error: any Error) -> String {
        guard let error = error as? CKError else { return error.localizedDescription }
        switch error.code {
        case .networkUnavailable, .networkFailure:
            return "Offline. Changes sync when the connection returns."
        case .notAuthenticated:
            return "Sign in to iCloud in Settings to sync your lists."
        case .quotaExceeded:
            return "iCloud storage is full."
        default:
            return "iCloud error \(error.code.rawValue): \(error.localizedDescription)"
        }
    }
}
