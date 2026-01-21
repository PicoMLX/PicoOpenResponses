//
//  ResponseCommon.swift
//  PicoResponses
//
//  Created by Ronald Mannak on 1/18/26.

import Foundation

// MARK: - OpenResponses Text Output Configuration

public enum VerbosityEnum: String, Codable, Sendable, Equatable {
    case low
    case medium
    case high
}

public struct TextResponseFormat: Codable, Sendable, Equatable {
    public let type: String

    public init() {
        self.type = "text"
    }
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

public enum ResponseReasoningEffort: String, Codable, Sendable, Equatable {
    case none
    case low
    case medium
    case high
    case xhigh
}

public enum ResponseReasoningSummary: String, Codable, Sendable, Equatable {
    case concise
    case detailed
    case auto
}

public struct ResponseReasoning: Codable, Sendable, Equatable {
    public let effort: ResponseReasoningEffort?
    public let summary: ResponseReasoningSummary?

    public init(effort: ResponseReasoningEffort? = nil, summary: ResponseReasoningSummary? = nil) {
        self.effort = effort
        self.summary = summary
    }
}

public struct ResponseReasoningParam: Codable, Sendable, Equatable {
    public let effort: ResponseReasoningEffort?
    public let summary: ResponseReasoningSummary?

    public init(effort: ResponseReasoningEffort? = nil, summary: ResponseReasoningSummary? = nil) {
        self.effort = effort
        self.summary = summary
    }
}

public enum ResponseTruncationEnum: String, Codable, Sendable, Equatable {
    case auto, disabled
}

public enum ResponseInclude: String, Codable, Sendable, Equatable {
    case reasoningEncryptedContent = "reasoning.encrypted_content"
    case messageOutputTextLogprobs = "message.output_text.logprobs"
}

public struct ResponseStreamOptions: Codable, Sendable, Equatable {
    public let includeObfuscation: Bool?

    public init(includeObfuscation: Bool? = nil) {
        self.includeObfuscation = includeObfuscation
    }
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
    case inputImage = "input_image"
    case inputFile = "input_file"
    case inputAudio = "input_audio"
    case outputAudio = "output_audio"
    // Open Responses uses `reasoning_text` and `summary_text` as content-part types.
    // Keep `reasoning` out of generated payloads; it is not a valid content-part type.
    case reasoningText = "reasoning_text"
    case summaryText = "summary_text"
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
        var normalized = dictionary
        // Normalize model output blocks to include required fields.
        if self.type == .outputText {
            if normalized["annotations"] == nil {
                normalized["annotations"] = AnyCodable([])
            }
            if normalized["logprobs"] == nil {
                normalized["logprobs"] = AnyCodable([])
            }
        }
        self.data = normalized
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

    static func outputText(_ value: String, annotations: [AnyCodable] = [], logprobs: [AnyCodable] = []) -> ResponseContentBlock {
        ResponseContentBlock(
            type: .outputText,
            data: [
                "text": AnyCodable(value),
                // Open Responses OutputTextContent requires these fields, even if empty.
                "annotations": AnyCodable(annotations.map { $0.jsonObject }),
                "logprobs": AnyCodable(logprobs.map { $0.jsonObject })
            ]
        )
    }

    static func imageURL(_ url: URL, detail: String? = nil) -> ResponseContentBlock {
        var data: [String: AnyCodable] = ["image_url": AnyCodable(url.absoluteString)]
        if let detail {
            data["detail"] = AnyCodable(detail)
        }
        return ResponseContentBlock(type: .inputImage, data: data)
    }

    static func reasoning(_ value: String) -> ResponseContentBlock {
        ResponseContentBlock(type: .reasoningText, data: ["text": AnyCodable(value)])
    }

    static func summaryText(_ value: String) -> ResponseContentBlock {
        ResponseContentBlock(type: .summaryText, data: ["text": AnyCodable(value)])
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
