import Foundation
import Observation

@MainActor
@Observable
final class JournalEditorSession {
    enum SaveState { case empty, unsaved, saving, saved, failed }
    var day: JournalDay { didSet { if day != oldValue { saveState = .unsaved } } }
    private let store: JournalStore
    private var isDeleted = false
    private(set) var deleteFailed = false
    private(set) var entry: JournalEntry?
    var body: String { didSet { if body != oldValue { saveState = .unsaved } } }
    var period: JournalPeriod { didSet { if period != oldValue { saveState = .unsaved } } }
    private(set) var saveState: SaveState

    init(day: JournalDay, entry: JournalEntry?, period: JournalPeriod, store: JournalStore) {
        self.day = day
        self.entry = entry
        self.period = period
        self.store = store
        self.body = entry?.body ?? ""
        self.saveState = entry == nil ? .empty : .saved
    }

    var hasUnsavedChanges: Bool {
        saveState == .unsaved || saveState == .saving || saveState == .failed
    }

    var status: String {
        switch saveState {
        case .empty: "Start writing"
        case .unsaved, .saving: "Saving…"
        case .saved: "Saved"
        case .failed: "Not saved"
        }
    }

    @discardableResult
    func save() -> Bool {
        guard !isDeleted else { return true }
        guard hasUnsavedChanges else { return true }
        if entry == nil && body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            saveState = .empty
            return true
        }
        saveState = .saving
        do {
            if let entry { try store.update(entry: entry, body: body, period: period, day: day) }
            else { entry = try store.create(day: day, body: body, period: period) }
            saveState = .saved
            return true
        } catch {
            // Keep the user's draft in this editor so a failed save can be retried.
            saveState = .failed
            return false
        }
    }

    func delete() -> Bool {
        guard let entry else { return true }
        do {
            try store.delete(entry: entry)
            isDeleted = true
            self.entry = nil
            body = ""
            saveState = .empty
            deleteFailed = false
            return true
        } catch {
            deleteFailed = true
            return false
        }
    }
}
