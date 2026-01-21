import EventSource
import Foundation
import Testing
@testable import PicoResponsesCore

private func parseEvents(_ frames: [String]) async -> [EventSource.Event] {
    let parser = EventSource.Parser()
    for frame in frames {
        for byte in frame.utf8 {
            await parser.consume(byte)
        }
    }
    await parser.finish()
    var events: [EventSource.Event] = []
    while let event = await parser.getNextEvent() {
        events.append(event)
    }
    return events
}

@Test func responseStreamParserParsesChunks() async throws {
    let frames = [
        "data: {\"type\":\"response.output_text.delta\",\"status\":\"in_progress\",\"item\":{\"id\":\"item_1\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"Hel\"}]}}\n\n",
        "data: {\"type\":\"response.output_text.delta\",\"item\":{\"id\":\"item_1\",\"role\":\"assistant\",\"content\":[{\"type\":\"output_text\",\"text\":\"lo\"}]}}\n\n",
        "data: [DONE]\n\n"
    ]

    let events = await parseEvents(frames)

    let stream = AsyncThrowingStream<EventSource.Event, Error> { continuation in
        for event in events {
            continuation.yield(event)
        }
        continuation.finish()
    }

    let decoder = ResponsesJSONCoding.makeDecoder()
    let parser = ResponseStreamParser(decoder: decoder)
    var results: [ResponseStreamEvent] = []
    for try await event in parser.parse(stream: stream) {
        results.append(event)
    }

    #expect(results.count == 3)
    guard results.count == 3 else { return }

    #expect(results[0].type == "response.output_text.delta")
    #expect(results[0].kind == .responseOutputTextDelta)
    #expect(results[0].status == .inProgress)
    let firstItem = results[0].data["item"]?.dictionaryValue
    let firstContent = firstItem? ["content"]?.arrayValue?.first?.dictionaryValue
    #expect(firstContent? ["text"]?.stringValue == "Hel")

    #expect(results[1].type == "response.output_text.delta")
    #expect(results[1].kind == .responseOutputTextDelta)
    let secondItem = results[1].data["item"]?.dictionaryValue
    let secondContent = secondItem? ["content"]?.arrayValue?.first?.dictionaryValue
    #expect(secondContent? ["text"]?.stringValue == "lo")

    #expect(results[2].type == "done")
    #expect(results[2].kind == .done)
    #expect(results[2].isTerminal)
}

@Test func responseStreamEventProvidesTypedConvenience() {
    let responsePayload: [String: AnyCodable] = [
        "response": AnyCodable([
            "id": "resp_123",
            "object": "response",
            "created_at": 0,
            "completed_at": 1,
            "model": "gpt-4o-mini",
            "status": "completed",
            "incomplete_details": NSNull(),
            "usage": NSNull(),
            "instructions": NSNull(),
            "reasoning": NSNull(),
            "max_output_tokens": NSNull(),
            "max_tool_calls": NSNull(),
            "previous_response_id": NSNull(),
            "safety_identifier": NSNull(),
            "prompt_cache_key": NSNull(),
            "tools": [],
            "tool_choice": "auto",
            "truncation": "disabled",
            "parallel_tool_calls": false,
            "text": ["format": ["type": "text"], "verbosity": "medium"],
            "output": [],
            "metadata": [:],
            "temperature": 1,
            "top_p": 1,
            "frequency_penalty": 0,
            "presence_penalty": 0,
            "top_logprobs": 0,
            "store": false,
            "background": false,
            "service_tier": "default",
            "error": NSNull()
        ])
    ]

    let completedEvent = ResponseStreamEvent(type: "response.completed", data: responsePayload)
    #expect(completedEvent.kind == .responseCompleted)
    #expect(completedEvent.isTerminal)
    #expect(completedEvent.completedResponse?.id == "resp_123")

    let errorEvent = ResponseStreamEvent(
        type: "error",
        data: ["error": AnyCodable(["code": "server_error", "message": "failed"])]
    )
    #expect(errorEvent.kind == .error)
    #expect(errorEvent.isTerminal)
    #expect(errorEvent.streamError?.message == "failed")
    #expect(errorEvent.streamError?.code == "server_error")
}
