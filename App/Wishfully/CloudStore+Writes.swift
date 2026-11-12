import CloudKit
import Foundation
import WishfullyCore

/// Writes: lists, wishes, bought marks, the Share extension's inbox and sharing.
extension CloudStore {
    /// Creates a list owned by this person, in a zone of its own.
    func createList(title: String) async {
        let list = Wishlist(title: title)
        let zoneID = CKRecordZone.ID(zoneName: RecordSchema.zoneName(for: list.id), ownerName: CKCurrentUserDefaultName)
        let target = ListTarget(scope: .owned, zoneName: zoneID.zoneName, ownerName: zoneID.ownerName, title: title)
        let record = CKRecord(
            recordType: RecordSchema.RecordType.wishlist,
            recordID: CKRecord.ID(recordName: list.id.description, zoneID: zoneID)
        )
        record.apply(list.recordFields)
        do {
            _ = try await container.privateCloudDatabase.modifyRecordZones(
                saving: [CKRecordZone(zoneID: zoneID)],
                deleting: []
            )
            try await WishWriter.save([record], in: container.privateCloudDatabase)
            lists.append(ListState(target: target, list: list, canWrite: true))
            chooseShareTarget()
            lastError = nil
        } catch {
            lastError = Self.describe(error)
        }
        persist()
    }

    /// Saves a new or edited wish. The phone shows it at once; iCloud receives it now or on
    /// the next sync.
    func save(_ wish: Wish, photo: Data?, in listID: String) async {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[index].wishes[wish.id] = wish
        if let photo {
            PhotoStore.store(photo, for: wish.id)
        }
        await send(.saveWish(wish.id, listID: listID))
    }

    func importWishes(_ wishes: [Wish], into listID: String) async {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        for wish in wishes {
            lists[index].wishes[wish.id] = wish
        }
        let target = lists[index].target
        let records = wishes.map { wish in
            let record = CKRecord(
                recordType: RecordSchema.RecordType.wish,
                recordID: CKRecord.ID(recordName: wish.id.description, zoneID: target.zoneID)
            )
            record.apply(wish.recordFields)
            return record
        }
        do {
            // CloudKit takes at most 400 records per request.
            for start in stride(from: 0, to: records.count, by: 400) {
                let batch = Array(records[start ..< min(start + 400, records.count)])
                try await WishWriter.save(batch, in: target.database(in: container))
            }
            lastError = nil
        } catch {
            lastError = Self.describe(error)
            snapshot.pending += wishes.map { .saveWish($0.id, listID: listID) }
        }
        persist()
    }

    func delete(_ wish: Wish.ID, from listID: String) async {
        guard let index = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[index].wishes[wish] = nil
        PhotoStore.remove(wish)
        await send(.deleteWish(wish, listID: listID))
    }

    /// Marks a wish bought or not. The mark stays in this person's private database.
    func setPurchased(_ purchased: Bool, for wish: Wish.ID) async {
        overlays[wish] = ShopperOverlay(
            wishID: wish,
            status: purchased ? .bought : .notBought,
            boughtAt: purchased ? Date() : nil
        )
        await send(.overlay(wish))
    }

    private func send(_ write: PendingWrite) async {
        do {
            try await perform(write)
            lastError = nil
        } catch {
            lastError = Self.describe(error)
            if !snapshot.pending.contains(write) {
                snapshot.pending.append(write)
            }
        }
        persist()
    }

    func sendPending() async {
        for write in snapshot.pending {
            do {
                try await perform(write)
                snapshot.pending.removeAll { $0 == write }
            } catch {
                Log.sync.error("Pending write failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func perform(_ write: PendingWrite) async throws {
        switch write {
        case let .saveWish(id, listID):
            guard let state = list(withID: listID), let wish = state.wishes[id] else { return }
            try await WishWriter.save(wish, photo: PhotoStore.photo(for: id), to: state.target, in: container)
        case let .deleteWish(id, listID):
            guard let state = list(withID: listID) else { return }
            let recordID = CKRecord.ID(recordName: id.description, zoneID: state.target.zoneID)
            _ = try await state.target.database(in: container).modifyRecords(saving: [], deleting: [recordID])
        case let .overlay(id):
            guard let overlay = overlays[id] else { return }
            try await saveOverlay(overlay)
        }
    }

    private func saveOverlay(_ overlay: ShopperOverlay) async throws {
        let database = container.privateCloudDatabase
        let zoneID = CKRecordZone.ID(zoneName: RecordSchema.shopperZoneName, ownerName: CKCurrentUserDefaultName)
        let record = CKRecord(
            recordType: RecordSchema.RecordType.overlay,
            recordID: CKRecord.ID(recordName: RecordSchema.overlayRecordName(for: overlay.wishID), zoneID: zoneID)
        )
        record.apply(overlay.recordFields)
        do {
            try await WishWriter.save([record], in: database)
        } catch let error as CKError where error.code == .zoneNotFound || error.code == .partialFailure {
            _ = try await database.modifyRecordZones(saving: [CKRecordZone(zoneID: zoneID)], deleting: [])
            try await WishWriter.save([record], in: database)
        }
    }

    /// Sends wishes the Share extension kept on the phone while iCloud was unreachable.
    func sendInbox() async {
        for (entry, photo) in Inbox.entries() {
            do {
                try await WishWriter.save(entry.wish, photo: photo, to: entry.target, in: container)
                if let photo {
                    PhotoStore.store(photo, for: entry.wish.id)
                }
                Inbox.remove(entry.wish.id)
            } catch {
                Log.sync.error("Inbox entry failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Sharing

    /// The list's zone-wide share, created on first use. Only the owner calls this.
    func share(for listID: String) async throws -> CKShare {
        guard let state = list(withID: listID), state.isOwner else { throw CKError(.permissionFailure) }
        let database = container.privateCloudDatabase
        let shareID = CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: state.target.zoneID)
        do {
            if let existing = try await database.record(for: shareID) as? CKShare {
                return existing
            }
        } catch let error as CKError where error.code == .unknownItem {
            Log.share.info("Creating the share for a list")
        }
        let share = CKShare(recordZoneID: state.target.zoneID)
        share[CKShare.SystemFieldKey.title] = state.title as NSString
        share.publicPermission = .none
        try await WishWriter.save([share], in: database)
        return share
    }

    /// Accepts a list someone shared through a link, then reads it.
    func accept(_ metadata: CKShare.Metadata) async {
        do {
            _ = try await container.accept(metadata)
            Log.share.info("Accepted a shared list")
        } catch {
            lastError = Self.describe(error)
        }
        await refresh()
    }
}
