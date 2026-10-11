import XCTest
import SwiftData
@testable import Bearings

final class TrustedContactStoreTests: XCTestCase {
    @MainActor
    func testCreateEditDisableDeleteAndRelaunch() throws {
        let url = temporaryStoreURL()
        var container: ModelContainer? = try PersistenceController.makeContainer(storeURL: url)
        var store: TrustedContactStore? = TrustedContactStore(context: try XCTUnwrap(container).mainContext)
        let created = try XCTUnwrap(store).create(displayName: "  Alex Example  ", phoneNumber: " (555) 010-0200 ")
        XCTAssertEqual(created.displayName, "Alex Example")
        XCTAssertEqual(created.phoneNumber, "(555) 010-0200")
        try store?.update(created.id, displayName: "Alex Updated", phoneNumber: "+1 555 010 0200", isEnabled: false)
        XCTAssertEqual(try store?.contacts().first?.displayName, "Alex Updated")
        XCTAssertEqual(try store?.contacts().first?.isEnabled, false)

        store = nil; container = nil
        let reopened = try PersistenceController.makeContainer(storeURL: url)
        let reopenedStore = TrustedContactStore(context: reopened.mainContext)
        XCTAssertEqual(try reopenedStore.contacts().map(\.id), [created.id])
        try reopenedStore.setEnabled(true, for: created.id)
        XCTAssertTrue(try XCTUnwrap(reopenedStore.contacts().first).isEnabled)
        try reopenedStore.delete(created.id)
        XCTAssertTrue(try reopenedStore.contacts().isEmpty)
    }

    @MainActor
    func testReadOnlyFailuresRemainRetryableWithoutVisibleMutation() throws {
        let url = temporaryStoreURL()
        let writer = try PersistenceController.makeContainer(storeURL: url)
        let writerStore = TrustedContactStore(context: writer.mainContext)
        let fixture = try writerStore.create(displayName: "Jordan Example", phoneNumber: "555-0111")
        let schema = PersistenceController.schema
        let configuration = ModelConfiguration("TrustedContactReadOnly", schema: schema, url: url,
                                               allowsSave: false, cloudKitDatabase: .none)
        let reader = try ModelContainer(for: schema, configurations: [configuration])
        let store = TrustedContactStore(context: reader.mainContext)

        for _ in 0..<2 {
            XCTAssertThrowsError(try store.update(fixture.id, displayName: "Changed", phoneNumber: "555-0999", isEnabled: false))
            XCTAssertThrowsError(try store.delete(fixture.id))
            XCTAssertThrowsError(try store.create(displayName: "New", phoneNumber: "555-0122"))
            let retained = try store.contacts()
            XCTAssertEqual(retained.count, 1)
            XCTAssertEqual(retained.first?.displayName, "Jordan Example")
            XCTAssertTrue(try XCTUnwrap(retained.first).isEnabled)
            XCTAssertEqual(store.revision, 0)
        }
    }

    private func temporaryStoreURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("BearingsContactTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("Journal.store")
    }
}
