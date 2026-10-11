import Foundation
import SwiftData

enum PersistenceController {
    static var schema: Schema {
        Schema([JournalEntry.self, DailyAnalysisRecord.self, ReflectionRecord.self, EmotionOverrideRecord.self,
                TrustedContact.self])
    }
    // These legacy identities must remain stable after the Bearings rename.
    // Existing installations continue reading the same local journal store.
    @MainActor
    static func makeContainer(inMemory: Bool = false, storeURL: URL? = nil) throws -> ModelContainer {
        let schema = self.schema
        let configuration: ModelConfiguration

        if inMemory {
            configuration = ModelConfiguration(
                "ReCollect", schema: schema, isStoredInMemoryOnly: true,
                groupContainer: .none, cloudKitDatabase: .none
            )
        } else {
            let url = try storeURL ?? defaultStoreURL()
            try prepareDirectory(for: url)
            configuration = ModelConfiguration(
                "ReCollect", schema: schema, url: url, cloudKitDatabase: .none
            )
        }

        // Initialization errors intentionally reach the launch error screen.
        // A temporary store must never masquerade as the user's saved journal.
        let container = try ModelContainer(for: schema, configurations: [configuration])
        container.mainContext.autosaveEnabled = false
        if !inMemory {
            try protectStoreFiles(at: configuration.url)
        }
        return container
    }

    private static func defaultStoreURL() throws -> URL {
        let support = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true
        )
        return support.appendingPathComponent("ReCollect", isDirectory: true)
            .appendingPathComponent("Journal.store", isDirectory: false)
    }

    private static func prepareDirectory(for storeURL: URL) throws {
        let directory = storeURL.deletingLastPathComponent()
        #if os(iOS)
        let attributes: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ]
        #else
        let attributes: [FileAttributeKey: Any] = [:]
        #endif
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true, attributes: attributes
        )
        #if os(iOS)
        try FileManager.default.setAttributes(attributes, ofItemAtPath: directory.path)
        #endif
    }

    private static func protectStoreFiles(at url: URL) throws {
        #if os(iOS)
        let manager = FileManager.default
        let attributes: [FileAttributeKey: Any] = [
            .protectionKey: FileProtectionType.completeUntilFirstUserAuthentication
        ]
        for suffix in ["", "-wal", "-shm"] {
            let path = url.path + suffix
            if manager.fileExists(atPath: path) {
                try manager.setAttributes(attributes, ofItemAtPath: path)
            }
        }
        #endif
    }
}
