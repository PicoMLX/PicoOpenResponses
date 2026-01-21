import Foundation
import Testing
@testable import PicoResponsesCore

@Test func responseCreateRequestEncodingBasic() throws {
    let request = ResponseCreateRequest(
        model: "gpt-4o-mini",
        input: [
            .message(
                role: .user,
                content: [
                    .inputText("Hello")
                ]
            )
        ],
        instructions: "Be concise",
        text: TextParam(format: .text(TextResponseFormat()), verbosity: .high),
        metadata: ["conversation_id": AnyCodable("conv_123"), "attempt": AnyCodable("1")],
        temperature: 0.3,
        topP: 0.9,
        frequencyPenalty: 0.1,
        presencePenalty: 0.2,
        topLogprobs: 2,
        store: true,
        background: false,
        serviceTier: "default",
        maxOutputTokens: 256,
        reasoning: ResponseReasoningOptions(effort: "medium"),
        parallelToolCalls: false,
        tools: [
            .function(ResponseToolDefinition(
                name: "weather",
                description: "Get the forecast",
                inputSchema: .object(
                    properties: [
                        "location": .string(minLength: 1, description: "City name"),
                        "unit": .enumeration([
                            AnyCodable("celsius"),
                            AnyCodable("fahrenheit")
                        ])
                    ],
                    required: ["location"],
                    additionalProperties: .boolean(false)
                )
            ))
        ],
        toolChoice: .auto,
        previousResponseId: "resp_456"
    )

    let encoder = ResponsesJSONCoding.makeEncoder()
    let data = try encoder.encode(request)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(json? ["model"] as? String == "gpt-4o-mini")

    guard
        let input = json? ["input"] as? [[String: Any]],
        let first = input.first,
        let content = first["content"] as? [[String: Any]],
        let firstContent = content.first
    else {
        Issue.record("Failed to decode request JSON structure")
        return
    }

    #expect(first["role"] as? String == "user")
    #expect(firstContent["type"] as? String == "input_text")
    #expect(firstContent["text"] as? String == "Hello")

    #expect(json? ["instructions"] as? String == "Be concise")

    let text = json? ["text"] as? [String: Any]
    let format = text? ["format"] as? [String: Any]
    #expect(format? ["type"] as? String == "text")
    #expect(text? ["verbosity"] as? String == "high")

    let metadata = json? ["metadata"] as? [String: Any]
    #expect(metadata? ["conversation_id"] as? String == "conv_123")
    #expect(metadata? ["attempt"] as? String == "1")

    #expect(json? ["temperature"] as? Double == 0.3)
    #expect(json? ["top_p"] as? Double == 0.9)
    #expect(json? ["frequency_penalty"] as? Double == 0.1)
    #expect(json? ["presence_penalty"] as? Double == 0.2)
    #expect(json? ["top_logprobs"] as? Int == 2)
    #expect(json? ["store"] as? Bool == true)
    #expect(json? ["background"] as? Bool == false)
    #expect(json? ["service_tier"] as? String == "default")
    #expect(json? ["max_output_tokens"] as? Int == 256)
    #expect(json? ["parallel_tool_calls"] as? Bool == false)
    #expect(json? ["tool_choice"] as? String == "auto")
    #expect(json? ["previous_response_id"] as? String == "resp_456")

    let tools = json? ["tools"] as? [[String: Any]]
    let firstTool = tools?.first
    #expect(firstTool? ["type"] as? String == "function")
    #expect(firstTool? ["name"] as? String == "weather")
    let inputSchema = firstTool? ["parameters"] as? [String: Any]
    #expect(inputSchema? ["type"] as? String == "object")
    let toolProperties = inputSchema? ["properties"] as? [String: Any]
    let locationSchema = toolProperties? ["location"] as? [String: Any]
    #expect(locationSchema? ["minLength"] as? Int == 1)
    let unitSchema = toolProperties? ["unit"] as? [String: Any]
    let unitEnum = unitSchema? ["enum"] as? [String]
    #expect(unitEnum?.contains("celsius") == true)
}

@Test func responseCreateRequestStreamFlagEncoding() throws {
    let request = ResponseCreateRequest(
        model: "gpt-4.1-mini",
        input: [
            .message(role: .user, content: [.inputText("Hello")])
        ],
        stream: true
    )

    let encoder = ResponsesJSONCoding.makeEncoder()
    let data = try encoder.encode(request)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(json? ["stream"] as? Bool == true)
}
