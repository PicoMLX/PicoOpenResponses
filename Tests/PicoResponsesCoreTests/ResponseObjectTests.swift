import Foundation
import Testing
@testable import PicoResponsesCore

@Test func responseObjectDecodesTimestamps() throws {
    let json = """
    {
        "id": "resp_123",
        "object": "response",
        "created_at": 1,
        "completed_at": 2,
        "model": "gpt-4o-mini",
        "status": "completed",
        "incomplete_details": null,
        "usage": null,
        "instructions": null,
        "reasoning": null,
        "max_output_tokens": null,
        "max_tool_calls": null,
        "previous_response_id": null,
        "safety_identifier": null,
        "prompt_cache_key": null,
        "tools": [],
        "tool_choice": "auto",
        "truncation": "disabled",
        "parallel_tool_calls": false,
        "text": { "format": { "type": "text" }, "verbosity": "medium" },
        "output": [],
        "metadata": {},
        "temperature": 1,
        "top_p": 1,
        "frequency_penalty": 0,
        "presence_penalty": 0,
        "top_logprobs": 0,
        "store": false,
        "background": false,
        "service_tier": "default",
        "error": null
    }
    """

    let data = Data(json.utf8)
    let decoder = ResponsesJSONCoding.makeDecoder()
    let response = try decoder.decode(ResponseObject.self, from: data)

    #expect(response.status == .completed)
    #expect(response.createdAt == Date(timeIntervalSince1970: 1))
    #expect(response.completedAt == Date(timeIntervalSince1970: 2))
}
