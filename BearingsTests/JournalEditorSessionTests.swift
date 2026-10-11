import Foundation
import SwiftData
import XCTest
@testable import Bearings

final class JournalEditorSessionTests: XCTestCase {
    @MainActor
    func testUntouchedOrBlankDraftNeverCreatesAnEntry() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let session = JournalEditorSession(day: day, entry: nil, period: .morning, store: store)

        XCTAssertTrue(session.saveState == .empty)
        XCTAssertFalse(session.hasUnsavedChanges)
        XCTAssertTrue(session.save())
        XCTAssertNil(session.entry)

        // Choosing a period is a draft change, but is not writing to persist.
        session.period = .evening
        XCTAssertTrue(session.hasUnsavedChanges)
        XCTAssertTrue(session.save())
        XCTAssertTrue(session.saveState == .empty)
        XCTAssertFalse(session.hasUnsavedChanges)

        session.body = " \n\t"
        XCTAssertTrue(session.save())
        XCTAssertTrue(session.saveState == .empty)
        XCTAssertNil(session.entry)
        XCTAssertTrue(try store.entries(for: day).isEmpty)
    }

    @MainActor
    func testRepeatedSaveEditsSameUUIDAndSavesExplicitPeriodAssignment() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        var clock = Date(timeIntervalSince1970: 1_792_000_000)
        let store = JournalStore(context: container.mainContext, now: { clock })
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let session = JournalEditorSession(day: day, entry: nil, period: .morning, store: store)
        session.body = "First thoughts"
        XCTAssertTrue(session.save())
        let entry = try XCTUnwrap(session.entry)
        let id = entry.id
        let createdAt = entry.createdAt
        XCTAssertEqual(entry.period, .morning)
        XCTAssertTrue(session.saveState == .saved)

        clock = clock.addingTimeInterval(30)
        session.body = "First thoughts, revised"
        session.period = .evening
        XCTAssertTrue(session.hasUnsavedChanges)
        XCTAssertTrue(session.save())
        XCTAssertTrue(session.save())

        let entries = try store.entries(for: day)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(session.entry?.id, id)
        XCTAssertEqual(entries.first?.id, id)
        XCTAssertEqual(entries.first?.body, "First thoughts, revised")
        XCTAssertEqual(entries.first?.period, .evening)
        XCTAssertEqual(entries.first?.createdAt, createdAt)
        XCTAssertEqual(entries.first?.modifiedAt, clock)
        XCTAssertFalse(session.hasUnsavedChanges)
    }

    @MainActor
    func testClearingExistingWritingSavesAndSurvivesStoreReopen() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("BearingsEditorTests-\(UUID().uuidString)", isDirectory: true)
        // Keep this isolated store for simulator cleanup: SwiftData can retain
        // SQLite handles after its container goes out of scope.
        let url = directory.appendingPathComponent("Journal.store")
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))

        let id = try autoreleasepool {
            let container = try PersistenceController.makeContainer(storeURL: url)
            let store = JournalStore(context: container.mainContext)
            let entry = try store.create(day: day, body: "Writing to clear", period: .evening)
            let session = JournalEditorSession(day: day, entry: entry, period: entry.period, store: store)
            session.body = ""
            XCTAssertTrue(session.save())
            XCTAssertTrue(session.saveState == .saved)
            XCTAssertEqual(session.entry?.id, entry.id)
            return entry.id
        }

        let reopened = try PersistenceController.makeContainer(storeURL: url)
        let store = JournalStore(context: reopened.mainContext)
        let entries = try store.entries(for: day)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.id, id)
        XCTAssertEqual(entries.first?.body, "")
        XCTAssertEqual(entries.first?.period, .evening)
    }

    @MainActor
    func testDeleteThenLateEditorChangesAndSaveCannotResurrectEntry() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let session = JournalEditorSession(day: day, entry: nil, period: .morning, store: store)
        session.body = "Writing to delete"
        XCTAssertTrue(session.save())
        XCTAssertNotNil(session.entry)
        XCTAssertTrue(session.delete())
        XCTAssertNil(session.entry)
        XCTAssertEqual(session.body, "")
        XCTAssertTrue(session.saveState == .empty)
        XCTAssertTrue(session.save())

        // TextEditor can finish delivering a binding change during dismissal.
        // A deleted session must stay terminal even if its old draft changes.
        session.body = "A late native editor commit"
        session.period = .evening
        XCTAssertTrue(session.save())
        XCTAssertNil(session.entry)
        XCTAssertTrue(try store.entries(for: day).isEmpty)
        XCTAssertTrue(try store.daysWithEntries().isEmpty)
    }
}
