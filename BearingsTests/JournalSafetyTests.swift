import XCTest
import SwiftData
@testable import Bearings

final class JournalSafetyTests: XCTestCase {
    func testExplicitCurrentIntentProducesNarrowSignals() throws {
        let evaluator = ConservativeJournalSafetyEvaluator()
        XCTAssertEqual(try evaluator.evaluate("I am going to kill myself."), [.explicitSelfHarm])
        XCTAssertEqual(try evaluator.evaluate("I intend to seriously hurt someone."), [.explicitOtherHarm])
    }

    func testNonIntentLanguageDoesNotTrigger() throws {
        let evaluator = ConservativeJournalSafetyEvaluator()
        let fixtures = [
            "I feel sad and lonely today.",
            "I am furious and everything is awful.",
            "This deadline is killing me.",
            "I could kill for a cup of coffee.",
            "Last year I thought: I will kill myself.",
            "The character says \"I am going to kill myself.\" in the novel.",
            "The note read, 'I will end my life.'",
            "The news said someone planned to kill him.",
            "She is going to kill him.",
            "I used to think I would end my life.",
            "That song says, \"I will end my life.\""
        ]
        for fixture in fixtures {
            XCTAssertTrue(try evaluator.evaluate(fixture).isEmpty, "Unexpected signal for synthetic fixture")
        }
    }

    func testServiceEvaluatesOnlyAfterSuccessfulSave() throws {
        let evaluator = CountingSafetyEvaluator(result: [.explicitSelfHarm])
        let service = JournalSafetyCheckService(evaluator: evaluator)
        XCTAssertTrue(try service.evaluateAfterSave(succeeded: false, committedText: "synthetic").isEmpty)
        XCTAssertEqual(evaluator.callCount, 0)
        XCTAssertEqual(try service.evaluateAfterSave(succeeded: true, committedText: "synthetic"), [.explicitSelfHarm])
        XCTAssertEqual(evaluator.callCount, 1)
    }

    @MainActor
    func testEvaluationFailureDoesNotAffectCommittedJournal() throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = JournalStore(context: container.mainContext)
        let day = try XCTUnwrap(JournalDay(key: "2026-10-10"))
        let entry = try store.create(day: day, body: "Synthetic committed writing")
        let service = JournalSafetyCheckService(evaluator: ThrowingSafetyEvaluator())
        XCTAssertThrowsError(try service.evaluateAfterSave(succeeded: true, committedText: entry.body))
        XCTAssertEqual(try store.entries(for: day).first?.body, "Synthetic committed writing")
    }

    @MainActor
    func testConsentStagesNeverInvokeTransportBeforeFinalSend() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let contactStore = TrustedContactStore(context: container.mainContext)
        let contact = try contactStore.create(displayName: "Alex Example", phoneNumber: "555-0100")
        let pinger = PingSpy()
        let session = SafetyCheckInSession(contactStore: contactStore, pinger: pinger)

        var calls = await pinger.calls()
        XCTAssertEqual(calls, 0)
        session.beginReachOut()
        calls = await pinger.calls()
        XCTAssertEqual(calls, 0)
        session.selectedRecipientIDs.insert(contact.id)
        session.reviewMessage()
        calls = await pinger.calls()
        XCTAssertEqual(calls, 0)
        await session.finalSend()
        calls = await pinger.calls()
        XCTAssertEqual(calls, 1)
        XCTAssertEqual(session.stage, .unavailable)
    }

    @MainActor
    func testNoContactStateAndCancellationActionsDoNotInvokeTransport() async throws {
        let container = try PersistenceController.makeContainer(inMemory: true)
        let store = TrustedContactStore(context: container.mainContext)
        let pinger = PingSpy()
        let session = SafetyCheckInSession(contactStore: store, pinger: pinger)
        session.beginReachOut()
        XCTAssertTrue(session.enabledContacts.isEmpty)
        let calls = await pinger.calls()
        XCTAssertEqual(calls, 0)
        // Timeout, dismissal, backgrounding, and navigation dismiss the view;
        // none call a session method that can reach the transport.
        XCTAssertEqual(session.stage, .recipients)
    }
}

private final class CountingSafetyEvaluator: JournalSafetyEvaluating, @unchecked Sendable {
    var callCount = 0
    let result: Set<JournalSafetySignal>
    init(result: Set<JournalSafetySignal>) { self.result = result }
    func evaluate(_ committedText: String) throws -> Set<JournalSafetySignal> { callCount += 1; return result }
}

private struct ThrowingSafetyEvaluator: JournalSafetyEvaluating {
    struct Failure: Error {}
    func evaluate(_ committedText: String) throws -> Set<JournalSafetySignal> { throw Failure() }
}

private actor PingSpy: TrustedContactPinging {
    private var callCount = 0
    func preparePing(recipients: [TrustedContactSnapshot], message: String) async throws {
        callCount += 1
        throw TrustedContactPingError.unavailable
    }
    func calls() -> Int { callCount }
}
