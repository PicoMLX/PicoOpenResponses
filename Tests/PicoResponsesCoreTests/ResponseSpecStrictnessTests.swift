import Foundation
import Testing
@testable import PicoResponsesCore

private func baseResponseJSON() -> [String: Any] {
    [
        "id": "resp_123",
        "object": "response",
        "created_at": 1,
        "completed_at": NSNull(),
        "model": "gpt-4o-mini",
        "status": "in_progress",
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
        "metadata": [
            "flag": true,
            "count": 3,
            "pi": 3.14,
            "tags": ["alpha", "beta"],
            "nested": ["id": "meta_1"]
        ],
        "temperature": 1,
        "top_p": 1,
        "frequency_penalty": 0,
        "presence_penalty": 0,
        "top_logprobs": 0,
        "store": false,
        "background": false,
        "service_tier": "default",
        "error": NSNull()
    ]
}

private func baseResponseObject(
    completedAt: Date? = nil,
    incompleteDetails: ResponseIncompleteDetails? = nil,
    usage: ResponseUsage? = nil,
    instructions: String? = nil,
    reasoning: ResponseReasoning? = nil,
    maxOutputTokens: Int? = nil,
    maxToolCalls: Int? = nil,
    previousResponseId: String? = nil,
    safetyIdentifier: String? = nil,
    promptCacheKey: String? = nil,
    error: ResponseError? = nil,
    metadata: [String: AnyCodable] = [:]
) -> ResponseObject {
    ResponseObject(
        id: "resp_123",
        object: "response",
        createdAt: Date(timeIntervalSince1970: 1),
        completedAt: completedAt,
        model: "gpt-4o-mini",
        status: .inProgress,
        incompleteDetails: incompleteDetails,
        usage: usage,
        instructions: instructions,
        reasoning: reasoning,
        maxOutputTokens: maxOutputTokens,
        maxToolCalls: maxToolCalls,
        previousResponseId: previousResponseId,
        safetyIdentifier: safetyIdentifier,
        promptCacheKey: promptCacheKey,
        tools: [],
        toolChoice: .auto,
        truncation: .disabled,
        parallelToolCalls: false,
        text: .default,
        output: [],
        metadata: metadata,
        temperature: 1,
        topP: 1,
        frequencyPenalty: 0,
        presencePenalty: 0,
        topLogprobs: 0,
        store: false,
        background: false,
        serviceTier: "default",
        error: error
    )
}

@Test func responseObjectEncodingIncludesNullsForRequiredNullableFields() throws {
    let response = baseResponseObject(metadata: [:])
    let data = try ResponsesJSONCoding.makeEncoder().encode(response)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    let nullKeys = [
        "completed_at",
        "incomplete_details",
        "usage",
        "instructions",
        "reasoning",
        "max_output_tokens",
        "max_tool_calls",
        "previous_response_id",
        "safety_identifier",
        "prompt_cache_key",
        "error"
    ]

    for key in nullKeys {
        guard let value = json?[key] else {
            Issue.record("Missing required key: \(key)")
            continue
        }
        #expect(value is NSNull)
    }
}

@Test func responseObjectDecodingRequiresPresenceOfNullableFields() throws {
    let decoder = ResponsesJSONCoding.makeDecoder()
    let base = baseResponseJSON()
    let requiredNullableKeys = [
        "completed_at",
        "incomplete_details",
        "usage",
        "instructions",
        "reasoning",
        "max_output_tokens",
        "max_tool_calls",
        "previous_response_id",
        "safety_identifier",
        "prompt_cache_key",
        "error"
    ]

    for key in requiredNullableKeys {
        var payload = base
        payload.removeValue(forKey: key)
        let data = try JSONSerialization.data(withJSONObject: payload)
        var didThrow = false
        do {
            _ = try decoder.decode(ResponseObject.self, from: data)
        } catch {
            didThrow = true
        }
        if !didThrow {
            Issue.record("Expected decoding to fail when missing \(key)")
        }
        #expect(didThrow)
    }
}

@Test func responseObjectDecodingAcceptsExplicitNulls() throws {
    let data = try JSONSerialization.data(withJSONObject: baseResponseJSON())
    let decoder = ResponsesJSONCoding.makeDecoder()
    let response = try decoder.decode(ResponseObject.self, from: data)

    #expect(response.completedAt == nil)
    #expect(response.incompleteDetails == nil)
    #expect(response.usage == nil)
    #expect(response.instructions == nil)
    #expect(response.reasoning == nil)
    #expect(response.maxOutputTokens == nil)
    #expect(response.maxToolCalls == nil)
    #expect(response.previousResponseId == nil)
    #expect(response.safetyIdentifier == nil)
    #expect(response.promptCacheKey == nil)
    #expect(response.error == nil)

    #expect(response.metadata["flag"]?.boolValue == true)
    #expect(response.metadata["count"]?.intValue == 3)
    #expect(response.metadata["pi"]?.doubleValue == 3.14)
    let tags = response.metadata["tags"]?.arrayValue?.compactMap { $0.stringValue }
    #expect(tags == ["alpha", "beta"])
    #expect(response.metadata["nested"]?.dictionaryValue?["id"]?.stringValue == "meta_1")
}

@Test func responseReasoningEncodingIncludesNulls() throws {
    let reasoning = ResponseReasoning()
    let data = try ResponsesJSONCoding.makeEncoder().encode(reasoning)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(json?["effort"] is NSNull)
    #expect(json?["summary"] is NSNull)
}

@Test func responseReasoningDecodingRequiresKeys() throws {
    let decoder = ResponsesJSONCoding.makeDecoder()
    let missingPayload = try JSONSerialization.data(withJSONObject: [:])
    var didThrow = false
    do {
        _ = try decoder.decode(ResponseReasoning.self, from: missingPayload)
    } catch {
        didThrow = true
    }
    #expect(didThrow)

    let nullPayload = try JSONSerialization.data(withJSONObject: ["effort": NSNull(), "summary": NSNull()])
    _ = try decoder.decode(ResponseReasoning.self, from: nullPayload)
}

@Test func responseIncompleteDetailsEncodesReason() throws {
    let response = ResponseObject.incomplete(
        id: "resp_incomplete",
        model: "gpt-4o-mini",
        tools: [],
        truncation: .disabled,
        parallelToolCalls: false,
        output: [],
        reason: "max_output_tokens",
        temperature: 1,
        topP: 1,
        frequencyPenalty: 0,
        presencePenalty: 0,
        topLogprobs: 0,
        store: false,
        background: false,
        serviceTier: "default"
    )

    let data = try ResponsesJSONCoding.makeEncoder().encode(response)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let incomplete = json? ["incomplete_details"] as? [String: Any]
    #expect(incomplete? ["reason"] as? String == "max_output_tokens")
}

@Test func responseErrorEncodesCodeAndMessage() throws {
    let response = ResponseObject.failed(
        id: "resp_failed",
        model: "gpt-4o-mini",
        tools: [],
        truncation: .disabled,
        parallelToolCalls: false,
        error: ResponseError(code: "rate_limit", message: "Too many requests"),
        temperature: 1,
        topP: 1,
        frequencyPenalty: 0,
        presencePenalty: 0,
        topLogprobs: 0,
        store: false,
        background: false,
        serviceTier: "default"
    )

    let data = try ResponsesJSONCoding.makeEncoder().encode(response)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let error = json? ["error"] as? [String: Any]
    #expect(error? ["code"] as? String == "rate_limit")
    #expect(error? ["message"] as? String == "Too many requests")
}

@Test func responseErrorEncodingRequiresCodeAndMessage() throws {
    var didThrow = false
    do {
        _ = try ResponsesJSONCoding.makeEncoder().encode(ResponseError())
    } catch {
        didThrow = true
    }
    #expect(didThrow)
}

@Test func responseErrorDecodingRequiresCodeAndMessage() throws {
    let decoder = ResponsesJSONCoding.makeDecoder()
    let missingCode = try JSONSerialization.data(withJSONObject: ["message": "failed"])
    let missingMessage = try JSONSerialization.data(withJSONObject: ["code": "server_error"])

    for payload in [missingCode, missingMessage] {
        var didThrow = false
        do {
            _ = try decoder.decode(ResponseError.self, from: payload)
        } catch {
            didThrow = true
        }
        #expect(didThrow)
    }
}

@Test func responseIncompleteDetailsDecodingRequiresReason() throws {
    let decoder = ResponsesJSONCoding.makeDecoder()
    let payload = try JSONSerialization.data(withJSONObject: ["type": "length"])
    var didThrow = false
    do {
        _ = try decoder.decode(ResponseIncompleteDetails.self, from: payload)
    } catch {
        didThrow = true
    }
    #expect(didThrow)
}

@Test func responseIncompleteDetailsEncodingRequiresReason() throws {
    var didThrow = false
    do {
        _ = try ResponsesJSONCoding.makeEncoder().encode(ResponseIncompleteDetails())
    } catch {
        didThrow = true
    }
    #expect(didThrow)
}

@Test func responseToolDefinitionEncodingIncludesRequiredKeys() throws {
    let tool = ResponseToolDefinition(name: "weather")
    let data = try ResponsesJSONCoding.makeEncoder().encode(tool)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    #expect(json? ["type"] as? String == "function")
    #expect(json? ["name"] as? String == "weather")
    #expect(json? ["description"] is NSNull)
    #expect(json? ["parameters"] is NSNull)
    #expect(json? ["strict"] as? Bool == true)
}

@Test func responseToolDefinitionDecodingRequiresKeys() throws {
    let decoder = ResponsesJSONCoding.makeDecoder()
    let payload = try JSONSerialization.data(withJSONObject: ["type": "function", "name": "weather"])
    var didThrow = false
    do {
        _ = try decoder.decode(ResponseToolDefinition.self, from: payload)
    } catch {
        didThrow = true
    }
    #expect(didThrow)
}

@Test func responseOutputReasoningEncodingOmitsRoleAndStatus() throws {
    let output = ResponseOutput.reasoning(id: "rsn_1", summaryText: "Summary text")
    let data = try ResponsesJSONCoding.makeEncoder().encode(output)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    #expect(json? ["type"] as? String == "reasoning")
    #expect(json? ["role"] == nil)
    #expect(json? ["status"] == nil)
    #expect(json? ["content"] == nil)
    let summary = json? ["summary"] as? [[String: Any]]
    #expect(summary?.first? ["type"] as? String == "input_text")
    #expect(summary?.first? ["text"] as? String == "Summary text")
}

@Test func responseOutputFunctionCallDecodingRequiresFields() throws {
    let base: [String: Any] = [
        "id": "item_call",
        "type": "function_call",
        "call_id": "call_1",
        "name": "lookup",
        "arguments": "{\"query\":\"hi\"}",
        "status": "completed"
    ]

    let decoder = ResponsesJSONCoding.makeDecoder()
    let data = try JSONSerialization.data(withJSONObject: base)
    let output = try decoder.decode(ResponseOutput.self, from: data)
    #expect(output.callId == "call_1")
    #expect(output.name == "lookup")
    #expect(output.arguments?.dictionaryValue?["query"]?.stringValue == "hi")

    for key in ["call_id", "name", "arguments", "status"] {
        var payload = base
        payload.removeValue(forKey: key)
        let missing = try JSONSerialization.data(withJSONObject: payload)
        var didThrow = false
        do {
            _ = try decoder.decode(ResponseOutput.self, from: missing)
        } catch {
            didThrow = true
        }
        #expect(didThrow)
    }
}

@Test func responseOutputFunctionCallEncodingIncludesRequiredFields() throws {
    let output = ResponseOutput.functionCall(
        id: "item_call",
        callId: "call_1",
        name: "lookup",
        arguments: ResponseToolCall.Arguments(json: ["query": AnyCodable("hi")])
    )
    let data = try ResponsesJSONCoding.makeEncoder().encode(output)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(json? ["type"] as? String == "function_call")
    #expect(json? ["call_id"] as? String == "call_1")
    #expect(json? ["name"] as? String == "lookup")
    #expect(json? ["arguments"] as? String != nil)
    #expect(json? ["status"] as? String == "completed")
}

@Test func responseOutputFunctionCallOutputDecodingRequiresFields() throws {
    let base: [String: Any] = [
        "id": "item_out",
        "type": "function_call_output",
        "call_id": "call_1",
        "output": "{\"ok\":true}",
        "status": "completed"
    ]

    let decoder = ResponsesJSONCoding.makeDecoder()
    let data = try JSONSerialization.data(withJSONObject: base)
    let output = try decoder.decode(ResponseOutput.self, from: data)
    #expect(output.callId == "call_1")
    if case .string(let value)? = output.output {
        #expect(value == "{\"ok\":true}")
    } else {
        Issue.record("Expected string output payload.")
    }

    for key in ["call_id", "output", "status"] {
        var payload = base
        payload.removeValue(forKey: key)
        let missing = try JSONSerialization.data(withJSONObject: payload)
        var didThrow = false
        do {
            _ = try decoder.decode(ResponseOutput.self, from: missing)
        } catch {
            didThrow = true
        }
        #expect(didThrow)
    }
}

@Test func responseOutputFunctionCallOutputEncodingIncludesRequiredFields() throws {
    let output = ResponseOutput.functionCallOutput(
        id: "item_out",
        callId: "call_1",
        output: .string("{\"ok\":true}")
    )
    let data = try ResponsesJSONCoding.makeEncoder().encode(output)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(json? ["type"] as? String == "function_call_output")
    #expect(json? ["call_id"] as? String == "call_1")
    #expect(json? ["output"] as? String == "{\"ok\":true}")
    #expect(json? ["status"] as? String == "completed")
}

@Test func responseOutputMessageDecodingRequiresFields() throws {
    let base: [String: Any] = [
        "id": "item_1",
        "type": "message",
        "role": "assistant",
        "status": "completed",
        "content": [
            ["type": "output_text", "text": "Hello", "annotations": [], "logprobs": []]
        ]
    ]

    let decoder = ResponsesJSONCoding.makeDecoder()
    let requiredKeys = ["type", "role", "status", "content"]
    for key in requiredKeys {
        var payload = base
        payload.removeValue(forKey: key)
        let data = try JSONSerialization.data(withJSONObject: payload)
        var didThrow = false
        do {
            _ = try decoder.decode(ResponseOutput.self, from: data)
        } catch {
            didThrow = true
        }
        if !didThrow {
            Issue.record("Expected decoding to fail when missing \(key)")
        }
        #expect(didThrow)
    }
}

@Test func responseOutputReasoningDecodingRequiresSummary() throws {
    let payload: [String: Any] = [
        "id": "item_reasoning",
        "type": "reasoning"
    ]
    let decoder = ResponsesJSONCoding.makeDecoder()
    let data = try JSONSerialization.data(withJSONObject: payload)
    var didThrow = false
    do {
        _ = try decoder.decode(ResponseOutput.self, from: data)
    } catch {
        didThrow = true
    }
    #expect(didThrow)
}

@Test func responseItemStatusUnknownFallsBack() throws {
    let payload: [String: Any] = [
        "id": "item_2",
        "type": "message",
        "role": "assistant",
        "status": "mystery_status",
        "content": [
            ["type": "output_text", "text": "Hello", "annotations": [], "logprobs": []]
        ]
    ]
    let data = try JSONSerialization.data(withJSONObject: payload)
    let decoder = ResponsesJSONCoding.makeDecoder()
    let output = try decoder.decode(ResponseOutput.self, from: data)
    if case .unknown(let value) = output.status {
        #expect(value == "mystery_status")
    } else {
        Issue.record("Expected unknown status fallback.")
    }
}

@Test func responseContentBlockNormalizesOutputText() throws {
    let payload: [String: Any] = [
        "type": "output_text",
        "text": "Normalized"
    ]
    let data = try JSONSerialization.data(withJSONObject: payload)
    let decoder = ResponsesJSONCoding.makeDecoder()
    let block = try decoder.decode(ResponseContentBlock.self, from: data)
    #expect(block.type == .outputText)
    #expect(block.annotations?.isEmpty == true)
    #expect(block.data["logprobs"]?.arrayValue?.isEmpty == true)
}

@Test func responseContentBlockImageURLDefaultsDetail() {
    let url = URL(string: "https://example.com/image.png")!
    let block = ResponseContentBlock.imageURL(url)
    #expect(block.data["detail"]?.stringValue == "auto")
}

@Test func responseContentBlockRoundTripsVariousTypes() throws {
    let blocks: [ResponseContentBlock] = [
        .inputText("Hello"),
        .outputText("Hi", annotations: [AnyCodable(["tag": "greeting"])], logprobs: []),
        ResponseContentBlock(type: .inputImage, data: [
            "image_url": AnyCodable("https://example.com/image.png"),
            "detail": AnyCodable("high")
        ]),
        ResponseContentBlock(type: .inputFile, data: [
            "filename": AnyCodable("notes.txt"),
            "file_url": AnyCodable("https://example.com/notes.txt")
        ]),
        ResponseContentBlock(type: .inputAudio, data: [
            "audio_url": AnyCodable("https://example.com/audio.wav")
        ]),
        ResponseContentBlock(type: .outputAudio, data: [
            "audio_url": AnyCodable("https://example.com/response.wav")
        ]),
        .refusal("Policy refusal"),
        .reasoning("Reasoning text"),
        .summaryText("Summary text")
    ]

    let data = try ResponsesJSONCoding.makeEncoder().encode(blocks)
    let decoder = ResponsesJSONCoding.makeDecoder()
    let decoded = try decoder.decode([ResponseContentBlock].self, from: data)

    #expect(decoded.count == blocks.count)
    #expect(decoded[0].type == .inputText)
    #expect(decoded[1].type == .outputText)
    #expect(decoded[2].type == .inputImage)
    #expect(decoded[3].type == .inputFile)
    #expect(decoded[4].type == .inputAudio)
    #expect(decoded[5].type == .outputAudio)
    #expect(decoded[6].type == .refusal)
    #expect(decoded[7].type == .reasoningText)
    #expect(decoded[8].type == .summaryText)

    #expect(decoded[2].data["image_url"]?.stringValue == "https://example.com/image.png")
    #expect(decoded[3].data["filename"]?.stringValue == "notes.txt")
    #expect(decoded[4].data["audio_url"]?.stringValue == "https://example.com/audio.wav")
    #expect(decoded[5].data["audio_url"]?.stringValue == "https://example.com/response.wav")
}

@Test func responseContentBlockUnknownTypeFallsBackToText() throws {
    let payload: [String: Any] = [
        "type": "unknown_type",
        "text": "Fallback"
    ]
    let data = try JSONSerialization.data(withJSONObject: payload)
    let decoder = ResponsesJSONCoding.makeDecoder()
    let block = try decoder.decode(ResponseContentBlock.self, from: data)
    #expect(block.type == .text)
}
