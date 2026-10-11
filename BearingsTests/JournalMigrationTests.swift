import Foundation
import SwiftData
import XCTest
@testable import Bearings

/// Frozen pre-AI shape. Keeping its entity name JournalEntry exercises the
/// store's real additive migration rather than seeding the current schema.
private enum LegacyJournalSchema: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }
    static var models: [any PersistentModel.Type] { [JournalEntry.self] }

    @Model
    final class JournalEntry {
        @Attribute(.unique) var id: UUID
        var dayKey: String
        var body: String
        var periodRawValue: String
        var createdAt: Date
        var modifiedAt: Date

        init(id: UUID, dayKey: String, body: String, periodRawValue: String,
             createdAt: Date, modifiedAt: Date) {
            self.id = id
            self.dayKey = dayKey
            self.body = body
            self.periodRawValue = periodRawValue
            self.createdAt = createdAt
            self.modifiedAt = modifiedAt
        }
    }
}

final class JournalMigrationTests: XCTestCase {
    @MainActor
    func testExistingFileBackedJournalMigratesWithoutInventingCreationZone() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BearingsMigrationTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("Journal.store")
        let firstID = UUID()
        let secondID = UUID()
        let created = Date(timeIntervalSince1970: 1_650_000_000)
        let modified = created.addingTimeInterval(600)
        try autoreleasepool {
            let schema = Schema(versionedSchema: LegacyJournalSchema.self)
            XCTAssertEqual(Set(schema.entitiesByName.keys), ["JournalEntry"])
            let configuration = ModelConfiguration("ReCollect", schema: schema, url: url, cloudKitDatabase: .none)
            let legacy = try ModelContainer(for: schema, configurations: [configuration])
            legacy.mainContext.autosaveEnabled = false
            legacy.mainContext.insert(LegacyJournalSchema.JournalEntry(
                id: firstID, dayKey: "2011-12-30", body: "Legacy writing on a civil day skipped in Samoa.",
                periodRawValue: "morning", createdAt: created, modifiedAt: modified
            ))
            legacy.mainContext.insert(LegacyJournalSchema.JournalEntry(
                id: secondID, dayKey: "2026-03-08", body: "Legacy writing on a daylight saving day.",
                periodRawValue: "evening", createdAt: created, modifiedAt: created
            ))
            try legacy.mainContext.save()
        }

        try autoreleasepool {
            let migrated = try PersistenceController.makeContainer(storeURL: url)
            let store = JournalStore(context: migrated.mainContext)
            let firstDay = try XCTUnwrap(JournalDay(key: "2011-12-30"))
            let secondDay = try XCTUnwrap(JournalDay(key: "2026-03-08"))
            let first = try XCTUnwrap(store.entries(for: firstDay).first)
            let second = try XCTUnwrap(store.entries(for: secondDay).first)
            XCTAssertEqual(first.id, firstID)
            XCTAssertEqual(first.body, "Legacy writing on a civil day skipped in Samoa.")
            XCTAssertEqual(first.period, .morning)
            XCTAssertEqual(first.createdAt, created)
            XCTAssertEqual(first.modifiedAt, modified)
            XCTAssertNil(first.createdTimeZoneIdentifier)
            XCTAssertEqual(second.id, secondID)
            XCTAssertEqual(second.period, .evening)
            XCTAssertEqual(second.createdAt, created)
            XCTAssertNil(second.createdTimeZoneIdentifier)
            XCTAssertNil(try store.dailyAnalysis(for: firstDay))
            try store.setEmotionOverride(.peace, for: firstDay)
            try store.update(entry: first, body: first.body + " Updated after migration.")
            XCTAssertNil(first.createdTimeZoneIdentifier)
            XCTAssertEqual(first.createdAt, created)
        }

        let reopened = try PersistenceController.makeContainer(storeURL: url)
        let store = JournalStore(context: reopened.mainContext)
        let firstDay = try XCTUnwrap(JournalDay(key: "2011-12-30"))
        let first = try XCTUnwrap(store.entries(for: firstDay).first)
        XCTAssertEqual(first.id, firstID)
        XCTAssertNil(first.createdTimeZoneIdentifier)
        XCTAssertTrue(first.body.hasSuffix("Updated after migration."))
        XCTAssertEqual(try store.emotionOverrides(from: firstDay, through: firstDay), [firstDay.key: .peace])
    }
}
