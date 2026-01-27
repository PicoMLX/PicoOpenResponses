import XCTest
@testable import PicoResponsesSwiftUI
import OpenResponses

final class ConversationStreamReducerTests: XCTestCase {
    func testDeltaAppendsAssistantMessage() {
        var snapshot = ConversationStateSnapshot(
            messages: [ConversationMessage(role: .user, text: "Hello")],
            responsePhase: .awaitingResponse
        )

        let event = ResponseStreamEvent(
            type: "response.output_text.delta",
            data: Self.makeEventData([
                "delta": [
                    "text": " world"
                ]
            ])
        )

        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: event)

        XCTAssertEqual(snapshot.messages.last?.role, .assistant)
        XCTAssertEqual(snapshot.messages.last?.text, " world")
        XCTAssertTrue(snapshot.responsePhase.isStreaming)
    }

    func testCompletedResponseReplacesAssistantMessage() throws {
        var snapshot = ConversationStateSnapshot(
            messages: [
                ConversationMessage(role: .user, text: "Hi"),
                ConversationMessage(role: .assistant, text: "partial")
            ],
            responsePhase: .streaming
        )

        let response = ResponseObject(
            id: "resp_1",
            createdAt: Date(timeIntervalSince1970: 0),
            model: "gpt-4.1",
            status: .completed,
            tools: [],
            truncation: .disabled,
            parallelToolCalls: false,
            text: .default,
            output: [
                ResponseOutput(
                    id: "out_1",
                    role: .assistant,
                    content: [.outputText("final answer")],
                    status: .completed
                )
            ],
            temperature: 1,
            topP: 1,
            frequencyPenalty: 0,
            presencePenalty: 0,
            topLogprobs: 0,
            store: false,
            background: false,
            serviceTier: "default"
        )

        let responseDictionary = try Self.makeAnyCodableDictionary(response)
        let event = ResponseStreamEvent(
            type: "response.completed",
            data: [
                "response": AnyCodable(responseDictionary)
            ]
        )

        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: event)

        XCTAssertEqual(snapshot.messages.last?.text, "final answer")
        if case .completed = snapshot.responsePhase {
            // success
        } else {
            XCTFail("Expected completed phase")
        }
    }

    func testWebSearchEventsUpdatePhase() {
        var snapshot = ConversationStateSnapshot()

        let inProgress = ResponseStreamEvent(type: "response.web_search_call.in_progress", data: [:])
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: inProgress)
        if case .initiated = snapshot.webSearchPhase {
            // ok
        } else {
            XCTFail("Expected initiated phase")
        }

        let completed = ResponseStreamEvent(type: "response.web_search_call.completed", data: [:])
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: completed)
        if case .completed = snapshot.webSearchPhase {
            // ok
        } else {
            XCTFail("Expected completed phase")
        }
    }

    func testReasoningEventsUpdatePhase() {
        var snapshot = ConversationStateSnapshot()

        // Use response.reasoning_summary_part.added which triggers containsCreationIndicator (.added)
        let added = ResponseStreamEvent(type: "response.reasoning_summary_part.added", data: [:])
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: added)
        if case .drafting = snapshot.reasoningPhase {
            // ok
        } else {
            XCTFail("Expected drafting phase")
        }

        let delta = ResponseStreamEvent(type: "response.reasoning_summary_text.delta", data: [:])
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: delta)
        if case .reasoning = snapshot.reasoningPhase {
            // ok
        } else {
            XCTFail("Expected reasoning phase")
        }

        // Use response.reasoning_summary_text.done which triggers containsCompletionIndicator (.done)
        let done = ResponseStreamEvent(type: "response.reasoning_summary_text.done", data: ["text": AnyCodable("All good")])
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: done)
        if case .completed(let summary) = snapshot.reasoningPhase {
            XCTAssertEqual(summary, "All good")
        } else {
            XCTFail("Expected completed phase")
        }
    }

    func testToolCallEventsUpdatePhase() {
        var snapshot = ConversationStateSnapshot()

        // Use function_call_arguments.delta which contains .delta (triggers containsCreationIndicator or delta check)
        let delta = ResponseStreamEvent(type: "response.function_call_arguments.delta", data: ["name": AnyCodable("calendar"), "type": AnyCodable("function")])
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: delta)
        if case .running(let name, let type) = snapshot.toolCallPhase {
            XCTAssertEqual(name, "calendar")
            XCTAssertEqual(type, "function")
        } else {
            XCTFail("Expected running phase")
        }

        // Use function_call_arguments.done which contains .done (triggers containsCompletionIndicator)
        let done = ResponseStreamEvent(type: "response.function_call_arguments.done", data: ["name": AnyCodable("calendar"), "type": AnyCodable("function")])
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: done)
        if case .completed(let name, _) = snapshot.toolCallPhase {
            XCTAssertEqual(name, "calendar")
        } else {
            XCTFail("Expected completed phase")
        }
    }

    func testReasoningOutputItemEventsUpdatePhase() {
        var snapshot = ConversationStateSnapshot()
        let reasoningAddItem: [String: Any] = [
            "id": "rs_1",
            "type": "reasoning",
            "summary": ["Step 1"]
        ]
        let added = ResponseStreamEvent(
            type: "response.output_item.added",
            data: ["item": AnyCodable(reasoningAddItem)]
        )
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: added)
        if case .drafting = snapshot.reasoningPhase {
            // ok
        } else {
            XCTFail("Expected drafting phase from output item add")
        }

        let reasoningDoneItem: [String: Any] = [
            "id": "rs_1",
            "type": "reasoning",
            "summary": [["text": "Reasoned answer"]]
        ]
        let done = ResponseStreamEvent(
            type: "response.output_item.done",
            data: ["item": AnyCodable(reasoningDoneItem)]
        )
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: done)
        if case .completed(let summary) = snapshot.reasoningPhase {
            XCTAssertEqual(summary, "Reasoned answer")
        } else {
            XCTFail("Expected completed reasoning phase")
        }
    }

    func testToolCallOutputItemEventsUpdatePhase() {
        var snapshot = ConversationStateSnapshot()
        let toolAddItem: [String: Any] = [
            "id": "tc_1",
            "type": "function_call",
            "name": "browser",
            "tool_name": "web-search"
        ]
        let added = ResponseStreamEvent(
            type: "response.output_item.added",
            data: ["item": AnyCodable(toolAddItem)]
        )
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: added)
        if case .running(let name, _) = snapshot.toolCallPhase {
            XCTAssertEqual(name, "browser")
        } else {
            XCTFail("Expected running tool phase from output item add")
        }

        let toolDoneItem: [String: Any] = [
            "id": "tc_1",
            "type": "function_call",
            "name": "browser",
            "tool_name": "web-search"
        ]
        let done = ResponseStreamEvent(
            type: "response.output_item.done",
            data: ["item": AnyCodable(toolDoneItem)]
        )
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: done)
        if case .completed(let name, _) = snapshot.toolCallPhase {
            XCTAssertEqual(name, "browser")
        } else {
            XCTFail("Expected completed tool phase")
        }
    }

    func testFileSearchEventsUpdatePhase() {
        var snapshot = ConversationStateSnapshot()

        let inProgress = ResponseStreamEvent(type: "response.file_search_call.in_progress", data: [:])
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: inProgress)
        if case .preparing = snapshot.fileSearchPhase {
            // ok
        } else {
            XCTFail("Expected preparing phase")
        }

        let searching = ResponseStreamEvent(type: "response.file_search_call.searching", data: [:])
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: searching)
        if case .searching = snapshot.fileSearchPhase {
            // ok
        } else {
            XCTFail("Expected searching phase")
        }

        let completed = ResponseStreamEvent(type: "response.file_search_call.completed", data: [:])
        snapshot = ConversationStreamReducer.reduce(snapshot: snapshot, with: completed)
        if case .completed = snapshot.fileSearchPhase {
            // ok
        } else {
            XCTFail("Expected completed phase")
        }
    }

    private static func makeAnyCodableDictionary<T: Encodable>(_ value: T) throws -> [String: Any] {
        let encoder = ResponsesJSONCoding.makeEncoder()
        let data = try encoder.encode(value)
        let json = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = json as? [String: Any] else {
            return [:]
        }
        return dictionary
    }

    private static func makeEventData(_ value: [String: Any]) -> [String: AnyCodable] {
        value.mapValues(AnyCodable.init)
    }
}
