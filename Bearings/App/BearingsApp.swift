import SwiftUI
import SwiftData

@main
struct BearingsApp: App {
    var body: some Scene {
        WindowGroup {
            StoreBootstrapView()
                .preferredColorScheme(.light)
        }
    }
}

private struct StoreBootstrapView: View {
    @State private var container: ModelContainer?
    @State private var failed = false
    @State private var journalViewID = UUID()

    var body: some View {
        Group {
            if let container {
                BearingsRootView(container: container, onRetryRead: { journalViewID = UUID() })
                    .modelContainer(container)
                    .id(journalViewID)
            } else if failed {
                ContentUnavailableView {
                    Label("Your journal couldn’t open", systemImage: "book.closed")
                } description: {
                    Text("Bearings could not open its local storage. Your existing journal has not been replaced. Try again when your device is unlocked and has available storage.")
                } actions: {
                    Button("Try again", action: openStore)
                }
            } else {
                ProgressView("Opening your journal…")
            }
        }
        .tint(BearingsTheme.ink)
        .task { if container == nil { openStore() } }
    }

    private func openStore() {
        do {
            var storeURL: URL?
            #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("--uitesting") {
                let directory = URL.applicationSupportDirectory.appending(path: "BearingsUITests", directoryHint: .isDirectory)
                if arguments.contains("--reset-test-store"), FileManager.default.fileExists(atPath: directory.path) {
                    try FileManager.default.removeItem(at: directory)
                }
                storeURL = directory.appending(path: "ui-tests.store")
            }
            #endif
            container = try PersistenceController.makeContainer(storeURL: storeURL)
            failed = false
        } catch {
            // Never log error descriptions: persistence errors may contain private values.
            failed = true
        }
    }
}
