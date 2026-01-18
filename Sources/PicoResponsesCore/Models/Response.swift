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

public struct ResponseStatusDetails: Codable, Sendable, Equatable {
    public let type: String?
    public let reason: String?
    public let raw: [String: AnyCodable]

    public init(type: String? = nil, reason: String? = nil, raw: [String: AnyCodable] = [:]) {
        self.type = type
        self.reason = reason
        self.raw = raw
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
        self.reason = reason
        self.type = type
        self.raw = raw
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
        self.reason = reason
        self.message = message
        self.raw = raw
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
        self.code = code
        self.message = message
        self.param = param
        self.raw = raw
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
        self.code = code
        self.message = message
        self.type = type
        self.raw = raw
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
        outputTokensDetails: OutputTokenDetails,
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

// MARK: - Response Options

public enum TextVerbosity: String, Codable, Sendable, Equatable {
    case low
    case medium
    case high
}

/// `TextResponseFormat` as defined by Open Responses. This is the minimum required shape
/// for `text.format` when using plain text output.
public struct TextResponseFormat: Codable, Sendable, Equatable {
    public let type: String

    public init(type: String = "text") {
        self.type = type
    }
}

/// Request-side `text` configuration (TextParam in the spec).
/// The acceptance tests require `format` to be present when `text` is provided.
public struct ResponseTextParam: Codable, Sendable, Equatable {
    public let format: TextResponseFormat
    public let verbosity: TextVerbosity?

    public init(format: TextResponseFormat = TextResponseFormat(), verbosity: TextVerbosity? = nil) {
        self.format = format
        self.verbosity = verbosity
    }
}

/// Response-side `text` configuration (TextField in the spec). `format` is required.
public struct ResponseTextField: Codable, Sendable, Equatable {
    public let format: TextResponseFormat
    public let verbosity: TextVerbosity?

    public init(format: TextResponseFormat = TextResponseFormat(), verbosity: TextVerbosity? = nil) {
        self.format = format
        self.verbosity = verbosity
    }
}

public enum ResponseModality: String, Codable, Sendable {
    case text
    case audio
    case image
    case video
}

public struct ResponseFormat: Codable, Sendable, Equatable {
    public enum FormatType: String, Codable, Sendable {
        case auto
        case text
        case jsonSchema = "json_schema"
    }

    public let type: FormatType
    public let jsonSchema: JSONSchema?
    public let strict: Bool?

    public init(type: FormatType = .auto, jsonSchema: JSONSchema? = nil, strict: Bool? = nil) {
        self.type = type
        self.jsonSchema = jsonSchema
        self.strict = strict
    }

}

public struct ResponseAudioOptions: Codable, Sendable, Equatable {
    public let voice: String?
    public let format: String?

    public init(voice: String? = nil, format: String? = nil) {
        self.voice = voice
        self.format = format
    }
}

public struct ResponseReasoningOptions: Codable, Sendable, Equatable {
    public let effort: String?
    public let minOutputTokens: Int?
    public let maxOutputTokens: Int?

    public init(effort: String? = nil, minOutputTokens: Int? = nil, maxOutputTokens: Int? = nil) {
        self.effort = effort
        self.minOutputTokens = minOutputTokens
        self.maxOutputTokens = maxOutputTokens
    }

}

public enum ResponseTruncationEnum: String, Codable, Sendable, Equatable {
    case auto, disabled
}

public struct ResponseTruncationStrategy: Codable, Sendable, Equatable {
    public let type: String?
    public let maxInputTokens: Int?

    public init(type: String? = nil, maxInputTokens: Int? = nil) {
        self.type = type
        self.maxInputTokens = maxInputTokens
    }

}

// MARK: - Content Blocks

public enum ResponseContentType: String, Codable, Sendable {
    case text
    case inputText = "input_text"
    case outputText = "output_text"
    case refusal
    case imageUrl = "image_url"
    case imageFile = "image_file"
    case inputAudio = "input_audio"
    case outputAudio = "output_audio"
    case toolCall = "tool_call"
    case toolOutput = "tool_output"
    case reasoning
    case summaryText = "summary_text"
    case json
}

public struct ResponseContentBlock: Codable, Sendable, Equatable {
    public let type: ResponseContentType
    public let data: [String: AnyCodable]

    public init(type: ResponseContentType, data: [String: AnyCodable] = [:]) {
        var payload = data
        payload["type"] = AnyCodable(type.rawValue)
        self.type = type
        self.data = payload
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dictionary = try container.decode([String: AnyCodable].self)
        let typeString = dictionary["type"]?.stringValue ?? "text"
        self.type = ResponseContentType(rawValue: typeString) ?? .text
        self.data = dictionary
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }

    public var text: String? {
        data["text"]?.stringValue
    }

    public var annotations: [AnyCodable]? {
        data["annotations"]?.arrayValue
    }

    public var toolCall: ResponseToolCall? {
        guard type == .toolCall else {
            return nil
        }
        return data.decode(ResponseToolCall.self)
    }

    public var toolOutput: ResponseToolOutput? {
        guard type == .toolOutput else {
            return nil
        }
        return data.decode(ResponseToolOutput.self)
    }

    public func decode<T: Decodable>(_ decodableType: T.Type, decoder: JSONDecoder = ResponsesJSONCoding.makeDecoder()) -> T? {
        data.decode(decodableType, using: decoder)
    }
}

public extension ResponseContentBlock {
    static func text(_ value: String) -> ResponseContentBlock {
        ResponseContentBlock(type: .text, data: ["text": AnyCodable(value)])
    }

    static func inputText(_ value: String) -> ResponseContentBlock {
        ResponseContentBlock(type: .inputText, data: ["text": AnyCodable(value)])
    }

    static func outputText(_ value: String) -> ResponseContentBlock {
        ResponseContentBlock(type: .outputText, data: ["text": AnyCodable(value)])
    }

    static func imageURL(_ url: URL) -> ResponseContentBlock {
        ResponseContentBlock(type: .imageUrl, data: ["image_url": AnyCodable(["url": url.absoluteString])])
    }

    static func json(_ object: [String: Any]) -> ResponseContentBlock {
        ResponseContentBlock(type: .json, data: ["json": AnyCodable(object)])
    }
    
    static func reasoning(_ value: String) -> ResponseContentBlock {
        ResponseContentBlock(type: .reasoning, data: ["text": AnyCodable(value)])
    }
    
    static func refusal(_ value: String) -> ResponseContentBlock {
        ResponseContentBlock(type: .refusal, data: ["refusal": AnyCodable(value)])
    }
}

public enum MessageRole: String, Codable, Sendable {
    case user
    case system
    case assistant
    case tool
    case developer
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

public extension ResponseInputItem {
    static func message(role: MessageRole, content: [ResponseContentBlock], metadata: [String: AnyCodable]? = nil) -> ResponseInputItem {
        .message(ResponseMessageInput(role: role, content: content, metadata: metadata))
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
    public let status: String?
    public let metadata: [String: AnyCodable]?
    public let finishReason: String?
    public let refusal: ResponseRefusal?
    public let summary: [AnyCodable]?
    public let toolChoice: ToolChoice

    public init(
        id: String,
        type: ResponseOutputType = .message,
        role: MessageRole? = nil,
        content: [ResponseContentBlock] = [],
        status: String? = nil,
        metadata: [String: AnyCodable]? = nil,
        finishReason: String? = nil,
        refusal: ResponseRefusal? = nil,
        summary: [AnyCodable]? = nil,
        toolChoice: ToolChoice
    ) {
        self.id = id
        self.type = type
        self.role = role
        self.content = content
        self.status = status
        self.metadata = metadata
        self.finishReason = finishReason
        self.refusal = refusal
        self.summary = summary
        self.toolChoice = toolChoice
    }

    public init(
        id: String,
        role: MessageRole,
        content: [ResponseContentBlock],
        status: String? = nil,
        metadata: [String: AnyCodable]? = nil,
        finishReason: String? = nil,
        refusal: ResponseRefusal? = nil,
        toolChoice: ToolChoice
    ) {
        self.init(
            id: id,
            type: .message,
            role: role,
            content: content,
            status: status,
            metadata: metadata,
            finishReason: finishReason,
            refusal: refusal,
            summary: nil,
            toolChoice: toolChoice
        )
    }

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case role
        case content
        case status
        case metadata
        case finishReason = "finish_reason"
        case refusal
        case summary
        case toolChoice = "tool_choice"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decodeIfPresent(ResponseOutputType.self, forKey: .type) ?? .message
        self.role = try container.decodeIfPresent(MessageRole.self, forKey: .role)
        self.content = try container.decodeIfPresent([ResponseContentBlock].self, forKey: .content) ?? []
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        self.finishReason = try container.decodeIfPresent(String.self, forKey: .finishReason)
        self.refusal = try container.decodeIfPresent(ResponseRefusal.self, forKey: .refusal)
        self.summary = try container.decodeIfPresent([AnyCodable].self, forKey: .summary)
        self.toolChoice = try container.decode(ToolChoice.self, forKey: .toolChoice)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(role, forKey: .role)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(finishReason, forKey: .finishReason)
        try container.encodeIfPresent(refusal, forKey: .refusal)
        try container.encodeIfPresent(summary, forKey: .summary)
        try container.encode(toolChoice, forKey: .toolChoice)
    }
}

// MARK: - ResponseOutput Convenience Initializers (Server-Side Construction)

public extension ResponseOutput {
    static func message(
        id: String = "msg_\(UUID().uuidString)",
        text: String,
        role: MessageRole = .assistant,
        status: String = "completed",
        finishReason: String? = "stop",
        toolChoice: ToolChoice
    ) -> ResponseOutput {
        ResponseOutput(
            id: id,
            type: .message,
            role: role,
            content: [.outputText(text)],
            status: status,
            finishReason: finishReason,
            toolChoice: toolChoice
        )
    }
    
    static func inProgress(
        id: String = "msg_\(UUID().uuidString)",
        type: ResponseOutputType = .message,
        role: MessageRole = .assistant,
        toolChoice: ToolChoice
    ) -> ResponseOutput {
        ResponseOutput(
            id: id,
            type: type,
            role: role,
            content: [],
            status: "in_progress",
            toolChoice: toolChoice
        )
    }
    
    static func reasoning(
        id: String = "rsn_\(UUID().uuidString)",
        text: String,
        status: String = "completed",
        toolChoice: ToolChoice
    ) -> ResponseOutput {
        ResponseOutput(
            id: id,
            type: .reasoning,
            role: .assistant,
            content: [.reasoning(text)],
            status: status,
            toolChoice: toolChoice
        )
    }
}

public struct ResponseObject: Codable, Sendable, Equatable {
    public let id: String
    public let object: String
    public let createdAt: Date
    public let completedAt: Date?
    public let updatedAt: Date?
    public let expiresAt: Date?
    public let model: String
    public let status: ResponseStatus
    public let statusDetails: ResponseStatusDetails?
    public let incompleteDetails: ResponseIncompleteDetails?
    public let usage: ResponseUsage?
    public let modalities: [ResponseModality]?
    public let responseFormat: ResponseFormat?
    public let instructions: String?
    public let reasoning: ResponseReasoningOptions?
    public let maxOutputTokens: Int?
    public let maxToolCalls: Int?
    public let previousResponseId: String?
    public let safetyIdentifier: String?
    public let promptCacheKey: String?
    public let tools: [ResponseTool]
    public let truncation: ResponseTruncationEnum
    public let parallelToolCalls: Bool
    public let text: ResponseTextField
    public let output: [ResponseOutput]
    public let metadata: [String: AnyCodable]?
    public let temperature: Float
    public let topP: Float
    public let frequencyPenalty: Float
    public let presencePenalty: Float
    public let topLogprobs: Int
    public let store: Bool
    public let background: Bool
    public let serviceTier: String
    public let conversationId: String?
    public let session: String?
    public let finishReason: String?
    public let refusal: ResponseRefusal?
    public let error: ResponseError?

    public init(
        id: String,
        object: String = "response",
        createdAt: Date,
        completedAt: Date? = nil,
        updatedAt: Date? = nil,
        expiresAt: Date? = nil,
        model: String,
        status: ResponseStatus,
        statusDetails: ResponseStatusDetails? = nil,
        incompleteDetails: ResponseIncompleteDetails? = nil,
        usage: ResponseUsage? = nil,
        modalities: [ResponseModality]? = nil,
        responseFormat: ResponseFormat? = nil,
        instructions: String? = nil,
        reasoning: ResponseReasoningOptions? = nil,
        maxOutputTokens: Int? = nil,
        maxToolCalls: Int? = nil,
        previousResponseId: String? = nil,
        safetyIdentifier: String? = nil,
        promptCacheKey: String? = nil,
        tools: [ResponseTool],
        truncation: ResponseTruncationEnum,
        parallelToolCalls: Bool,
        text: ResponseTextField,
        output: [ResponseOutput] = [],
        metadata: [String: AnyCodable]? = nil,
        temperature: Float,
        topP: Float,
        frequencyPenalty: Float,
        presencePenalty: Float,
        topLogprobs: Int,
        store: Bool,
        background: Bool,
        serviceTier: String,
        conversationId: String? = nil,
        session: String? = nil,
        finishReason: String? = nil,
        refusal: ResponseRefusal? = nil,
        error: ResponseError? = nil
    ) {
        self.id = id
        self.object = object
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.updatedAt = updatedAt
        self.expiresAt = expiresAt
        self.model = model
        self.status = status
        self.statusDetails = statusDetails
        self.incompleteDetails = incompleteDetails
        self.usage = usage
        self.modalities = modalities
        self.responseFormat = responseFormat
        self.instructions = instructions
        self.reasoning = reasoning
        self.maxOutputTokens = maxOutputTokens
        self.maxToolCalls = maxToolCalls
        self.previousResponseId = previousResponseId
        self.safetyIdentifier = safetyIdentifier
        self.promptCacheKey = promptCacheKey
        self.tools = tools
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
        self.conversationId = conversationId
        self.session = session
        self.finishReason = finishReason
        self.refusal = refusal
        self.error = error
    }

    enum CodingKeys: String, CodingKey {
        case id
        case object
        case createdAt = "created_at"
        case completedAt = "completed_at"
        case updatedAt = "updated_at"
        case expiresAt = "expires_at"
        case model
        case status
        case statusDetails = "status_details"
        case incompleteDetails = "incomplete_details"
        case usage
        case modalities
        case responseFormat = "response_format"
        case instructions
        case reasoning
        case maxOutputTokens = "max_output_tokens"
        case maxToolCalls = "max_tool_calls"
        case previousResponseId = "previous_response_id"
        case safetyIdentifier = "safety_identifier"
        case promptCacheKey = "prompt_cache_key"
        case tools
        case truncation
        case parallelToolCalls = "parallel_tool_calls"
        case text
        case output
        case metadata
        case temperature
        case topP = "top_p"
        case frequencyPenalty = "frequency_penalty"
        case presencePenalty = "presence_penalty"
        case topLogprobs = "top_logprobs"
        case store
        case background
        case serviceTier = "service_tier"
        case conversationId = "conversation_id"
        case session
        case finishReason = "finish_reason"
        case refusal
        case error
    }
}

public extension ResponseObject {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(object, forKey: .object)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encode(model, forKey: .model)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(statusDetails, forKey: .statusDetails)
        try container.encodeOrNull(incompleteDetails, forKey: .incompleteDetails)
        try container.encodeIfPresent(usage, forKey: .usage)
        try container.encodeIfPresent(modalities, forKey: .modalities)
        try container.encodeIfPresent(responseFormat, forKey: .responseFormat)
        try container.encodeOrNull(instructions, forKey: .instructions)
        try container.encodeOrNull(reasoning, forKey: .reasoning)
        try container.encodeOrNull(maxOutputTokens, forKey: .maxOutputTokens)
        try container.encodeOrNull(maxToolCalls, forKey: .maxToolCalls)
        try container.encodeOrNull(previousResponseId, forKey: .previousResponseId)
        try container.encodeOrNull(safetyIdentifier, forKey: .safetyIdentifier)
        try container.encodeOrNull(promptCacheKey, forKey: .promptCacheKey)
        try encodeRequired(tools, forKey: .tools, in: &container)
        try encodeRequired(truncation, forKey: .truncation, in: &container)
        try encodeRequired(parallelToolCalls, forKey: .parallelToolCalls, in: &container)
        try container.encode(text, forKey: .text)
        try container.encode(output, forKey: .output)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try encodeRequired(temperature, forKey: .temperature, in: &container)
        try encodeRequired(topP, forKey: .topP, in: &container)
        try encodeRequired(frequencyPenalty, forKey: .frequencyPenalty, in: &container)
        try encodeRequired(presencePenalty, forKey: .presencePenalty, in: &container)
        try encodeRequired(topLogprobs, forKey: .topLogprobs, in: &container)
        try encodeRequired(store, forKey: .store, in: &container)
        try encodeRequired(background, forKey: .background, in: &container)
        try encodeRequired(serviceTier, forKey: .serviceTier, in: &container)
        try container.encodeIfPresent(conversationId, forKey: .conversationId)
        try container.encodeIfPresent(session, forKey: .session)
        try container.encodeIfPresent(finishReason, forKey: .finishReason)
        try container.encodeIfPresent(refusal, forKey: .refusal)
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

// MARK: - ResponseObject Convenience Initializers (Server-Side Construction)

public extension ResponseObject {
    static func completed(
        id: String = "resp_\(UUID().uuidString)",
        model: String,
        tools: [ResponseTool],
        truncation: ResponseTruncationEnum,
        parallelToolCalls: Bool,
        text: ResponseTextField = ResponseTextField(),
        output: [ResponseOutput],
        temperature: Float,
        topP: Float,
        frequencyPenalty: Float,
        presencePenalty: Float,
        topLogprobs: Int,
        store: Bool,
        background: Bool,
        serviceTier: String,
        usage: ResponseUsage? = nil,
        createdAt: Date = Date(),
        finishReason: String = "stop"
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
            temperature: temperature,
            topP: topP,
            frequencyPenalty: frequencyPenalty,
            presencePenalty: presencePenalty,
            topLogprobs: topLogprobs,
            store: store,
            background: background,
            serviceTier: serviceTier,
            finishReason: finishReason
        )
    }
    
    static func inProgress(
        id: String = "resp_\(UUID().uuidString)",
        model: String,
        tools: [ResponseTool],
        truncation: ResponseTruncationEnum,
        parallelToolCalls: Bool,
        text: ResponseTextField = ResponseTextField(),
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
            output: [],
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
        text: ResponseTextField = ResponseTextField(),
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
        text: ResponseTextField = ResponseTextField(),
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

// MARK: - Request Payload

public struct ResponseCreateRequest: Codable, Sendable, Equatable {
    public let model: String?
    public let input: [ResponseInputItem]
    public let instructions: String?
    public let modalities: [ResponseModality]?
    public let responseFormat: ResponseFormat?
    public let audio: ResponseAudioOptions?
    public let text: ResponseTextParam?
    public let metadata: [String: AnyCodable]?
    public let temperature: Float?
    public let topP: Float?
    public let stream: Bool?
    public let frequencyPenalty: Float?
    public let presencePenalty: Float?
    public let topLogprobs: Int?
    public let store: Bool?
    public let background: Bool?
    public let serviceTier: String?
    public let stop: [String]?
    public let maxOutputTokens: Int?
    public let maxInputTokens: Int?
    public let truncationStrategy: ResponseTruncationStrategy?
    public let reasoning: ResponseReasoningOptions?
    public let logitBias: [String: Float]?
    public let seed: Int?
    public let parallelToolCalls: Bool?
    public let tools: [ResponseTool]?
    public let toolChoice: ToolChoice?
    public let session: String?
    public let previousResponseId: String?

    public init(
        model: String? = nil,
        input: [ResponseInputItem],
        instructions: String? = nil,
        modalities: [ResponseModality]? = nil,
        responseFormat: ResponseFormat? = nil,
        audio: ResponseAudioOptions? = nil,
        text: ResponseTextParam? = nil,
        metadata: [String: AnyCodable]? = nil,
        temperature: Float? = nil,
        topP: Float? = nil,
        stream: Bool? = nil,
        frequencyPenalty: Float? = nil,
        presencePenalty: Float? = nil,
        topLogprobs: Int? = nil,
        store: Bool? = nil,
        background: Bool? = nil,
        serviceTier: String? = nil,
        stop: [String]? = nil,
        maxOutputTokens: Int? = nil,
        maxInputTokens: Int? = nil,
        truncationStrategy: ResponseTruncationStrategy? = nil,
        reasoning: ResponseReasoningOptions? = nil,
        logitBias: [String: Float]? = nil,
        seed: Int? = nil,
        parallelToolCalls: Bool? = nil,
        tools: [ResponseTool]? = nil,
        toolChoice: ToolChoice? = nil,
        session: String? = nil,
        previousResponseId: String? = nil
    ) {
        self.model = model
        self.input = input
        self.instructions = instructions
        self.modalities = modalities
        self.responseFormat = responseFormat
        self.audio = audio
        self.text = text
        self.metadata = metadata
        self.temperature = temperature
        self.topP = topP
        self.stream = stream
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.topLogprobs = topLogprobs
        self.store = store
        self.background = background
        self.serviceTier = serviceTier
        self.stop = stop
        self.maxOutputTokens = maxOutputTokens
        self.maxInputTokens = maxInputTokens
        self.truncationStrategy = truncationStrategy
        self.reasoning = reasoning
        self.logitBias = logitBias
        self.seed = seed
        self.parallelToolCalls = parallelToolCalls
        self.tools = tools
        self.toolChoice = toolChoice
        self.session = session
        self.previousResponseId = previousResponseId
    }

}

// MARK: - ResponseCreateRequest Validation

public extension ResponseCreateRequest {
    func validate() throws {
        if input.isEmpty {
            throw PicoResponsesError.validationError("input cannot be empty")
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
        
        if let maxOutputTokens, maxOutputTokens < 1 {
            throw PicoResponsesError.validationError("maxOutputTokens must be at least 1")
        }
        
        if let maxInputTokens, maxInputTokens < 1 {
            throw PicoResponsesError.validationError("maxInputTokens must be at least 1")
        }

        if let text, text.format.type.isEmpty {
            throw PicoResponsesError.validationError("text.format.type cannot be empty")
        }
    }
}

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

public struct ResponseStreamEvent: Sendable, Equatable {
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
        
        // Reasoning text
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
        guard kind == .responseReasoningTextDelta else { return nil }
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

// MARK: - ResponseStreamEvent Factory Methods (Server-Side Construction)

public extension ResponseStreamEvent {
    
    init(kind: Kind, data: [String: AnyCodable] = [:]) {
        self.type = kind.rawValue
        self.data = data
    }
    
    // MARK: - Response Lifecycle Events
    
    static func created(response: ResponseObject, sequenceNumber: Int) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseCreated,
            data: [
                "response": AnyCodable(encodeResponse(response)),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    static func inProgress(response: ResponseObject, sequenceNumber: Int) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseInProgress,
            data: [
                "response": AnyCodable(encodeResponse(response)),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    static func completed(response: ResponseObject, sequenceNumber: Int) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseCompleted,
            data: [
                "response": AnyCodable(encodeResponse(response)),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    static func failed(response: ResponseObject, sequenceNumber: Int) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseFailed,
            data: [
                "response": AnyCodable(encodeResponse(response)),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    static func incomplete(response: ResponseObject, sequenceNumber: Int) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseIncomplete,
            data: [
                "response": AnyCodable(encodeResponse(response)),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    // MARK: - Output Item Events
    
    static func outputItemAdded(
        item: ResponseOutput,
        outputIndex: Int,
        sequenceNumber: Int
    ) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseOutputItemAdded,
            data: [
                "item": AnyCodable(encodeOutput(item)),
                "output_index": AnyCodable(outputIndex),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    static func outputItemDone(
        item: ResponseOutput,
        outputIndex: Int,
        sequenceNumber: Int
    ) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseOutputItemDone,
            data: [
                "item": AnyCodable(encodeOutput(item)),
                "output_index": AnyCodable(outputIndex),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    // MARK: - Content Part Events
    
    static func contentPartAdded(
        itemId: String,
        outputIndex: Int,
        contentIndex: Int,
        part: ResponseContentBlock,
        sequenceNumber: Int
    ) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseContentPartAdded,
            data: [
                "item_id": AnyCodable(itemId),
                "output_index": AnyCodable(outputIndex),
                "content_index": AnyCodable(contentIndex),
                "part": AnyCodable(part.data.jsonObject()),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    static func contentPartDone(
        itemId: String,
        outputIndex: Int,
        contentIndex: Int,
        part: ResponseContentBlock,
        sequenceNumber: Int
    ) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseContentPartDone,
            data: [
                "item_id": AnyCodable(itemId),
                "output_index": AnyCodable(outputIndex),
                "content_index": AnyCodable(contentIndex),
                "part": AnyCodable(part.data.jsonObject()),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    // MARK: - Output Text Events
    
    static func outputTextDelta(
        itemId: String,
        outputIndex: Int,
        contentIndex: Int,
        delta: String,
        sequenceNumber: Int
    ) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseOutputTextDelta,
            data: [
                "item_id": AnyCodable(itemId),
                "output_index": AnyCodable(outputIndex),
                "content_index": AnyCodable(contentIndex),
                "delta": AnyCodable(delta),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    static func outputTextDone(
        itemId: String,
        outputIndex: Int,
        contentIndex: Int,
        text: String,
        sequenceNumber: Int
    ) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseOutputTextDone,
            data: [
                "item_id": AnyCodable(itemId),
                "output_index": AnyCodable(outputIndex),
                "content_index": AnyCodable(contentIndex),
                "text": AnyCodable(text),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    // MARK: - Reasoning Text Events
    
    static func reasoningTextDelta(
        itemId: String,
        outputIndex: Int,
        contentIndex: Int,
        delta: String,
        sequenceNumber: Int
    ) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseReasoningTextDelta,
            data: [
                "item_id": AnyCodable(itemId),
                "output_index": AnyCodable(outputIndex),
                "content_index": AnyCodable(contentIndex),
                "delta": AnyCodable(delta),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    static func reasoningTextDone(
        itemId: String,
        outputIndex: Int,
        contentIndex: Int,
        text: String,
        sequenceNumber: Int
    ) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseReasoningTextDone,
            data: [
                "item_id": AnyCodable(itemId),
                "output_index": AnyCodable(outputIndex),
                "content_index": AnyCodable(contentIndex),
                "text": AnyCodable(text),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    // MARK: - Function Call Events
    
    static func functionCallArgumentsDelta(
        itemId: String,
        outputIndex: Int,
        delta: String,
        sequenceNumber: Int
    ) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseFunctionCallArgumentsDelta,
            data: [
                "item_id": AnyCodable(itemId),
                "output_index": AnyCodable(outputIndex),
                "delta": AnyCodable(delta),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    static func functionCallArgumentsDone(
        itemId: String,
        outputIndex: Int,
        name: String,
        arguments: String,
        sequenceNumber: Int
    ) -> ResponseStreamEvent {
        ResponseStreamEvent(
            kind: .responseFunctionCallArgumentsDone,
            data: [
                "item_id": AnyCodable(itemId),
                "output_index": AnyCodable(outputIndex),
                "name": AnyCodable(name),
                "arguments": AnyCodable(arguments),
                "sequence_number": AnyCodable(sequenceNumber)
            ]
        )
    }
    
    // MARK: - Error Event
    
    static func error(
        code: String,
        message: String,
        param: String? = nil,
        sequenceNumber: Int
    ) -> ResponseStreamEvent {
        var data: [String: AnyCodable] = [
            "code": AnyCodable(code),
            "message": AnyCodable(message),
            "sequence_number": AnyCodable(sequenceNumber)
        ]
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
    
    /// Converts the event to an SSE-formatted string: "data: {json}\n\n"
    /// Returns nil if serialization fails.
    func toSSEString() -> String? {
        // Build the event data dictionary
        var eventDict: [String: Any] = ["type": type]
        for (key, value) in data {
            eventDict[key] = value.toJSONValue()
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: eventDict),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        return "data: \(jsonString)\n\n"
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
}
