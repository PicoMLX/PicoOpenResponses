import Foundation
import Testing
@testable import PicoResponsesCore

@Test func toolChoiceEncodingRoundTrip() throws {
    let choice = ToolChoice.function(name: "weather")
    let data = try JSONEncoder().encode(choice)
    let raw = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(raw? ["type"] as? String == "function")
    #expect(raw? ["name"] as? String == "weather")

    let decoded = try JSONDecoder().decode(ToolChoice.self, from: data)
    if case .function(let name) = decoded {
        #expect(name == "weather")
    } else {
        Issue.record("Expected function tool choice")
    }
}

@Test func responseToolDefinitionEncodesMCPMetadata() throws {
    let definition = ResponseToolDefinition(
        name: "calendar",
        description: "Calendar availability",
        inputSchema: .object(properties: [:]),
        mcpServer: ResponseToolDefinition.MCPServer(
            label: "Primary Calendar",
            url: URL(string: "https://mcp.example.com")!,
            transport: "sse",
            version: "2024-09-01",
            auth: ["type": AnyCodable("bearer"), "scopes": AnyCodable(["calendar.read"])],
            options: ["region": AnyCodable("us-west-2")],
            metadata: ["environment": AnyCodable("prod")]
        )
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    let data = try encoder.encode(definition)
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    let server = json? ["server"] as? [String: Any]
    #expect(server? ["label"] as? String == "Primary Calendar")
    #expect(server? ["url"] as? String == "https://mcp.example.com")
    #expect(server? ["transport"] as? String == "sse")
    #expect(server? ["version"] as? String == "2024-09-01")
    let auth = json? ["server_auth"] as? [String: Any]
    #expect(auth? ["type"] as? String == "bearer")
    let scopes = auth? ["scopes"] as? [String]
    #expect(scopes?.contains("calendar.read") == true)
    let options = json? ["server_options"] as? [String: Any]
    #expect(options? ["region"] as? String == "us-west-2")
    #expect(json? ["server_label"] as? String == "Primary Calendar")
    #expect(json? ["server_url"] as? String == "https://mcp.example.com")
    let metadata = json? ["server_metadata"] as? [String: Any]
    #expect(metadata? ["environment"] as? String == "prod")
}

@Test func responseToolCallEncodingRoundTrip() throws {
    let payload: [String: Any] = [
        "id": "item_123",
        "call_id": "call_123",
        "name": "find_calendar_slot",
        "arguments": "{\"date\":\"2024-12-01\",\"participants\":[\"alice\",\"bob\"]}",
        "status": "completed",
        "type": "function_call"
    ]

    let data = try JSONSerialization.data(withJSONObject: payload)
    let decoder = ResponsesJSONCoding.makeDecoder()
    let call = try decoder.decode(ResponseToolCall.self, from: data)

    #expect(call.itemId == "item_123")
    #expect(call.callId == "call_123")
    #expect(call.name == "find_calendar_slot")
    #expect(call.arguments.dictionaryValue? ["date"]?.stringValue == "2024-12-01")
    let participants = call.arguments.dictionaryValue? ["participants"]?.arrayValue?.compactMap { $0.stringValue }
    #expect(participants == ["alice", "bob"])
    #expect(call.status == "completed")

    let encoded = try ResponsesJSONCoding.makeEncoder().encode(call)
    let encodedJSON = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
    let arguments = encodedJSON? ["arguments"] as? String
    #expect(arguments?.contains("\"date\"") == true)
    #expect(arguments?.contains("\"participants\"") == true)
}

@Test func responseToolCallDecodesObjectArguments() throws {
    let payload: [String: Any] = [
        "id": "item_456",
        "call_id": "call_456",
        "name": "lookup",
        "arguments": ["query": "hello"],
        "status": "completed",
        "type": "function_call"
    ]

    let data = try JSONSerialization.data(withJSONObject: payload)
    let decoder = ResponsesJSONCoding.makeDecoder()
    let call = try decoder.decode(ResponseToolCall.self, from: data)

    #expect(call.arguments.dictionaryValue? ["query"]?.stringValue == "hello")

    let encoded = try ResponsesJSONCoding.makeEncoder().encode(call)
    let encodedJSON = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
    let arguments = encodedJSON? ["arguments"] as? String
    let argumentsData = arguments?.data(using: .utf8) ?? Data()
    let argumentsJSON = try JSONSerialization.jsonObject(with: argumentsData) as? [String: Any]
    #expect(argumentsJSON? ["query"] as? String == "hello")
}

@Test func responseToolOutputEncodesJSONString() throws {
    let payload: [String: Any] = [
        "id": "item_123",
        "call_id": "call_123",
        "output": "{\"status\":\"ok\",\"count\":2}",
        "status": "completed",
        "type": "function_call_output"
    ]

    let data = try JSONSerialization.data(withJSONObject: payload)
    let decoder = ResponsesJSONCoding.makeDecoder()
    let output = try decoder.decode(ResponseToolOutput.self, from: data)

    #expect(output.callId == "call_123")
    #expect(output.jsonValue? ["status"]?.stringValue == "ok")
    #expect(output.jsonValue? ["count"]?.intValue == 2)

    let encoded = try ResponsesJSONCoding.makeEncoder().encode(output)
    let encodedJSON = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
    let outputString = encodedJSON? ["output"] as? String
    let outputData = outputString?.data(using: .utf8) ?? Data()
    let outputJSON = try JSONSerialization.jsonObject(with: outputData) as? [String: Any]
    #expect(outputJSON? ["status"] as? String == "ok")
    #expect(outputJSON? ["count"] as? Int == 2)
}

@Test func responseToolOutputPreservesContentPartArrays() throws {
    let parts: [AnyCodable] = [
        AnyCodable(["type": "input_text", "text": "Hello"]),
        AnyCodable(["type": "input_file", "filename": "note.txt"])
    ]

    let output = ResponseToolOutput(
        itemId: "item_parts",
        callId: "call_parts",
        payload: .array(parts),
        status: "completed"
    )

    let encoded = try ResponsesJSONCoding.makeEncoder().encode(output)
    let encodedJSON = try JSONSerialization.jsonObject(with: encoded) as? [String: Any]
    let outputArray = encodedJSON? ["output"] as? [[String: Any]]
    #expect(outputArray?.count == 2)
    #expect(outputArray?.first? ["type"] as? String == "input_text")
}
