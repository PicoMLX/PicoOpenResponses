//
//  ResponseObject.swift
//  PicoResponses
//
//  Created by Ronald Mannak on 1/18/26.

import Foundation

// MARK: - Status & Usage Metadata

public enum ResponseStatus: String, Codable, Sendable {
    case queued
    case inProgress = "in_progress"
    case completed
    case incomplete
    case failed
    case cancelled
}

public enum ResponseItemStatus: Codable, Sendable, Equatable {
    case inProgress
    case completed
    case incomplete
    case unknown(String)

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "in_progress": self = .inProgress
        case "completed": self = .completed
        case "incomplete": self = .incomplete
        default: self = .unknown(raw)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let raw: String
        switch self {
        case .inProgress: raw = "in_progress"
        case .completed: raw = "completed"
        case .incomplete: raw = "incomplete"
        case .unknown(let value): raw = value
        }
        try container.encode(raw)
    }
}

public struct ResponseStatusDetails: Codable, Sendable, Equatable {
    public let type: String?
    public let reason: String?
    public let raw: [String: AnyCodable]

    public init(type: String? = nil, reason: String? = nil, raw: [String: AnyCodable] = [:]) {
        var merged = raw
        if let type { merged["type"] = AnyCodable(type) }
        if let reason { merged["reason"] = AnyCodable(reason) }
        self.type = type
        self.reason = reason
        self.raw = merged
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode([String: AnyCodable].self)
        self.type = raw["type"]?.stringValue
        self.reason = raw["reason"]?.stringValue
        self.raw = raw
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }
}

public struct ResponseIncompleteDetails: Codable, Sendable, Equatable {
    public let reason: String?
    public let type: String?
    public let raw: [String: AnyCodable]

    public init(reason: String? = nil, type: String? = nil, raw: [String: AnyCodable] = [:]) {
        var merged = raw
        if let reason { merged["reason"] = AnyCodable(reason) }
        if let type { merged["type"] = AnyCodable(type) }
        self.reason = reason
        self.type = type
        self.raw = merged
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode([String: AnyCodable].self)
        self.reason = raw["reason"]?.stringValue
        self.type = raw["type"]?.stringValue
        self.raw = raw
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }
}

public struct ResponseRefusal: Codable, Sendable, Equatable {
    public let reason: String?
    public let message: String?
    public let raw: [String: AnyCodable]

    public init(reason: String? = nil, message: String? = nil, raw: [String: AnyCodable] = [:]) {
        var merged = raw
        if let reason { merged["reason"] = AnyCodable(reason) }
        if let message { merged["message"] = AnyCodable(message) }
        self.reason = reason
        self.message = message
        self.raw = merged
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode([String: AnyCodable].self)
        self.reason = raw["reason"]?.stringValue
        self.message = raw["message"]?.stringValue
        self.raw = raw
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }
}

public struct ResponseError: Codable, Sendable, Equatable {
    public let code: String?
    public let message: String?
    public let param: String?
    public let raw: [String: AnyCodable]

    public init(code: String? = nil, message: String? = nil, param: String? = nil, raw: [String: AnyCodable] = [:]) {
        var merged = raw
        if let code { merged["code"] = AnyCodable(code) }
        if let message { merged["message"] = AnyCodable(message) }
        if let param { merged["param"] = AnyCodable(param) }
        self.code = code
        self.message = message
        self.param = param
        self.raw = merged
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode([String: AnyCodable].self)
        self.code = raw["code"]?.stringValue
        self.message = raw["message"]?.stringValue
        self.param = raw["param"]?.stringValue
        self.raw = raw
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }
}

public struct ResponseToolInvocationError: Codable, Sendable, Equatable {
    public let code: String?
    public let message: String?
    public let type: String?
    public let raw: [String: AnyCodable]

    public init(code: String? = nil, message: String? = nil, type: String? = nil, raw: [String: AnyCodable] = [:]) {
        var merged = raw
        if let code { merged["code"] = AnyCodable(code) }
        if let message { merged["message"] = AnyCodable(message) }
        if let type { merged["type"] = AnyCodable(type) }
        self.code = code
        self.message = message
        self.type = type
        self.raw = merged
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode([String: AnyCodable].self)
        self.code = raw["code"]?.stringValue
        self.message = raw["message"]?.stringValue
        self.type = raw["type"]?.stringValue ?? raw["kind"]?.stringValue
        self.raw = raw
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }
}

public struct ResponseUsage: Codable, Sendable, Equatable {
    public let inputTokens: Int
    public let outputTokens: Int
    public let totalTokens: Int
    public let inputTokensDetails: InputTokensDetails
    public let outputTokensDetails: OutputTokenDetails

    public init(
        inputTokens: Int,
        outputTokens: Int,
        totalTokens: Int,
        inputTokensDetails: InputTokensDetails,
        outputTokensDetails: OutputTokenDetails
    ) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.totalTokens = totalTokens
        self.inputTokensDetails = inputTokensDetails
        self.outputTokensDetails = outputTokensDetails
    }
}

public struct InputTokensDetails: Codable, Sendable, Equatable {
    public let cachedTokens: Int

    public init(cachedTokens: Int) {
        self.cachedTokens = cachedTokens
    }
}

public struct OutputTokenDetails: Codable, Sendable, Equatable {
    public let reasoningTokens: Int

    public init(reasoningTokens: Int) {
        self.reasoningTokens = reasoningTokens
    }
}

// MARK: - Response-side Text Output Configuration

public struct JsonObjectResponseFormat: Codable, Sendable, Equatable {
    public let type: String

    public init() {
        self.type = "json_object"
    }
}

public struct JsonSchemaResponseFormat: Codable, Sendable, Equatable {
    public let type: String
    public let name: String
    public let description: String
    public let schema: AnyCodable
    public let strict: Bool

    public init(name: String, description: String, schema: AnyCodable, strict: Bool) {
        self.type = "json_schema"
        self.name = name
        self.description = description
        self.schema = schema
        self.strict = strict
    }
}

/// Response-side union: TextResponseFormat | JsonObjectResponseFormat | JsonSchemaResponseFormat
public enum TextFormatField: Codable, Sendable, Equatable {
    case text(TextResponseFormat)
    case jsonObject(JsonObjectResponseFormat)
    case jsonSchema(JsonSchemaResponseFormat)

    private enum CodingKeys: String, CodingKey { case type }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "text":
            self = .text(try TextResponseFormat(from: decoder))
        case "json_object":
            self = .jsonObject(try JsonObjectResponseFormat(from: decoder))
        case "json_schema":
            self = .jsonSchema(try JsonSchemaResponseFormat(from: decoder))
        default:
            // Be permissive: unknown types fall back to text.
            self = .text(TextResponseFormat())
        }
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .text(let value):
            try value.encode(to: encoder)
        case .jsonObject(let value):
            try value.encode(to: encoder)
        case .jsonSchema(let value):
            try value.encode(to: encoder)
        }
    }
}

/// Response-side text configuration.
public struct TextField: Codable, Sendable, Equatable {
    public let format: TextFormatField
    public let verbosity: VerbosityEnum?

    public init(format: TextFormatField = .text(TextResponseFormat()), verbosity: VerbosityEnum? = .medium) {
        self.format = format
        self.verbosity = verbosity
    }

    public static var `default`: TextField {
        TextField(format: .text(TextResponseFormat()), verbosity: .medium)
    }

}

// MARK: - Outputs & Responses

public enum ResponseOutputType: String, Codable, Sendable {
    case message
    case reasoning
    case functionCall = "function_call"
    case fileSearchCall = "file_search_call"
    case webSearchCall = "web_search_call"
    case codeInterpreterCall = "code_interpreter_call"
    case mcpCall = "mcp_call"
    case mcpListTools = "mcp_list_tools"
    case imageGenerationCall = "image_generation_call"
}

public struct ResponseOutput: Codable, Sendable, Equatable {
    public let id: String
    public let type: ResponseOutputType
    public let role: MessageRole?
    public let content: [ResponseContentBlock]
    public let status: ResponseItemStatus
    public let metadata: [String: AnyCodable]?
    public let refusal: ResponseRefusal?
    public let summary: [AnyCodable]?

    public init(
        id: String,
        type: ResponseOutputType = .message,
        role: MessageRole? = nil,
        content: [ResponseContentBlock] = [],
        status: ResponseItemStatus,
        metadata: [String: AnyCodable]? = nil,
        refusal: ResponseRefusal? = nil,
        summary: [AnyCodable]? = nil
    ) {
        self.id = id
        self.type = type
        self.role = role
        self.content = content
        self.status = status
        self.metadata = metadata
        self.refusal = refusal
        self.summary = summary
    }

    public init(
        id: String,
        role: MessageRole,
        content: [ResponseContentBlock],
        status: ResponseItemStatus,
        metadata: [String: AnyCodable]? = nil,
        refusal: ResponseRefusal? = nil
    ) {
        self.init(
            id: id,
            type: .message,
            role: role,
            content: content,
            status: status,
            metadata: metadata,
            refusal: refusal,
            summary: nil
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case role
        case content
        case status
        case metadata
        case refusal
        case summary
        // tool_choice is not present at the item level
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard container.contains(.id) else {
            throw DecodingError.keyNotFound(
                CodingKeys.id,
                DecodingError.Context(codingPath: container.codingPath, debugDescription: "`id` is required.")
            )
        }
        guard container.contains(.type) else {
            throw DecodingError.keyNotFound(
                CodingKeys.type,
                DecodingError.Context(codingPath: container.codingPath, debugDescription: "`type` is required.")
            )
        }

        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(ResponseOutputType.self, forKey: .type)

        switch type {
        case .reasoning:
            guard container.contains(.summary) else {
                throw DecodingError.keyNotFound(
                    CodingKeys.summary,
                    DecodingError.Context(codingPath: container.codingPath, debugDescription: "`summary` is required for reasoning items.")
                )
            }
            self.summary = try container.decode([AnyCodable].self, forKey: .summary)
            if container.contains(.content) {
                self.content = try container.decode([ResponseContentBlock].self, forKey: .content)
            } else {
                self.content = []
            }
            self.role = try container.decodeIfPresent(MessageRole.self, forKey: .role)
            self.status = try container.decodeIfPresent(ResponseItemStatus.self, forKey: .status) ?? .completed
        default:
            guard container.contains(.status) else {
                throw DecodingError.keyNotFound(
                    CodingKeys.status,
                    DecodingError.Context(codingPath: container.codingPath, debugDescription: "`status` is required for output items.")
                )
            }
            self.status = try container.decode(ResponseItemStatus.self, forKey: .status)
            if type == .message {
                guard container.contains(.content) else {
                    throw DecodingError.keyNotFound(
                        CodingKeys.content,
                        DecodingError.Context(codingPath: container.codingPath, debugDescription: "`content` is required for message items.")
                    )
                }
                guard container.contains(.role) else {
                    throw DecodingError.keyNotFound(
                        CodingKeys.role,
                        DecodingError.Context(codingPath: container.codingPath, debugDescription: "`role` is required for message items.")
                    )
                }
                self.content = try container.decode([ResponseContentBlock].self, forKey: .content)
                self.role = try container.decode(MessageRole.self, forKey: .role)
            } else if container.contains(.content) {
                self.content = try container.decode([ResponseContentBlock].self, forKey: .content)
                self.role = try container.decodeIfPresent(MessageRole.self, forKey: .role)
            } else {
                self.content = []
                self.role = try container.decodeIfPresent(MessageRole.self, forKey: .role)
            }
            self.summary = try container.decodeIfPresent([AnyCodable].self, forKey: .summary)
        }

        self.metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        self.refusal = try container.decodeIfPresent(ResponseRefusal.self, forKey: .refusal)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        if type != .reasoning {
            try container.encodeIfPresent(role, forKey: .role)
        }
        if type == .reasoning {
            // Open Responses Reference: ReasoningBody
            // - `summary` is required and must be an array (not null)
            // - `content` is optional; if present it must be an array (not null)
            // - ReasoningBody does NOT include `role`, `status`, or `tool_choice`

            // Encode required `summary` as InputTextContent[]
            let summaryItems: [[String: AnyCodable]]
            if let summary, !summary.isEmpty {
                summaryItems = summary.compactMap { part in
                    guard let dict = part.dictionaryValue,
                          let text = dict["text"]?.stringValue else { return nil }
                    return [
                        "type": AnyCodable("input_text"),
                        "text": AnyCodable(text)
                    ]
                }
            } else {
                summaryItems = []
            }
            try container.encode(summaryItems, forKey: .summary)

            // Encode optional `content` as InputTextContent[] only when non-empty
            if !content.isEmpty {
                let contentItems: [[String: AnyCodable]] = content.compactMap { block in
                    guard let text = block.text else { return nil }
                    return [
                        "type": AnyCodable("input_text"),
                        "text": AnyCodable(text)
                    ]
                }
                try container.encode(contentItems, forKey: .content)
            }
        } else {
            try container.encode(content, forKey: .content)
        }
        if type != .reasoning {
            try container.encode(status, forKey: .status)
        }
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(refusal, forKey: .refusal)
        // For reasoning items, `summary` is handled above (required). For other item types, keep it optional.
        if type != .reasoning {
            try container.encodeIfPresent(summary, forKey: .summary)
        }
        // ReasoningBody does NOT include tool_choice at the item level.
    }
}

// MARK: - ResponseOutput Convenience Initializers (Server-Side Construction)

public extension ResponseOutput {
    static func message(
        id: String = "msg_\(UUID().uuidString)",
        text: String,
        role: MessageRole = .assistant,
        status: ResponseItemStatus = .completed
    ) -> ResponseOutput {
        ResponseOutput(
            id: id,
            type: .message,
            role: role,
            content: [.outputText(text)],
            status: status
        )
    }

    static func inProgress(
        id: String = "msg_\(UUID().uuidString)",
        type: ResponseOutputType = .message,
        role: MessageRole = .assistant
    ) -> ResponseOutput {
        ResponseOutput(
            id: id,
            type: type,
            role: role,
            content: [],
            status: .inProgress
        )
    }

    static func reasoning(
        id: String = "rsn_\(UUID().uuidString)",
        summaryText: String,
        status: ResponseItemStatus = .completed
    ) -> ResponseOutput {
        // ReasoningItemParam requires `summary` and `content: null`.
        let summary: [AnyCodable] = [AnyCodable(["type": "input_text", "text": summaryText])]
        return ResponseOutput(
            id: id,
            type: .reasoning,
            role: nil,
            content: [],
            status: status,
            metadata: nil,
            refusal: nil,
            summary: summary
        )
    }

    // Backwards-compatible overload (keeps existing call sites working).
    static func reasoning(
        id: String = "rsn_\(UUID().uuidString)",
        text: String,
        status: ResponseItemStatus = .completed
    ) -> ResponseOutput {
        return ResponseOutput.reasoning(id: id, summaryText: text, status: status)
    }
}

public struct ResponseObject: Codable, Sendable, Equatable {
    public let id: String
    public let object: String
    public let createdAt: Date
    public let completedAt: Date?
    public let model: String
    public let status: ResponseStatus
    public let incompleteDetails: ResponseIncompleteDetails?
    public let usage: ResponseUsage?
    public let instructions: String?
    public let reasoning: ResponseReasoning?
    public let maxOutputTokens: Int?
    public let maxToolCalls: Int?
    public let previousResponseId: String?
    public let safetyIdentifier: String?
    public let promptCacheKey: String?
    public let tools: [ResponseTool]
    public let toolChoice: ToolChoice
    public let truncation: ResponseTruncationEnum
    public let parallelToolCalls: Bool
    public let text: TextField
    public let output: [ResponseOutput]
    public let metadata: [String: AnyCodable]
    public let temperature: Float
    public let topP: Float
    public let frequencyPenalty: Float
    public let presencePenalty: Float
    public let topLogprobs: Int
    public let store: Bool
    public let background: Bool
    public let serviceTier: String
    public let error: ResponseError?

    public init(
        id: String,
        object: String = "response",
        createdAt: Date,
        completedAt: Date? = nil,
        model: String,
        status: ResponseStatus,
        incompleteDetails: ResponseIncompleteDetails? = nil,
        usage: ResponseUsage? = nil,
        instructions: String? = nil,
        reasoning: ResponseReasoning? = nil,
        maxOutputTokens: Int? = nil,
        maxToolCalls: Int? = nil,
        previousResponseId: String? = nil,
        safetyIdentifier: String? = nil,
        promptCacheKey: String? = nil,
        tools: [ResponseTool],
        toolChoice: ToolChoice = .auto,
        truncation: ResponseTruncationEnum,
        parallelToolCalls: Bool,
        text: TextField,
        output: [ResponseOutput] = [],
        metadata: [String: AnyCodable] = [:],
        temperature: Float,
        topP: Float,
        frequencyPenalty: Float,
        presencePenalty: Float,
        topLogprobs: Int,
        store: Bool,
        background: Bool,
        serviceTier: String,
        error: ResponseError? = nil
    ) {
        self.id = id
        self.object = object
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.model = model
        self.status = status
        self.incompleteDetails = incompleteDetails
        self.usage = usage
        self.instructions = instructions
        self.reasoning = reasoning
        self.maxOutputTokens = maxOutputTokens
        self.maxToolCalls = maxToolCalls
        self.previousResponseId = previousResponseId
        self.safetyIdentifier = safetyIdentifier
        self.promptCacheKey = promptCacheKey
        self.tools = tools
        self.toolChoice = toolChoice
        self.truncation = truncation
        self.parallelToolCalls = parallelToolCalls
        self.text = text
        self.output = output
        self.metadata = metadata
        self.temperature = temperature
        self.topP = topP
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.topLogprobs = topLogprobs
        self.store = store
        self.background = background
        self.serviceTier = serviceTier
        self.error = error
    }

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case createdAt
        case completedAt
        case model
        case status
        case incompleteDetails
        case usage
        case instructions
        case reasoning
        case maxOutputTokens
        case maxToolCalls
        case previousResponseId
        case safetyIdentifier
        case promptCacheKey
        case tools
        case toolChoice
        case truncation
        case parallelToolCalls
        case text
        case output
        case metadata
        case temperature
        case topP
        case frequencyPenalty
        case presencePenalty
        case topLogprobs
        case store
        case background
        case serviceTier
        case error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let requiredKeys: [CodingKeys] = [
            .id,
            .object,
            .createdAt,
            .completedAt,
            .status,
            .incompleteDetails,
            .model,
            .previousResponseId,
            .instructions,
            .output,
            .error,
            .tools,
            .toolChoice,
            .truncation,
            .parallelToolCalls,
            .text,
            .topP,
            .presencePenalty,
            .frequencyPenalty,
            .topLogprobs,
            .temperature,
            .reasoning,
            .usage,
            .maxOutputTokens,
            .maxToolCalls,
            .store,
            .background,
            .serviceTier,
            .metadata,
            .safetyIdentifier,
            .promptCacheKey
        ]

        for key in requiredKeys where !container.contains(key) {
            throw DecodingError.keyNotFound(
                key,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "`\(key.stringValue)` is required."
                )
            )
        }

        self.id = try container.decode(String.self, forKey: .id)
        self.object = try container.decode(String.self, forKey: .object)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        self.model = try container.decode(String.self, forKey: .model)
        self.status = try container.decode(ResponseStatus.self, forKey: .status)
        self.incompleteDetails = try container.decodeIfPresent(ResponseIncompleteDetails.self, forKey: .incompleteDetails)
        self.usage = try container.decodeIfPresent(ResponseUsage.self, forKey: .usage)
        self.instructions = try container.decodeIfPresent(String.self, forKey: .instructions)
        self.reasoning = try container.decodeIfPresent(ResponseReasoning.self, forKey: .reasoning)
        self.maxOutputTokens = try container.decodeIfPresent(Int.self, forKey: .maxOutputTokens)
        self.maxToolCalls = try container.decodeIfPresent(Int.self, forKey: .maxToolCalls)
        self.previousResponseId = try container.decodeIfPresent(String.self, forKey: .previousResponseId)
        self.safetyIdentifier = try container.decodeIfPresent(String.self, forKey: .safetyIdentifier)
        self.promptCacheKey = try container.decodeIfPresent(String.self, forKey: .promptCacheKey)
        self.tools = try container.decode([ResponseTool].self, forKey: .tools)
        self.toolChoice = try container.decode(ToolChoice.self, forKey: .toolChoice)
        self.truncation = try container.decode(ResponseTruncationEnum.self, forKey: .truncation)
        self.parallelToolCalls = try container.decode(Bool.self, forKey: .parallelToolCalls)
        self.text = try container.decode(TextField.self, forKey: .text)
        self.output = try container.decode([ResponseOutput].self, forKey: .output)
        self.metadata = try container.decode([String: AnyCodable].self, forKey: .metadata)
        self.temperature = try container.decode(Float.self, forKey: .temperature)
        self.topP = try container.decode(Float.self, forKey: .topP)
        self.frequencyPenalty = try container.decode(Float.self, forKey: .frequencyPenalty)
        self.presencePenalty = try container.decode(Float.self, forKey: .presencePenalty)
        self.topLogprobs = try container.decode(Int.self, forKey: .topLogprobs)
        self.store = try container.decode(Bool.self, forKey: .store)
        self.background = try container.decode(Bool.self, forKey: .background)
        self.serviceTier = try container.decode(String.self, forKey: .serviceTier)
        self.error = try container.decodeIfPresent(ResponseError.self, forKey: .error)
    }
}

public extension ResponseObject {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(object, forKey: .object)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeOrNull(completedAt, forKey: .completedAt)
        try container.encode(model, forKey: .model)
        try container.encode(status, forKey: .status)
        try container.encodeOrNull(incompleteDetails, forKey: .incompleteDetails)
        try container.encodeOrNull(usage, forKey: .usage)
        try container.encodeOrNull(instructions, forKey: .instructions)
        try container.encodeOrNull(reasoning, forKey: .reasoning)
        try container.encodeOrNull(maxOutputTokens, forKey: .maxOutputTokens)
        try container.encodeOrNull(maxToolCalls, forKey: .maxToolCalls)
        try container.encodeOrNull(previousResponseId, forKey: .previousResponseId)
        try container.encodeOrNull(safetyIdentifier, forKey: .safetyIdentifier)
        try container.encodeOrNull(promptCacheKey, forKey: .promptCacheKey)
        try encodeRequired(tools, forKey: .tools, in: &container)
        try encodeRequired(toolChoice, forKey: .toolChoice, in: &container)
        try encodeRequired(truncation, forKey: .truncation, in: &container)
        try encodeRequired(parallelToolCalls, forKey: .parallelToolCalls, in: &container)
        try encodeRequired(text, forKey: .text, in: &container)
        try container.encode(output, forKey: .output)
        try container.encode(metadata, forKey: .metadata)
        try encodeRequired(temperature, forKey: .temperature, in: &container)
        try encodeRequired(topP, forKey: .topP, in: &container)
        try encodeRequired(frequencyPenalty, forKey: .frequencyPenalty, in: &container)
        try encodeRequired(presencePenalty, forKey: .presencePenalty, in: &container)
        try encodeRequired(topLogprobs, forKey: .topLogprobs, in: &container)
        try encodeRequired(store, forKey: .store, in: &container)
        try encodeRequired(background, forKey: .background, in: &container)
        try encodeRequired(serviceTier, forKey: .serviceTier, in: &container)
        try container.encodeOrNull(error, forKey: .error)
    }
}

private extension ResponseObject {
    func encodeRequired<T: Encodable>(
        _ value: T?,
        forKey key: CodingKeys,
        in container: inout KeyedEncodingContainer<CodingKeys>
    ) throws {
        if let value {
            try container.encode(value, forKey: key)
        } else {
            try container.encodeNil(forKey: key)
        }
    }
}

// MARK: - Fix call sites to pass status: .completed if missing or nil

public extension ResponseObject {
    static func completed(
        id: String = "resp_\(UUID().uuidString)",
        model: String,
        tools: [ResponseTool],
        truncation: ResponseTruncationEnum,
        parallelToolCalls: Bool,
        text: TextField = .default,
        output: [ResponseOutput],
        temperature: Float,
        topP: Float,
        frequencyPenalty: Float,
        presencePenalty: Float,
        topLogprobs: Int,
        store: Bool,
        background: Bool,
        serviceTier: String,
        metadata: [String: AnyCodable] = [:],
        usage: ResponseUsage? = nil,
        createdAt: Date = Date()
    ) -> ResponseObject {
        ResponseObject(
            id: id,
            object: "response",
            createdAt: createdAt,
            completedAt: Date(),
            model: model,
            status: .completed,
            usage: usage,
            tools: tools,
            truncation: truncation,
            parallelToolCalls: parallelToolCalls,
            text: text,
            output: output,
            metadata: metadata,
            temperature: temperature,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty,
            topLogprobs: topLogprobs,
            store: store,
            background: background,
            serviceTier: serviceTier
        )
    }

    static func inProgress(
        id: String = "resp_\(UUID().uuidString)",
        model: String,
        tools: [ResponseTool],
        truncation: ResponseTruncationEnum,
        parallelToolCalls: Bool,
        text: TextField = .default,
        output: [ResponseOutput] = [],
        metadata: [String: AnyCodable] = [:],
        temperature: Float,
        topP: Float,
        frequencyPenalty: Float,
        presencePenalty: Float,
        topLogprobs: Int,
        store: Bool,
        background: Bool,
        serviceTier: String,
        createdAt: Date = Date()
    ) -> ResponseObject {
        ResponseObject(
            id: id,
            object: "response",
            createdAt: createdAt,
            model: model,
            status: .inProgress,
            tools: tools,
            truncation: truncation,
            parallelToolCalls: parallelToolCalls,
            text: text,
            output: output,
            metadata: metadata,
            temperature: temperature,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty,
            topLogprobs: topLogprobs,
            store: store,
            background: background,
            serviceTier: serviceTier
        )
    }

    static func failed(
        id: String = "resp_\(UUID().uuidString)",
        model: String,
        tools: [ResponseTool],
        truncation: ResponseTruncationEnum,
        parallelToolCalls: Bool,
        text: TextField = .default,
        error: ResponseError,
        temperature: Float,
        topP: Float,
        frequencyPenalty: Float,
        presencePenalty: Float,
        topLogprobs: Int,
        store: Bool,
        background: Bool,
        serviceTier: String,
        createdAt: Date = Date()
    ) -> ResponseObject {
        ResponseObject(
            id: id,
            object: "response",
            createdAt: createdAt,
            model: model,
            status: .failed,
            tools: tools,
            truncation: truncation,
            parallelToolCalls: parallelToolCalls,
            text: text,
            output: [],
            temperature: temperature,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty,
            topLogprobs: topLogprobs,
            store: store,
            background: background,
            serviceTier: serviceTier,
            error: error
        )
    }

    static func incomplete(
        id: String = "resp_\(UUID().uuidString)",
        model: String,
        tools: [ResponseTool],
        truncation: ResponseTruncationEnum,
        parallelToolCalls: Bool,
        text: TextField = .default,
        output: [ResponseOutput],
        reason: String,
        temperature: Float,
        topP: Float,
        frequencyPenalty: Float,
        presencePenalty: Float,
        topLogprobs: Int,
        store: Bool,
        background: Bool,
        serviceTier: String,
        usage: ResponseUsage? = nil,
        createdAt: Date = Date()
    ) -> ResponseObject {
        ResponseObject(
            id: id,
            object: "response",
            createdAt: createdAt,
            model: model,
            status: .incomplete,
            incompleteDetails: ResponseIncompleteDetails(reason: reason),
            usage: usage,
            tools: tools,
            truncation: truncation,
            parallelToolCalls: parallelToolCalls,
            text: text,
            output: output,
            temperature: temperature,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty,
            topLogprobs: topLogprobs,
            store: store,
            background: background,
            serviceTier: serviceTier
        )
    }
}

public struct ResponseList: Codable, Sendable, Equatable {
    public let object: String
    public let data: [ResponseObject]
    public let hasMore: Bool
    public let firstId: String?
    public let lastId: String?
    public let nextPageToken: String?

    public init(
        object: String = "list",
        data: [ResponseObject],
        hasMore: Bool,
        firstId: String? = nil,
        lastId: String? = nil,
        nextPageToken: String? = nil
    ) {
        self.object = object
        self.data = data
        self.hasMore = hasMore
        self.firstId = firstId
        self.lastId = lastId
        self.nextPageToken = nextPageToken
    }
}
