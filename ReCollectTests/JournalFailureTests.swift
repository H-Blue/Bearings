import Foundation
import SwiftData
import XCTest
@testable import ReCollect

final class JournalFailureTests: XCTestCase {
    @MainActor
    func testReadOnlyCreateFailureRetainsDraftAndNeverLeavesAGhostEntry() throws {
        let url = temporaryStoreURL()
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let writer = try PersistenceController.makeContainer(storeURL: url)
        let writerStore = JournalStore(context: writer.mainContext)
        // Materialize an empty file-backed store before opening it read-only.
        let fixture = try writerStore.create(day: day, body: "Fixture to initialize storage")
        try writerStore.delete(entry: fixture)

        let reader = try readOnlyContainer(at: url)
        let context = ModelContext(reader)
        let store = JournalStore(context: context)
        let session = JournalEditorSession(day: day, entry: nil, period: .evening, store: store)
        session.body = "A draft that must remain available after a failed save."
        let draft = session.body

        for _ in 0..<2 {
            XCTAssertFalse(session.save())
            XCTAssertTrue(session.saveState == .failed)
            XCTAssertTrue(session.hasUnsavedChanges)
            XCTAssertEqual(session.body, draft)
            XCTAssertEqual(session.period, .evening)
            XCTAssertNil(session.entry)
            XCTAssertFalse(context.hasChanges)
            XCTAssertTrue(try store.entries(for: day).isEmpty)
            XCTAssertTrue(try store.daysWithEntries().isEmpty)
        }

        XCTAssertTrue(try writerStore.entries(for: day).isEmpty)
        XCTAssertEqual(store.revision, 0)
    }

    @MainActor
    func testReadOnlyEditAndDeleteFailuresRollBackAndPreserveTheirRetryOperation() throws {
        let url = temporaryStoreURL()
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let fixtureTime = Date(timeIntervalSince1970: 1_792_000_000)
        let writer = try PersistenceController.makeContainer(storeURL: url)
        let writerStore = JournalStore(context: writer.mainContext, now: { fixtureTime })
        let fixture = try writerStore.create(day: day, body: "Persisted fixture writing", period: .morning)
        let savedID = fixture.id

        let reader = try readOnlyContainer(at: url)
        let context = ModelContext(reader)
        let store = JournalStore(context: context, now: { fixtureTime.addingTimeInterval(60) })
        let entry = try XCTUnwrap(store.entries(for: day).first)
        let session = JournalEditorSession(day: day, entry: entry, period: entry.period, store: store)
        session.body = "Edited draft retained outside the persistent model"
        session.period = .evening

        for _ in 0..<2 {
            XCTAssertFalse(session.save())
            XCTAssertTrue(session.saveState == .failed)
            XCTAssertEqual(session.body, "Edited draft retained outside the persistent model")
            XCTAssertEqual(session.period, .evening)
            XCTAssertEqual(session.entry?.id, savedID)
            XCTAssertEqual(entry.body, "Persisted fixture writing")
            XCTAssertEqual(entry.period, .morning)
            XCTAssertEqual(entry.modifiedAt, fixtureTime)
            XCTAssertFalse(context.hasChanges)
        }

        for _ in 0..<2 {
            XCTAssertFalse(session.delete())
            XCTAssertTrue(session.deleteFailed)
            XCTAssertTrue(session.saveState == .failed)
            XCTAssertEqual(session.entry?.id, savedID)
            XCTAssertEqual(session.body, "Edited draft retained outside the persistent model")
            XCTAssertFalse(context.hasChanges)
            let retained = try store.entries(for: day)
            XCTAssertEqual(retained.count, 1)
            XCTAssertEqual(retained.first?.id, savedID)
            XCTAssertEqual(retained.first?.body, "Persisted fixture writing")
        }

        // A fresh context also sees the original record; retry has not silently
        // converted the failed delete into a successful edit or a new entry.
        let freshContext = ModelContext(reader)
        let persisted = try freshContext.fetch(FetchDescriptor<JournalEntry>())
        XCTAssertEqual(persisted.count, 1)
        XCTAssertEqual(persisted.first?.id, savedID)
        XCTAssertEqual(persisted.first?.body, "Persisted fixture writing")
        XCTAssertEqual(persisted.first?.period, .morning)
        XCTAssertEqual(store.revision, 0)
    }

    @MainActor
    private func readOnlyContainer(at url: URL) throws -> ModelContainer {
        let schema = Schema([JournalEntry.self])
        let configuration = ModelConfiguration(
            "ReCollectReadOnlyFailureTests", schema: schema, url: url,
            allowsSave: false, cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [configuration])
        container.mainContext.autosaveEnabled = false
        return container
    }

    private func temporaryStoreURL() -> URL {
        // Do not unlink a store while SwiftData may retain SQLite handles.
        // The test process/simulator can clean up these isolated temp folders.
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ReCollectFailureTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("Journal.store")
    }
}
