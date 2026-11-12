import CloudKit
import Foundation
import WishfullyCore

/// Copies `FieldValue`s from WishfullyCore into CloudKit records and back.
extension CKRecord {
    func apply(_ fields: [String: FieldValue]) {
        for (key, value) in fields {
            switch value {
            case let .string(text): self[key] = text as NSString
            case let .int(number): self[key] = NSNumber(value: number)
            case let .date(date): self[key] = date as NSDate
            case .empty: self[key] = nil
            }
        }
    }

    var fieldValues: [String: FieldValue] {
        var values: [String: FieldValue] = [:]
        for key in allKeys() {
            switch self[key] {
            case let text as String: values[key] = .string(text)
            case let date as Date: values[key] = .date(date)
            case let number as NSNumber: values[key] = .int(number.intValue)
            default: break
            }
        }
        return values
    }
}

/// Saves wishes to CloudKit. Shared by the app and the Share extension, so both write the
/// same record shape.
enum WishWriter {
    /// Saves a wish into its list's zone. A photo, when given, replaces the stored one;
    /// without one the stored photo stays as it is.
    static func save(_ wish: Wish, photo: Data?, to target: ListTarget, in container: CKContainer) async throws {
        let recordID = CKRecord.ID(recordName: wish.id.description, zoneID: target.zoneID)
        let record = CKRecord(recordType: RecordSchema.RecordType.wish, recordID: recordID)
        record.apply(wish.recordFields)
        let photoFile = try photo.map(writeTemporaryFile)
        defer { photoFile.map { try? FileManager.default.removeItem(at: $0) } }
        if let photoFile {
            record[RecordSchema.Field.image] = CKAsset(fileURL: photoFile)
        }
        try await save([record], in: target.database(in: container))
    }

    /// Saves records, overwriting only the fields each record sets.
    static func save(_ records: [CKRecord], in database: CKDatabase) async throws {
        guard !records.isEmpty else { return }
        let result = try await database.modifyRecords(
            saving: records,
            deleting: [],
            savePolicy: .changedKeys,
            atomically: false
        )
        for (_, outcome) in result.saveResults {
            if case let .failure(error) = outcome {
                throw error
            }
        }
    }

    private static func writeTemporaryFile(_ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
        try data.write(to: url, options: .atomic)
        return url
    }
}
