// Open Responses spec references:
// - https://www.openresponses.org/reference
// - https://www.openresponses.org/openapi/openapi.json
//
// Test plan (spec coverage + gotchas):
// 1) Requests: CreateResponseBody fields, snake_case encoding, and validation ranges.
// 2) Input items: message roles, item_reference, reasoning, function_call, function_call_output.
// 3) Content parts: input_text/image/file/video, output_text/refusal, summary_text/reasoning_text.
// 4) Tools: function tool naming/parameters, tool_choice forms, allowed_tools constraints.
// 5) ResponseResource: required fields, null vs missing, usage/incomplete/error objects.
// 6) Output items: message/function_call/function_call_output/reasoning item shapes.
// 7) Streaming: every event type + sequence/index fields, obfuscation/logprobs, [DONE].
// 8) JSON coding: AnyCodable edge cases, dates as epoch seconds, unknown enum fallback.
// 9) Client flows: request/stream headers, stream precondition errors, decoding failures.
//
// OpenAI-specific extensions live in `Tests/PicoResponsesCoreTests/OpenAIExtensionsTests.swift`.
// Tests intentionally include failing cases for known spec gaps so we can track compliance.
