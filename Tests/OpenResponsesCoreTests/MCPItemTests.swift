import Foundation
import Testing
@testable import OpenResponses

// OpenAI's MCP items and the `mcp` tool, as the Responses API documents them.

private func jsonObject<T: Encodable>(_ value: T) throws -> [String: Any] {
    let data = try ResponsesJSONCoding.makeEncoder().encode(value)
    return try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
}

private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
    try ResponsesJSONCoding.makeDecoder().decode(type, from: Data(json.utf8))
}

@Test func mcpCallEncodesOpenAIFields() throws {
    let item = ResponseOutput.mcpCall(
        id: "mcp_1", serverLabel: "pico", name: "get_weather", arguments: #"{"city":"Paris"}"#,
        output: #"{"temp":21}"#, approvalRequestId: "mcpr_1")
    let json = try jsonObject(item)

    #expect(json["type"] as? String == "mcp_call")
    #expect(json["id"] as? String == "mcp_1")
    #expect(json["server_label"] as? String == "pico")
    #expect(json["name"] as? String == "get_weather")
    #expect(json["arguments"] as? String == #"{"city":"Paris"}"#)
    #expect(json["output"] as? String == #"{"temp":21}"#)
    #expect(json["error"] is NSNull)
    #expect(json["approval_request_id"] as? String == "mcpr_1")
    #expect(json["status"] as? String == "completed")
    // A message's fields don't belong on an MCP item.
    #expect(json["content"] == nil)
    #expect(json["role"] == nil)
    #expect(json["call_id"] == nil)
}

@Test func runningMCPCallHasNullOutputAndError() throws {
    let item = ResponseOutput.mcpCall(
        id: "mcp_1", serverLabel: "pico", name: "get_weather", arguments: "{}", status: .inProgress)
    let json = try jsonObject(item)

    #expect(json["status"] as? String == "in_progress")
    #expect(json["output"] is NSNull)
    #expect(json["error"] is NSNull)
    #expect(json["approval_request_id"] is NSNull)
}

@Test func mcpCallDecodesFromOpenAIJSON() throws {
    let item = try decode(ResponseOutput.self, """
    {"id":"mcp_2","type":"mcp_call","server_label":"pico","name":"write_file",
     "arguments":"{\\"path\\":\\"a\\"}","output":null,"error":"Denied","approval_request_id":null,
     "status":"failed"}
    """)

    #expect(item.type == .mcpCall)
    #expect(item.serverLabel == "pico")
    #expect(item.name == "write_file")
    #expect(item.arguments?.string == #"{"path":"a"}"#)
    #expect(item.output == nil)
    #expect(item.error == "Denied")
    #expect(item.status == .unknown("failed"))
}

@Test func mcpListToolsRoundTrips() throws {
    let tool = MCPListedTool(
        name: "get_weather", description: "Weather for a city",
        inputSchema: AnyCodable(["type": "object", "additionalProperties": false]),
        annotations: AnyCodable(["readOnlyHint": true]))
    let item = ResponseOutput.mcpListTools(id: "mcpl_1", serverLabel: "pico", tools: [tool])
    let json = try jsonObject(item)

    #expect(json["type"] as? String == "mcp_list_tools")
    #expect(json["server_label"] as? String == "pico")
    #expect(json["status"] == nil)
    #expect(json["content"] == nil)
    let tools = try #require(json["tools"] as? [[String: Any]])
    #expect(tools.first?["name"] as? String == "get_weather")
    // Schema and annotation keys stay as sent, not snake-cased.
    let schema = try #require(tools.first?["input_schema"] as? [String: Any])
    #expect(schema["additionalProperties"] as? Bool == false)
    #expect((tools.first?["annotations"] as? [String: Any])?["readOnlyHint"] as? Bool == true)

    let data = try ResponsesJSONCoding.makeEncoder().encode(item)
    let decoded = try ResponsesJSONCoding.makeDecoder().decode(ResponseOutput.self, from: data)
    #expect(decoded.tools?.first?.name == "get_weather")
    #expect(decoded.serverLabel == "pico")
}

@Test func mcpApprovalRequestEncodesOpenAIFields() throws {
    let item = ResponseOutput.mcpApprovalRequest(
        id: "mcpr_1", serverLabel: "pico", name: "write_file", arguments: #"{"path":"a"}"#)
    let json = try jsonObject(item)

    #expect(json["type"] as? String == "mcp_approval_request")
    #expect(json["id"] as? String == "mcpr_1")
    #expect(json["server_label"] as? String == "pico")
    #expect(json["name"] as? String == "write_file")
    #expect(json["arguments"] as? String == #"{"path":"a"}"#)
    #expect(json["status"] == nil)

    let data = try ResponsesJSONCoding.makeEncoder().encode(item)
    let decoded = try ResponsesJSONCoding.makeDecoder().decode(ResponseOutput.self, from: data)
    #expect(decoded.type == .mcpApprovalRequest)
    #expect(decoded.name == "write_file")
}

@Test func mcpToolDecodesAllowedToolsListAndFilter() throws {
    let list = try decode(ResponseTool.self, """
    {"type":"mcp","server_label":"pico","server_url":"http://pico.local/mcp","allowed_tools":["a","b"]}
    """)
    guard case .mcp(let listConfig) = list else { Issue.record("Expected an mcp tool"); return }
    #expect(listConfig.serverLabel == "pico")
    #expect(listConfig.serverUrl == "http://pico.local/mcp")
    #expect(listConfig.allowedTools == MCPToolFilter(toolNames: ["a", "b"]))
    #expect(listConfig.requireApproval == nil)

    let filter = try decode(ResponseTool.self, """
    {"type":"mcp","server_label":"pico","allowed_tools":{"tool_names":["a"],"read_only":true}}
    """)
    guard case .mcp(let filterConfig) = filter else { Issue.record("Expected an mcp tool"); return }
    #expect(filterConfig.allowedTools == MCPToolFilter(toolNames: ["a"], readOnly: true))
}

@Test func mcpToolDecodesEveryRequireApprovalForm() throws {
    func requirement(_ value: String) throws -> MCPApprovalRequirement? {
        let tool = try decode(ResponseTool.self, #"{"type":"mcp","server_label":"pico","require_approval":\#(value)}"#)
        guard case .mcp(let config) = tool else { return nil }
        return config.requireApproval
    }

    #expect(try requirement(#""always""#) == .always)
    #expect(try requirement(#""never""#) == .never)
    #expect(try requirement(#"{"never":{"tool_names":["get_weather"]}}"#)
        == .filter(always: nil, never: MCPToolFilter(toolNames: ["get_weather"])))
    #expect(try requirement(#"{"always":{"read_only":false},"never":{"read_only":true}}"#)
        == .filter(always: MCPToolFilter(readOnly: false), never: MCPToolFilter(readOnly: true)))
    #expect(throws: DecodingError.self) { try requirement(#""sometimes""#) }
}

@Test func mcpToolEncodesWhatItDecoded() throws {
    let config = MCPToolConfig(
        serverLabel: "pico", serverUrl: "http://pico.local/mcp",
        allowedTools: MCPToolFilter(toolNames: ["a"]),
        requireApproval: .filter(always: nil, never: MCPToolFilter(toolNames: ["a"])))
    let json = try jsonObject(ResponseTool.mcp(config))

    #expect(json["type"] as? String == "mcp")
    #expect(json["server_label"] as? String == "pico")
    #expect(json["server_url"] as? String == "http://pico.local/mcp")
    #expect(json["allowed_tools"] as? [String] == ["a"])
    let never = (json["require_approval"] as? [String: Any])?["never"] as? [String: Any]
    #expect(never?["tool_names"] as? [String] == ["a"])

    let readOnly = try jsonObject(ResponseTool.mcp(MCPToolConfig(
        serverLabel: "pico", allowedTools: MCPToolFilter(readOnly: true), requireApproval: .never)))
    #expect((readOnly["allowed_tools"] as? [String: Any])?["read_only"] as? Bool == true)
    #expect(readOnly["require_approval"] as? String == "never")
}

@Test func mcpStreamingEventsUseOpenAINames() throws {
    let encoder = ResponseStreamEncoder()
    let listing = try #require(encoder.encodeString(
        ResponseStreamEvent.mcpListTools(.completed, itemId: "mcpl_1", outputIndex: 0), sequenceNumber: 3))
    #expect(listing.hasPrefix("event: response.mcp_list_tools.completed\n"))
    #expect(listing.contains(#""item_id":"mcpl_1""#))
    #expect(listing.contains(#""sequence_number":3"#))

    #expect(ResponseStreamEvent.mcpListTools(.inProgress, itemId: "l", outputIndex: 0).type
        == "response.mcp_list_tools.in_progress")
    #expect(ResponseStreamEvent.mcpListTools(.failed, itemId: "l", outputIndex: 0).type
        == "response.mcp_list_tools.failed")
    #expect(ResponseStreamEvent.mcpCall(.inProgress, itemId: "c", outputIndex: 1).type
        == "response.mcp_call.in_progress")
    #expect(ResponseStreamEvent.mcpCall(.completed, itemId: "c", outputIndex: 1).type
        == "response.mcp_call.completed")
    #expect(ResponseStreamEvent.mcpCall(.failed, itemId: "c", outputIndex: 1).type
        == "response.mcp_call.failed")

    let delta = ResponseStreamEvent.mcpCallArgumentsDelta(itemId: "c", outputIndex: 1, delta: "{}")
    #expect(delta.type == "response.mcp_call_arguments.delta")
    #expect(delta.data["delta"]?.stringValue == "{}")
    let done = ResponseStreamEvent.mcpCallArgumentsDone(itemId: "c", outputIndex: 1, arguments: "{}")
    #expect(done.type == "response.mcp_call_arguments.done")
    #expect(done.data["arguments"]?.stringValue == "{}")
}
