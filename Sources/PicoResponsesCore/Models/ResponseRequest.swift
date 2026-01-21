//
//  ResponseRequest.swift
//  PicoResponses
//
//  Created by Ronald Mannak on 1/18/26.

import Foundation

public struct JsonSchemaResponseFormatParam: Codable, Sendable, Equatable {
    public let type: String
    public let description: String?
    public let name: String?
    public let schema: AnyCodable?
    public let strict: Bool?

    public init(description: String? = nil, name: String? = nil, schema: AnyCodable? = nil, strict: Bool? = nil) {
        self.type = "json_schema"
        self.description = description
        self.name = name
        self.schema = schema
        self.strict = strict
    }
}

/// Request-side union: JsonSchemaResponseFormatParam | TextResponseFormat
public enum TextFormatParam: Codable, Sendable, Equatable {
    case text(TextResponseFormat)
    case jsonSchema(JsonSchemaResponseFormatParam)

    private enum CodingKeys: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            self = .text(try TextResponseFormat(from: decoder))
        case "json_schema":
            self = .jsonSchema(try JsonSchemaResponseFormatParam(from: decoder))
        default:
            // Be permissive: unknown types fall back to text.
            self = .text(TextResponseFormat())
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let value):
            try value.encode(to: encoder)
        case .jsonSchema(let value):
            try value.encode(to: encoder)
        }
    }
}

/// Request-side text configuration.
public struct TextParam: Codable, Sendable, Equatable {
    public let format: TextFormatParam?
    public let verbosity: VerbosityEnum?

    public init(format: TextFormatParam? = nil, verbosity: VerbosityEnum? = nil) {
        self.format = format
        self.verbosity = verbosity
    }

    // Intentionally no legacy helpers here; request payloads are spec-first.
}

public struct ResponseMessageInput: Codable, Sendable, Equatable {
    public let role: MessageRole
    public let content: [ResponseContentBlock]
    public let metadata: [String: AnyCodable]?

    public init(role: MessageRole, content: [ResponseContentBlock], metadata: [String: AnyCodable]? = nil) {
        self.role = role
        self.content = content
        self.metadata = metadata
    }
}

public enum ResponseInputItem: Codable, Sendable, Equatable {
    case message(ResponseMessageInput)
    case raw([String: AnyCodable])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dictionary = try container.decode([String: AnyCodable].self)
        if let roleValue = dictionary["role"]?.stringValue,
           let role = MessageRole(rawValue: roleValue),
           let contentValues = dictionary["content"]?.arrayValue {
            let blocks: [ResponseContentBlock] = contentValues.compactMap { value in
                guard let payload = value.dictionaryValue else { return nil }
                let typeString = payload["type"]?.stringValue ?? "text"
                let contentType = ResponseContentType(rawValue: typeString) ?? .text
                return ResponseContentBlock(type: contentType, data: payload)
            }
            let metadata = dictionary["metadata"]?.dictionaryValue
            self = .message(ResponseMessageInput(role: role, content: blocks, metadata: metadata))
        } else {
            self = .raw(dictionary)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .message(let message):
            let contentPayload: [Any] = message.content.map { $0.data.jsonObject() }
            var payload: [String: AnyCodable] = [
                "role": AnyCodable(message.role.rawValue),
                "content": AnyCodable(contentPayload)
            ]
            if let metadata = message.metadata {
                payload["metadata"] = AnyCodable(metadata.jsonObject())
            }
            try container.encode(payload)
        case .raw(let dictionary):
            try container.encode(dictionary)
        }
    }
}

public enum ResponseInput: Codable, Sendable, Equatable {
    case text(String)
    case items([ResponseInputItem])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
            return
        }
        if let items = try? container.decode([ResponseInputItem].self) {
            self = .items(items)
            return
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Expected input to be a string or an array of items."
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let value):
            try container.encode(value)
        case .items(let items):
            try container.encode(items)
        }
    }
}

public extension ResponseInputItem {
    static func message(role: MessageRole, content: [ResponseContentBlock], metadata: [String: AnyCodable]? = nil) -> ResponseInputItem {
        .message(ResponseMessageInput(role: role, content: content, metadata: metadata))
    }
}

// MARK: - Request Payload

public struct ResponseCreateRequest: Codable, Sendable, Equatable {
    public let model: String?
    public let input: ResponseInput
    public let include: [ResponseInclude]?
    public let instructions: String?
    public let text: TextParam?
    public let metadata: [String: AnyCodable]?
    public let temperature: Float?
    public let topP: Float?
    public let stream: Bool?
    public let streamOptions: ResponseStreamOptions?
    public let frequencyPenalty: Float?
    public let presencePenalty: Float?
    public let topLogprobs: Int?
    public let store: Bool?
    public let background: Bool?
    public let serviceTier: String?
    public let maxOutputTokens: Int?
    public let maxToolCalls: Int?
    public let reasoning: ResponseReasoningParam?
    public let truncation: ResponseTruncationEnum?
    public let safetyIdentifier: String?
    public let promptCacheKey: String?
    public let parallelToolCalls: Bool?
    public let tools: [ResponseTool]?
    public let toolChoice: ToolChoiceParam?
    public let previousResponseId: String?

    public init(
        model: String? = nil,
        input: ResponseInput,
        include: [ResponseInclude]? = nil,
        instructions: String? = nil,
        text: TextParam? = nil,
        metadata: [String: AnyCodable]? = nil,
        temperature: Float? = nil,
        topP: Float? = nil,
        stream: Bool? = nil,
        streamOptions: ResponseStreamOptions? = nil,
        frequencyPenalty: Float? = nil,
        presencePenalty: Float? = nil,
        topLogprobs: Int? = nil,
        store: Bool? = nil,
        background: Bool? = nil,
        serviceTier: String? = nil,
        maxOutputTokens: Int? = nil,
        maxToolCalls: Int? = nil,
        reasoning: ResponseReasoningParam? = nil,
        truncation: ResponseTruncationEnum? = nil,
        safetyIdentifier: String? = nil,
        promptCacheKey: String? = nil,
        parallelToolCalls: Bool? = nil,
        tools: [ResponseTool]? = nil,
        toolChoice: ToolChoiceParam? = nil,
        previousResponseId: String? = nil
    ) {
        self.model = model
        self.input = input
        self.include = include
        self.instructions = instructions
        self.text = text
        self.metadata = metadata
        self.temperature = temperature
        self.topP = topP
        self.stream = stream
        self.streamOptions = streamOptions
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.topLogprobs = topLogprobs
        self.store = store
        self.background = background
        self.serviceTier = serviceTier
        self.maxOutputTokens = maxOutputTokens
        self.maxToolCalls = maxToolCalls
        self.reasoning = reasoning
        self.truncation = truncation
        self.safetyIdentifier = safetyIdentifier
        self.promptCacheKey = promptCacheKey
        self.parallelToolCalls = parallelToolCalls
        self.tools = tools
        self.toolChoice = toolChoice
        self.previousResponseId = previousResponseId
    }

    public init(
        model: String? = nil,
        input: [ResponseInputItem],
        include: [ResponseInclude]? = nil,
        instructions: String? = nil,
        text: TextParam? = nil,
        metadata: [String: AnyCodable]? = nil,
        temperature: Float? = nil,
        topP: Float? = nil,
        stream: Bool? = nil,
        streamOptions: ResponseStreamOptions? = nil,
        frequencyPenalty: Float? = nil,
        presencePenalty: Float? = nil,
        topLogprobs: Int? = nil,
        store: Bool? = nil,
        background: Bool? = nil,
        serviceTier: String? = nil,
        maxOutputTokens: Int? = nil,
        maxToolCalls: Int? = nil,
        reasoning: ResponseReasoningParam? = nil,
        truncation: ResponseTruncationEnum? = nil,
        safetyIdentifier: String? = nil,
        promptCacheKey: String? = nil,
        parallelToolCalls: Bool? = nil,
        tools: [ResponseTool]? = nil,
        toolChoice: ToolChoiceParam? = nil,
        previousResponseId: String? = nil
    ) {
        self.init(
            model: model,
            input: .items(input),
            include: include,
            instructions: instructions,
            text: text,
            metadata: metadata,
            temperature: temperature,
            topP: topP,
            stream: stream,
            streamOptions: streamOptions,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty,
            topLogprobs: topLogprobs,
            store: store,
            background: background,
            serviceTier: serviceTier,
            maxOutputTokens: maxOutputTokens,
            maxToolCalls: maxToolCalls,
            reasoning: reasoning,
            truncation: truncation,
            safetyIdentifier: safetyIdentifier,
            promptCacheKey: promptCacheKey,
            parallelToolCalls: parallelToolCalls,
            tools: tools,
            toolChoice: toolChoice,
            previousResponseId: previousResponseId
        )
    }

    public init(
        model: String? = nil,
        input: String,
        include: [ResponseInclude]? = nil,
        instructions: String? = nil,
        text: TextParam? = nil,
        metadata: [String: AnyCodable]? = nil,
        temperature: Float? = nil,
        topP: Float? = nil,
        stream: Bool? = nil,
        streamOptions: ResponseStreamOptions? = nil,
        frequencyPenalty: Float? = nil,
        presencePenalty: Float? = nil,
        topLogprobs: Int? = nil,
        store: Bool? = nil,
        background: Bool? = nil,
        serviceTier: String? = nil,
        maxOutputTokens: Int? = nil,
        maxToolCalls: Int? = nil,
        reasoning: ResponseReasoningParam? = nil,
        truncation: ResponseTruncationEnum? = nil,
        safetyIdentifier: String? = nil,
        promptCacheKey: String? = nil,
        parallelToolCalls: Bool? = nil,
        tools: [ResponseTool]? = nil,
        toolChoice: ToolChoiceParam? = nil,
        previousResponseId: String? = nil
    ) {
        self.init(
            model: model,
            input: .text(input),
            include: include,
            instructions: instructions,
            text: text,
            metadata: metadata,
            temperature: temperature,
            topP: topP,
            stream: stream,
            streamOptions: streamOptions,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty,
            topLogprobs: topLogprobs,
            store: store,
            background: background,
            serviceTier: serviceTier,
            maxOutputTokens: maxOutputTokens,
            maxToolCalls: maxToolCalls,
            reasoning: reasoning,
            truncation: truncation,
            safetyIdentifier: safetyIdentifier,
            promptCacheKey: promptCacheKey,
            parallelToolCalls: parallelToolCalls,
            tools: tools,
            toolChoice: toolChoice,
            previousResponseId: previousResponseId
        )
    }
}

// MARK: - ResponseCreateRequest Validation

public extension ResponseCreateRequest {
    func validate() throws {
        switch input {
        case .text(let value):
            if value.isEmpty {
                throw PicoResponsesError.validationError("input cannot be empty")
            }
        case .items(let items):
            if items.isEmpty {
                throw PicoResponsesError.validationError("input cannot be empty")
            }
        }

        if let text, text.format == nil {
            throw PicoResponsesError.validationError("text must include format, e.g. { \"format\": { \"type\": \"text\" } }")
        }

        if let temperature, (temperature < 0 || temperature > 2) {
            throw PicoResponsesError.validationError("temperature must be between 0 and 2")
        }

        if let topP, (topP < 0 || topP > 1) {
            throw PicoResponsesError.validationError("topP must be between 0 and 1")
        }

        if let frequencyPenalty, (frequencyPenalty < -2 || frequencyPenalty > 2) {
            throw PicoResponsesError.validationError("frequencyPenalty must be between -2 and 2")
        }

        if let presencePenalty, (presencePenalty < -2 || presencePenalty > 2) {
            throw PicoResponsesError.validationError("presencePenalty must be between -2 and 2")
        }

        if let maxOutputTokens, maxOutputTokens < 16 {
            throw PicoResponsesError.validationError("maxOutputTokens must be at least 16")
        }

        if let maxToolCalls, maxToolCalls < 1 {
            throw PicoResponsesError.validationError("maxToolCalls must be at least 1")
        }

        if let topLogprobs, (topLogprobs < 0 || topLogprobs > 20) {
            throw PicoResponsesError.validationError("topLogprobs must be between 0 and 20")
        }
    }
}
