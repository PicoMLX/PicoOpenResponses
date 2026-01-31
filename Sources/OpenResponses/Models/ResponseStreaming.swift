//
//  ResponseStreaming.swift
//  PicoResponses
//
//  Created by Ronald Mannak on 1/18/26.

import Foundation

// MARK: - Streaming Events

public struct ResponseDelta: Sendable, Equatable {
    public let raw: AnyCodable

    public init(raw: AnyCodable) {
        self.raw = raw
    }

    public var text: String? {
        if let string = raw.stringValue {
            return string
        }
        if let dictionary = raw.dictionaryValue {
            if let text = dictionary["text"]?.stringValue {
                return text
            }
            if let delta = dictionary["delta"]?.stringValue {
                return delta
            }
            if let content = dictionary["content"]?.stringValue {
                return content
            }
        }
        return nil
    }

    public var toolCalls: [ResponseToolCall]? {
        guard let dictionary = raw.dictionaryValue,
              let values = dictionary["tool_calls"]?.arrayValue else {
            return nil
        }
        return values.compactMap { $0.dictionaryValue?.decode(ResponseToolCall.self) }
    }
}

public protocol ResponseStreamProtocol: Encodable, Sendable {
    var type: String { get }
    var sequenceNumber: Int? { get }
}

public struct ResponseStreamEvent: Sendable, Equatable, ResponseStreamProtocol {
    public let type: String
    public let data: [String: AnyCodable]

    public init(type: String, data: [String: AnyCodable]) {
        self.type = type
        self.data = data
    }

    public enum Kind: String, Sendable, Equatable, CaseIterable {
        // Response lifecycle
        case responseCreated = "response.created"
        case responseInProgress = "response.in_progress"
        case responseCompleted = "response.completed"
        case responseFailed = "response.failed"
        case responseIncomplete = "response.incomplete"
        case responseQueued = "response.queued"

        // Output items
        case responseOutputItemAdded = "response.output_item.added"
        case responseOutputItemDone = "response.output_item.done"

        // Content parts
        case responseContentPartAdded = "response.content_part.added"
        case responseContentPartDone = "response.content_part.done"

        // Output text
        case responseOutputTextDelta = "response.output_text.delta"
        case responseOutputTextDone = "response.output_text.done"
        case responseOutputTextAnnotationAdded = "response.output_text.annotation.added"

        // Refusal
        case responseRefusalDelta = "response.refusal.delta"
        case responseRefusalDone = "response.refusal.done"

        // Function calls
        case responseFunctionCallArgumentsDelta = "response.function_call_arguments.delta"
        case responseFunctionCallArgumentsDone = "response.function_call_arguments.done"

        // Reasoning (Open Responses)
        case responseReasoningDelta = "response.reasoning.delta"
        case responseReasoningDone = "response.reasoning.done"

        // Reasoning text (OpenAI extension)
        case responseReasoningTextDelta = "response.reasoning_text.delta"
        case responseReasoningTextDone = "response.reasoning_text.done"

        // Reasoning summary
        case responseReasoningSummaryPartAdded = "response.reasoning_summary_part.added"
        case responseReasoningSummaryPartDone = "response.reasoning_summary_part.done"
        case responseReasoningSummaryTextDelta = "response.reasoning_summary_text.delta"
        case responseReasoningSummaryTextDone = "response.reasoning_summary_text.done"

        // File search
        case responseFileSearchCallInProgress = "response.file_search_call.in_progress"
        case responseFileSearchCallSearching = "response.file_search_call.searching"
        case responseFileSearchCallCompleted = "response.file_search_call.completed"

        // Web search
        case responseWebSearchCallInProgress = "response.web_search_call.in_progress"
        case responseWebSearchCallSearching = "response.web_search_call.searching"
        case responseWebSearchCallCompleted = "response.web_search_call.completed"

        // Code interpreter
        case responseCodeInterpreterCallInProgress = "response.code_interpreter_call.in_progress"
        case responseCodeInterpreterCallInterpreting = "response.code_interpreter_call.interpreting"
        case responseCodeInterpreterCallCompleted = "response.code_interpreter_call.completed"
        case responseCodeInterpreterCallCodeDelta = "response.code_interpreter_call_code.delta"
        case responseCodeInterpreterCallCodeDone = "response.code_interpreter_call_code.done"

        // Image generation
        case responseImageGenerationCallInProgress = "response.image_generation_call.in_progress"
        case responseImageGenerationCallGenerating = "response.image_generation_call.generating"
        case responseImageGenerationCallPartialImage = "response.image_generation_call.partial_image"
        case responseImageGenerationCallCompleted = "response.image_generation_call.completed"

        // MCP (Model Context Protocol)
        case responseMcpCallInProgress = "response.mcp_call.in_progress"
        case responseMcpCallCompleted = "response.mcp_call.completed"
        case responseMcpCallFailed = "response.mcp_call.failed"
        case responseMcpCallArgumentsDelta = "response.mcp_call_arguments.delta"
        case responseMcpCallArgumentsDone = "response.mcp_call_arguments.done"
        case responseMcpListToolsInProgress = "response.mcp_list_tools.in_progress"
        case responseMcpListToolsCompleted = "response.mcp_list_tools.completed"
        case responseMcpListToolsFailed = "response.mcp_list_tools.failed"

        // Custom tool calls
        case responseCustomToolCallInputDelta = "response.custom_tool_call_input.delta"
        case responseCustomToolCallInputDone = "response.custom_tool_call_input.done"

        // Error and terminal
        case error = "error"
        case done = "done"
    }

    public var kind: Kind {
        Kind(rawValue: type) ?? .error
    }

    public var isKnownEventType: Bool {
        Kind(rawValue: type) != nil
    }

    public var status: ResponseStatus? {
        guard let value = data["status"]?.stringValue else { return nil }
        return ResponseStatus(rawValue: value)
    }

    public var responseId: String? {
        data["response_id"]?.stringValue ?? data["id"]?.stringValue
    }

    public var delta: ResponseDelta? {
        guard let payload = data["delta"] else { return nil }
        return ResponseDelta(raw: payload)
    }

    public var outputTextDelta: ResponseDelta? {
        guard kind == .responseOutputTextDelta else { return nil }
        return delta
    }

    public var reasoningTextDelta: ResponseDelta? {
        guard kind == .responseReasoningTextDelta || kind == .responseReasoningDelta else { return nil }
        return delta
    }

    public var error: ResponseError? {
        guard let payload = data["error"]?.dictionaryValue else { return nil }
        return payload.decode(ResponseError.self)
    }

    public var streamError: ResponseError? {
        guard kind == .error else { return nil }
        return error
    }

    public var response: ResponseObject? {
        guard let payload = data["response"]?.dictionaryValue else { return nil }
        let decoder = ResponsesJSONCoding.makeDecoder()
        return payload.decode(ResponseObject.self, using: decoder)
    }

    public var completedResponse: ResponseObject? {
        guard kind == .responseCompleted else { return nil }
        return response
    }

    public var isTerminal: Bool {
        switch kind {
        case .responseCompleted, .responseFailed, .responseIncomplete, .error, .done:
            return true
        default:
            return false
        }
    }

    public var sequenceNumber: Int? {
        data["sequence_number"]?.intValue
    }

    public var itemId: String? {
        data["item_id"]?.stringValue
    }

    public var outputIndex: Int? {
        data["output_index"]?.intValue
    }

    public var contentIndex: Int? {
        data["content_index"]?.intValue
    }
}

// MARK: - Encodable

extension ResponseStreamEvent: Encodable {
    public func encode(to encoder: Encoder) throws {
        var payload: [String: AnyCodable] = ["type": AnyCodable(type)]
        for (key, value) in data {
            payload[key] = value
        }
        var container = encoder.singleValueContainer()
        try container.encode(payload)
    }
}

// MARK: - Streaming Helpers

public actor ResponseStreamSequencer: Sendable {
    private var nextValue: Int

    public init(startAt: Int = 0) {
        self.nextValue = startAt
    }

    public func next() -> Int {
        defer { nextValue += 1 }
        return nextValue
    }
}

public struct ResponseStreamEncoder: Sendable {
    public init() {}

    public func encodeString<E: ResponseStreamProtocol>(_ event: E, sequenceNumber: Int? = nil) -> String? {
        guard let jsonString = encodeJSON(event, sequenceNumber: sequenceNumber) else { return nil }
        return "event: \(event.type)\n" + "data: \(jsonString)\n\n"
    }

    public func encodeData<E: ResponseStreamProtocol>(_ event: E, sequenceNumber: Int? = nil) -> Data? {
        encodeString(event, sequenceNumber: sequenceNumber)?.data(using: .utf8)
    }

    public func doneData() -> Data {
        Data("data: [DONE]\n\n".utf8)
    }

    private func encodeJSON<E: ResponseStreamProtocol>(_ event: E, sequenceNumber: Int?) -> String? {
        let encoder = ResponsesJSONCoding.makeEncoder()
        let decoder = ResponsesJSONCoding.makeDecoder()
        guard let data = try? encoder.encode(event),
              var dict = try? decoder.decode([String: AnyCodable].self, from: data) else {
            return nil
        }
        if dict["type"] == nil {
            dict["type"] = AnyCodable(event.type)
        }
        if dict["sequence_number"] == nil, let sequenceNumber {
            dict["sequence_number"] = AnyCodable(sequenceNumber)
        }
        guard let jsonData = try? encoder.encode(dict),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        return jsonString
    }
}

public struct ResponseStreamEmitter: Sendable {
    public let stream: AsyncStream<Data>

    private let continuation: AsyncStream<Data>.Continuation
    private let sequencer: ResponseStreamSequencer
    private let encoder: ResponseStreamEncoder

    public init(startAt: Int = 0, encoder: ResponseStreamEncoder = ResponseStreamEncoder()) {
        var continuation: AsyncStream<Data>.Continuation!
        self.stream = AsyncStream { streamContinuation in
            continuation = streamContinuation
        }
        self.continuation = continuation
        self.sequencer = ResponseStreamSequencer(startAt: startAt)
        self.encoder = encoder
    }

    @discardableResult
    public func emit<E: ResponseStreamProtocol>(_ event: E) async -> Bool {
        let sequenceNumber: Int
        if let provided = event.sequenceNumber {
            sequenceNumber = provided
        } else {
            sequenceNumber = await sequencer.next()
        }
        guard let data = encoder.encodeData(event, sequenceNumber: sequenceNumber) else {
            return false
        }
        continuation.yield(data)
        return true
    }

    public func finish(sendDone: Bool = true) {
        if sendDone {
            continuation.yield(encoder.doneData())
        }
        continuation.finish()
    }
}

// MARK: - ResponseStreamEvent Factory Methods (Server-Side Construction)

public extension ResponseStreamEvent {

    init(kind: Kind, data: [String: AnyCodable] = [:]) {
        self.type = kind.rawValue
        self.data = data
    }

    // MARK: - Response Lifecycle Events

    static func created(response: ResponseObject, sequenceNumber: Int? = nil) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "response": AnyCodable(encodeResponse(response))
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseCreated, data: data)
    }

    static func inProgress(response: ResponseObject, sequenceNumber: Int? = nil) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "response": AnyCodable(encodeResponse(response))
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseInProgress, data: data)
    }

    static func completed(response: ResponseObject, sequenceNumber: Int? = nil) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "response": AnyCodable(encodeResponse(response))
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseCompleted, data: data)
    }

    static func failed(response: ResponseObject, sequenceNumber: Int? = nil) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "response": AnyCodable(encodeResponse(response))
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseFailed, data: data)
    }

    static func incomplete(response: ResponseObject, sequenceNumber: Int? = nil) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "response": AnyCodable(encodeResponse(response))
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseIncomplete, data: data)
    }

    // MARK: - Output Item Events

    static func outputItemAdded(
        item: ResponseOutput,
        outputIndex: Int,
        sequenceNumber: Int? = nil
    ) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "item": AnyCodable(encodeOutput(item)),
            "output_index": AnyCodable(outputIndex)
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseOutputItemAdded, data: data)
    }

    static func outputItemDone(
        item: ResponseOutput,
        outputIndex: Int,
        sequenceNumber: Int? = nil
    ) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "item": AnyCodable(encodeOutput(item)),
            "output_index": AnyCodable(outputIndex)
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseOutputItemDone, data: data)
    }

    // MARK: - Content Part Events

    static func contentPartAdded(
        itemId: String,
        outputIndex: Int,
        contentIndex: Int,
        part: ResponseContentBlock,
        sequenceNumber: Int? = nil
    ) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "item_id": AnyCodable(itemId),
            "output_index": AnyCodable(outputIndex),
            "content_index": AnyCodable(contentIndex),
            "part": AnyCodable(part.data.jsonObject())
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseContentPartAdded, data: data)
    }

    static func contentPartDone(
        itemId: String,
        outputIndex: Int,
        contentIndex: Int,
        part: ResponseContentBlock,
        sequenceNumber: Int? = nil
    ) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "item_id": AnyCodable(itemId),
            "output_index": AnyCodable(outputIndex),
            "content_index": AnyCodable(contentIndex),
            "part": AnyCodable(part.data.jsonObject())
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseContentPartDone, data: data)
    }

    // MARK: - Output Text Events

    static func outputTextDelta(
        itemId: String,
        outputIndex: Int,
        contentIndex: Int,
        delta: String,
        sequenceNumber: Int? = nil
    ) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "item_id": AnyCodable(itemId),
            "output_index": AnyCodable(outputIndex),
            "content_index": AnyCodable(contentIndex),
            "logprobs": AnyCodable([]),
            "obfuscation": AnyCodable(""),
            "delta": AnyCodable(delta)
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseOutputTextDelta, data: data)
    }

    static func outputTextDone(
        itemId: String,
        outputIndex: Int,
        contentIndex: Int,
        text: String,
        sequenceNumber: Int? = nil
    ) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "item_id": AnyCodable(itemId),
            "output_index": AnyCodable(outputIndex),
            "content_index": AnyCodable(contentIndex),
            "logprobs": AnyCodable([]),
            "text": AnyCodable(text)
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseOutputTextDone, data: data)
    }

    // MARK: - Reasoning Events

    static func reasoningTextDelta(
        itemId: String,
        outputIndex: Int,
        contentIndex: Int,
        delta: String,
        sequenceNumber: Int? = nil
    ) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "item_id": AnyCodable(itemId),
            "output_index": AnyCodable(outputIndex),
            "content_index": AnyCodable(contentIndex),
            "delta": AnyCodable(delta)
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseReasoningDelta, data: data)
    }

    static func reasoningTextDone(
        itemId: String,
        outputIndex: Int,
        contentIndex: Int,
        text: String,
        sequenceNumber: Int? = nil
    ) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "item_id": AnyCodable(itemId),
            "output_index": AnyCodable(outputIndex),
            "content_index": AnyCodable(contentIndex),
            "text": AnyCodable(text)
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseReasoningDone, data: data)
    }

    // MARK: - Function Call Events

    static func functionCallArgumentsDelta(
        itemId: String,
        outputIndex: Int,
        delta: String,
        sequenceNumber: Int? = nil
    ) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "item_id": AnyCodable(itemId),
            "output_index": AnyCodable(outputIndex),
            "delta": AnyCodable(delta)
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseFunctionCallArgumentsDelta, data: data)
    }

    static func functionCallArgumentsDone(
        itemId: String,
        outputIndex: Int,
        name: String,
        arguments: String,
        sequenceNumber: Int? = nil
    ) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "item_id": AnyCodable(itemId),
            "output_index": AnyCodable(outputIndex),
            "name": AnyCodable(name),
            "arguments": AnyCodable(arguments)
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        return ResponseStreamEvent(kind: .responseFunctionCallArgumentsDone, data: data)
    }

    // MARK: - Error Event

    static func error(
        code: String,
        message: String,
        param: String? = nil,
        sequenceNumber: Int? = nil
    ) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "code": AnyCodable(code),
            "message": AnyCodable(message)
        ]
        addSequenceNumber(sequenceNumber, to: &data)
        if let param {
            data["param"] = AnyCodable(param)
        }
        return ResponseStreamEvent(kind: .error, data: data)
    }

    // MARK: - Done Event

    static func done() -> ResponseStreamEvent {
        ResponseStreamEvent(kind: .done, data: [:])
    }

    // MARK: - SSE Serialization

    /// Converts the event to an SSE-formatted string: "event: ...\ndata: {json}\n\n"
    /// Returns nil if serialization fails.
    func toSSEString() -> String? {
        var eventDict: [String: AnyCodable] = ["type": AnyCodable(type)]
        for (key, value) in data {
            eventDict[key] = value
        }
        let encoder = ResponsesJSONCoding.makeEncoder()
        guard let jsonData = try? encoder.encode(eventDict),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }

        return "event: \(type)\n" + "data: \(jsonString)\n\n"
    }

    /// Converts the event to SSE data bytes
    func toSSEData() -> Data? {
        toSSEString()?.data(using: .utf8)
    }

    // MARK: - Private Helpers

    private static func encodeResponse(_ response: ResponseObject) -> [String: Any] {
        let encoder = ResponsesJSONCoding.makeEncoder()
        guard let data = try? encoder.encode(response),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }

    private static func encodeOutput(_ output: ResponseOutput) -> [String: Any] {
        let encoder = ResponsesJSONCoding.makeEncoder()
        guard let data = try? encoder.encode(output),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return dict
    }

    private static func addSequenceNumber(_ sequenceNumber: Int?, to data: inout [String: AnyCodable]) {
        if let sequenceNumber {
            data["sequence_number"] = AnyCodable(sequenceNumber)
        }
    }
}
