import Foundation
import SwiftData
import XCTest
@testable import Bearings

final class JournalStoreTests: XCTestCase {
    @MainActor
    func testFileBackedCreateEditDeleteAndReopen() throws {
        let directory = temporaryDirectory()
        let url = directory.appendingPathComponent("Journal.store")
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let creationTime = Date(timeIntervalSince1970: 1_792_000_000)
        let modificationTime = creationTime.addingTimeInterval(60)

        let savedID = try autoreleasepool {
            let container = try PersistenceController.makeContainer(storeURL: url)
            var clock = creationTime
            let store = JournalStore(context: container.mainContext, now: { clock })
            let entry = try store.create(day: day, body: "A quiet morning.")
            clock = modificationTime
            try store.update(entry: entry, body: "A quiet morning, and a long walk.")
            XCTAssertEqual(entry.createdAt, creationTime)
            XCTAssertEqual(entry.modifiedAt, modificationTime)
            XCTAssertEqual(try store.daysWithEntries(), [day.key])
            return entry.id
        }

        try autoreleasepool {
            let reopened = try PersistenceController.makeContainer(storeURL: url)
            let store = JournalStore(context: reopened.mainContext)
            let entry = try XCTUnwrap(store.entries(for: day).first)
            XCTAssertEqual(entry.id, savedID)
            XCTAssertEqual(entry.dayKey, day.key)
            XCTAssertEqual(entry.body, "A quiet morning, and a long walk.")
            XCTAssertEqual(entry.createdAt, creationTime)
            XCTAssertEqual(entry.modifiedAt, modificationTime)
            try store.delete(entry: entry)
        }

        let reopened = try PersistenceController.makeContainer(storeURL: url)
        let store = JournalStore(context: reopened.mainContext)
        XCTAssertTrue(try store.entries(for: day).isEmpty)
        XCTAssertTrue(try store.daysWithEntries().isEmpty)
    }

    @MainActor
    func testMultipleEntriesKeepTheirDayAndCreationOrder() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        var clock = Date(timeIntervalSince1970: 1_792_000_000)
        let store = JournalStore(context: container.mainContext, now: { clock })
        let selectedDay = try XCTUnwrap(JournalDay(key: "2026-03-08"))
        let anotherDay = try XCTUnwrap(JournalDay(key: "2026-03-09"))
        let first = try store.create(day: selectedDay, body: "Morning")
        clock = clock.addingTimeInterval(600)
        let second = try store.create(day: selectedDay, body: "Evening")
        _ = try store.create(day: anotherDay, body: "Tomorrow")
        try store.update(entry: first, body: "Morning edited much later")

        XCTAssertEqual(try store.entries(for: selectedDay).map(\.id), [first.id, second.id])
        XCTAssertEqual(try store.daysWithEntries(), [selectedDay.key, anotherDay.key])
        let snapshots = try store.snapshots(from: selectedDay, through: selectedDay)
        XCTAssertEqual(snapshots.map(\.id), [first.id, second.id])
        XCTAssertEqual(snapshots.map(\.dayKey), [selectedDay.key, selectedDay.key])
        XCTAssertTrue(try store.snapshots(from: anotherDay, through: selectedDay).isEmpty)
    }

    @MainActor
    func testBlankNewDraftDoesNotCreateAnEntry() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        for blank in ["", " ", "\n\t\r "] {
            XCTAssertThrowsError(try store.create(day: day, body: blank)) { error in
                guard case JournalStoreError.emptyEntry = error else {
                    return XCTFail("Unexpected validation error: \(error)")
                }
            }
        }
        XCTAssertTrue(try store.entries(for: day).isEmpty)
        XCTAssertEqual(store.revision, 0)
    }

    @MainActor
    func testAssignedPeriodsPersistIndependentOfCreationTime() throws {
        let directory = temporaryDirectory()
        let url = directory.appendingPathComponent("Journal.store")
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let creationTime = Date(timeIntervalSince1970: 1_792_000_000)
        let entryIDs = try autoreleasepool {
            let container = try PersistenceController.makeContainer(storeURL: url)
            let store = JournalStore(context: container.mainContext, now: { creationTime })
            let morning = try store.create(day: day, body: "Morning remembered later", period: .morning)
            let evening = try store.create(day: day, body: "Evening remembered at the same time", period: .evening)
            let defaultPeriod = try store.create(day: day, body: "Default assignment")
            XCTAssertEqual(defaultPeriod.period, .midday)
            return [morning.id, evening.id, defaultPeriod.id]
        }

        let reopened = try PersistenceController.makeContainer(storeURL: url)
        let store = JournalStore(context: reopened.mainContext)
        let entries = try store.entries(for: day)
        let byID = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        XCTAssertEqual(byID[entryIDs[0]]?.period, .morning)
        XCTAssertEqual(byID[entryIDs[1]]?.period, .evening)
        XCTAssertEqual(byID[entryIDs[2]]?.period, .midday)
        XCTAssertEqual(Set(entries.map(\.createdAt)), [creationTime])
        let morning = try XCTUnwrap(byID[entryIDs[0]])
        try store.update(entry: morning, body: morning.body, period: .evening)
        XCTAssertEqual(morning.periodRawValue, "evening")
    }

    @MainActor
    func testClearedExistingEntrySurvivesReopenUntilExplicitDeletion() throws {
        let directory = temporaryDirectory()
        let url = directory.appendingPathComponent("Journal.store")
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let id = try autoreleasepool {
            let container = try PersistenceController.makeContainer(storeURL: url)
            let store = JournalStore(context: container.mainContext)
            let entry = try store.create(day: day, body: "Before rewriting")
            try store.update(entry: entry, body: "")
            return entry.id
        }
        let reopened = try PersistenceController.makeContainer(storeURL: url)
        let store = JournalStore(context: reopened.mainContext)
        let entry = try XCTUnwrap(store.entries(for: day).first)
        XCTAssertEqual(entry.id, id)
        XCTAssertEqual(entry.body, "")
        XCTAssertEqual(try store.daysWithEntries(), [day.key])
    }

    @MainActor
    func testUnchangedEditDoesNotChangeTimestampAndClockCannotMoveItBackward() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        var clock = Date(timeIntervalSince1970: 1_792_000_000)
        let store = JournalStore(context: container.mainContext, now: { clock })
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let entry = try store.create(day: day, body: "Original")
        let originalTime = entry.modifiedAt
        clock = clock.addingTimeInterval(100)
        try store.update(entry: entry, body: "Original")
        XCTAssertEqual(entry.modifiedAt, originalTime)
        XCTAssertEqual(store.revision, 1)
        clock = originalTime.addingTimeInterval(-100)
        try store.update(entry: entry, body: "Changed after clock adjustment")
        XCTAssertEqual(entry.modifiedAt, originalTime)
        XCTAssertEqual(entry.createdAt, originalTime)
        XCTAssertEqual(entry.dayKey, day.key)
    }

    @MainActor
    func testInvalidStorePathThrowsInsteadOfOpeningTemporaryStore() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let blockingFile = directory.appendingPathComponent("not-a-directory")
        try Data("blocked".utf8).write(to: blockingFile)
        let storeURL = blockingFile.appendingPathComponent("Journal.store")
        XCTAssertThrowsError(try PersistenceController.makeContainer(storeURL: storeURL))
    }

    private func temporaryDirectory() -> URL {
        // SwiftData may retain SQLite handles beyond container scope. Keep each
        // isolated temp store until the simulator/process is cleaned up rather
        // than unlinking files that its background handles still have open.
        FileManager.default.temporaryDirectory
            .appendingPathComponent("BearingsTests-\(UUID().uuidString)", isDirectory: true)
    }
}
