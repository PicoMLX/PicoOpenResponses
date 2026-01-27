import Foundation
import Testing
@testable import OpenResponses

@Test func responseStreamEventKindMappingMatchesSpec() {
    let mapping: [(String, ResponseStreamEvent.Kind)] = [
        ("response.created", .responseCreated),
        ("response.in_progress", .responseInProgress),
        ("response.completed", .responseCompleted),
        ("response.failed", .responseFailed),
        ("response.incomplete", .responseIncomplete),
        ("response.queued", .responseQueued),
        ("response.output_item.added", .responseOutputItemAdded),
        ("response.output_item.done", .responseOutputItemDone),
        ("response.content_part.added", .responseContentPartAdded),
        ("response.content_part.done", .responseContentPartDone),
        ("response.output_text.delta", .responseOutputTextDelta),
        ("response.output_text.done", .responseOutputTextDone),
        ("response.output_text.annotation.added", .responseOutputTextAnnotationAdded),
        ("response.refusal.delta", .responseRefusalDelta),
        ("response.refusal.done", .responseRefusalDone),
        ("response.function_call_arguments.delta", .responseFunctionCallArgumentsDelta),
        ("response.function_call_arguments.done", .responseFunctionCallArgumentsDone),
        ("response.reasoning.delta", .responseReasoningDelta),
        ("response.reasoning.done", .responseReasoningDone),
        ("response.reasoning_summary_part.added", .responseReasoningSummaryPartAdded),
        ("response.reasoning_summary_part.done", .responseReasoningSummaryPartDone),
        ("response.reasoning_summary_text.delta", .responseReasoningSummaryTextDelta),
        ("response.reasoning_summary_text.done", .responseReasoningSummaryTextDone),
        ("error", .error)
    ]

    for (type, expected) in mapping {
        let event = ResponseStreamEvent(
            type: type,
            data: [
                "sequence_number": AnyCodable(42),
                "item_id": AnyCodable("item_1"),
                "output_index": AnyCodable(1),
                "content_index": AnyCodable(2)
            ]
        )
        #expect(event.kind == expected)
        #expect(event.isKnownEventType == true)
        #expect(event.sequenceNumber == 42)
        #expect(event.itemId == "item_1")
        #expect(event.outputIndex == 1)
        #expect(event.contentIndex == 2)
    }
}

@Test func responseStreamEventTerminalStatesMatchSpec() {
    let terminalTypes = [
        "response.completed",
        "response.failed",
        "response.incomplete",
        "error",
        "done"
    ]
    for type in terminalTypes {
        let event = ResponseStreamEvent(type: type, data: [:])
        #expect(event.isTerminal)
    }
}

@Test func responseStreamEventUnknownTypeIsNotKnown() {
    let event = ResponseStreamEvent(type: "response.unknown", data: [:])
    #expect(event.kind == .error)
    #expect(event.isKnownEventType == false)
    #expect(event.isTerminal == true)
}
