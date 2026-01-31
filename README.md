# OpenResponses

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%20|%20macOS%2014%20|%20tvOS%2017%20|%20visionOS%201-blue.svg)](https://developer.apple.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A Swift SDK for the [Open Responses specification](https://www.openresponses.org/specification). Two modules ship in the package:

- **OpenResponses** – Codable models, streaming events, tools, JSONSchema, and an EventSource HTTP client.
- **OpenResponsesSwiftUI** – Observable view model, conversation state, and streaming reducers for SwiftUI apps.

## Install it

1. Open your project in Xcode.
2. Choose **File → Add Packages… → Add Local…**.
3. Select this repository's root folder.
4. Add `OpenResponses` and `OpenResponsesSwiftUI` to your target.

```swift
import OpenResponses
import OpenResponsesSwiftUI
```

## Try it

Send a simple request and print the response.

```swift
import OpenResponses

let client = OpenResponses(configuration: .init(
    apiKey: "sk-...",
    baseURL: URL(string: "https://api.openai.com/v1")!
))

let response = try await client.responses.create(
    request: ResponseCreateRequest(model: "gpt-4.1-mini", input: "Say hello")
)

// Extract text from the first message output
if let text = response.output.first?.content.first?.text {
    print(text)
}
// Output: Hello! How can I help you today?
```

## Stream a response

Receive tokens as they arrive.

```swift
let request = ResponseCreateRequest(
    model: "gpt-4.1-mini",
    input: "Write a haiku about Swift",
    stream: true
)

for try await event in try client.responses.stream(request: request) {
    if case .responseOutputTextDelta = event.kind {
        print(event.delta?.text ?? "", terminator: "")
    }
}
// Output: Concise and swift code (streamed token by token)
```

## Use tools

Define a function tool and let the model call it.

```swift
let weatherTool = ResponseTool.function(
    name: "get_weather",
    description: "Get the current weather for a location",
    parameters: .object(
        properties: [
            "location": .string(description: "City name"),
            "unit": .enumeration([AnyCodable("celsius"), AnyCodable("fahrenheit")])
        ],
        required: ["location"]
    )
)

let request = ResponseCreateRequest(
    model: "gpt-4.1-mini",
    input: "What's the weather in London?",
    tools: [weatherTool]
)

let response = try await client.responses.create(request: request)

// Check for function calls in the response output
for output in response.output {
    if output.type == .functionCall, let name = output.name, let args = output.arguments {
        print("Function: \(name)")
        // Arguments can be accessed as a string or parsed JSON
        if let jsonArgs = args.json {
            print("Arguments: \(jsonArgs)")
        } else if let stringArgs = args.string {
            print("Arguments: \(stringArgs)")
        }
    }
}
```

Six tool types are supported: `webSearch`, `fileSearch`, `codeInterpreter`, `computerUse`, `function`, and `mcp`.

## Build a chat UI

Use `ConversationViewModel` with SwiftUI. The view model is `@Observable` and works with `@Bindable`.

```swift
import OpenResponsesSwiftUI

struct ChatView: View {
    @Bindable var conversation: ConversationViewModel

    var body: some View {
        VStack {
            List(conversation.snapshot.messages) { message in
                Text("\(message.role.rawValue): \(message.text)")
            }

            if conversation.isStreaming {
                ProgressView("Streaming…")
            }

            HStack {
                TextField("Message", text: $conversation.draft)
                Button("Send", action: conversation.submitPrompt)
                    .disabled(conversation.isStreaming || conversation.draft.isEmpty)
            }
        }
    }
}
```

Set up the view model with a service:

```swift
let configuration = PicoResponsesConfiguration(
    apiKey: Secrets.openAIKey,
    baseURL: URL(string: "https://api.openai.com/v1")!
)
let responsesClient = ResponsesClient(configuration: configuration)

var builder = ConversationRequestBuilder(
    model: "gpt-4.1-mini",
    temperature: 0.7,
    maxOutputTokens: 512
)

let service = LiveConversationService(client: responsesClient, requestBuilder: builder)
let viewModel = ConversationViewModel(service: service)
```

---

## Reference

### Configure the client

`PicoResponsesConfiguration` accepts connection parameters. Local servers without authentication can pass `nil` for the API key.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `apiKey` | `String?` | `nil` | Bearer token for authentication |
| `organizationId` | `String?` | `nil` | OpenAI organisation header |
| `projectId` | `String?` | `nil` | OpenAI project header |
| `baseURL` | `URL` | `https://api.openai.com/v1` | API endpoint |
| `timeout` | `TimeInterval` | `120` | Request timeout in seconds |
| `streamingTimeout` | `TimeInterval?` | `nil` | SSE timeout override |

### Request parameters

`ResponseCreateRequest` accepts all Open Responses specification parameters.

| Parameter | Type | Description |
|-----------|------|-------------|
| `model` | `String?` | Model identifier |
| `input` | `ResponseInput` | Text string or array of input items |
| `instructions` | `String?` | System instructions |
| `temperature` | `Float?` | Sampling temperature (0–2) |
| `topP` | `Float?` | Nucleus sampling (0–1) |
| `maxOutputTokens` | `Int?` | Maximum tokens to generate |
| `frequencyPenalty` | `Float?` | Frequency penalty (-2 to 2) |
| `presencePenalty` | `Float?` | Presence penalty (-2 to 2) |
| `stream` | `Bool?` | Enable streaming |
| `tools` | `[ResponseTool]?` | Available tools |
| `toolChoice` | `ToolChoiceParam?` | Tool selection strategy |
| `previousResponseId` | `String?` | Continue from prior response |
| `reasoning` | `ResponseReasoningParam?` | Reasoning configuration |
| `text` | `TextParam?` | Text format and verbosity |

### Streaming events

52 event types are defined in `ResponseStreamEvent.Kind`.

**Response lifecycle:**
- `response.created`, `response.in_progress`, `response.completed`, `response.failed`, `response.incomplete`, `response.queued`

**Output items:**
- `response.output_item.added`, `response.output_item.done`

**Content parts:**
- `response.content_part.added`, `response.content_part.done`

**Text output:**
- `response.output_text.delta`, `response.output_text.done`, `response.output_text.annotation.added`

**Refusal:**
- `response.refusal.delta`, `response.refusal.done`

**Function calls:**
- `response.function_call_arguments.delta`, `response.function_call_arguments.done`

**Reasoning:**
- `response.reasoning.delta`, `response.reasoning.done`
- `response.reasoning_text.delta`, `response.reasoning_text.done`
- `response.reasoning_summary_part.added`, `response.reasoning_summary_part.done`
- `response.reasoning_summary_text.delta`, `response.reasoning_summary_text.done`

**File search:**
- `response.file_search_call.in_progress`, `response.file_search_call.searching`, `response.file_search_call.completed`

**Web search:**
- `response.web_search_call.in_progress`, `response.web_search_call.searching`, `response.web_search_call.completed`

**Code interpreter:**
- `response.code_interpreter_call.in_progress`, `response.code_interpreter_call.interpreting`, `response.code_interpreter_call.completed`
- `response.code_interpreter_call_code.delta`, `response.code_interpreter_call_code.done`

**Image generation:**
- `response.image_generation_call.in_progress`, `response.image_generation_call.generating`
- `response.image_generation_call.partial_image`, `response.image_generation_call.completed`

**MCP (Model Context Protocol):**
- `response.mcp_call.in_progress`, `response.mcp_call.completed`, `response.mcp_call.failed`
- `response.mcp_call_arguments.delta`, `response.mcp_call_arguments.done`
- `response.mcp_list_tools.in_progress`, `response.mcp_list_tools.completed`, `response.mcp_list_tools.failed`

**Custom tools:**
- `response.custom_tool_call_input.delta`, `response.custom_tool_call_input.done`

**Terminal:**
- `error`, `done`

### Tool types

| Type | Configuration | Description |
|------|--------------|-------------|
| `webSearch` | `WebSearchConfig?` | Web search with location context |
| `fileSearch` | `FileSearchConfig?` | Vector store search |
| `codeInterpreter` | `CodeInterpreterConfig?` | Python code execution |
| `computerUse` | `ComputerUseConfig` | Screen interaction (requires display dimensions) |
| `function` | `ResponseToolDefinition` | Custom function with JSONSchema parameters |
| `mcp` | `MCPToolConfig` | Model Context Protocol server |

### Structured outputs

Use `JSONSchema` to define output structure.

```swift
let schema = JSONSchema.object(
    properties: [
        "name": .string(description: "Person's name"),
        "age": .integer(minimum: 0, maximum: 150),
        "email": .string(format: "email")
    ],
    required: ["name", "age"]
)

// Encode the schema to AnyCodable
let encoder = JSONEncoder()
let schemaData = try encoder.encode(schema)
let schemaAny = try JSONDecoder().decode(AnyCodable.self, from: schemaData)

let request = ResponseCreateRequest(
    model: "gpt-4.1-mini",
    input: "Extract: John Doe, 30, john@example.com",
    text: TextParam(format: .jsonSchema(JsonSchemaResponseFormatParam(
        name: "person",
        schema: schemaAny,
        strict: true
    )))
)
```

Available schema types: `string`, `number`, `integer`, `boolean`, `null`, `array`, `object`, `enumeration`, `oneOf`, `anyOf`, `allOf`.

### Conversations API

```swift
// List conversations
let conversations = try await client.conversations.list()

// Retrieve a conversation
let conversation = try await client.conversations.retrieve(id: "conv_123")
```

### Files API

```swift
// Upload a file
let uploadRequest = FileUploadRequest(
    data: fileData,
    filename: "document.pdf",
    purpose: .assistants
)
let file = try await client.files.upload(uploadRequest)

// List files
let files = try await client.files.list()

// Download file content
let content = try await client.files.retrieveContent(id: "file_123")

// Delete a file
try await client.files.delete(id: "file_123")
```

### Server-side usage

Build Open Responses–compatible servers with Hummingbird or Vapor.

**Validate incoming requests:**

```swift
func handleRequest(_ input: ResponseCreateRequest) async throws -> Response {
    try input.validate()
    // Process request...
}
```

**Build streaming events:**

Use `ResponseStreamEmitter` for automatic sequence numbering, or manage sequences manually:

```swift
// Option 1: Automatic sequencing with emitter
let emitter = ResponseStreamEmitter()
await emitter.emit(ResponseStreamEvent.created(response: initialResponse))
for token in tokenStream {
    await emitter.emit(ResponseStreamEvent.outputTextDelta(
        itemId: messageId, outputIndex: 0, contentIndex: 0, delta: token
    ))
}
await emitter.emit(ResponseStreamEvent.completed(response: finalResponse))
emitter.finish()

// Option 2: Manual sequencing
var seq = 0
let createdEvent = ResponseStreamEvent.created(response: initialResponse, sequenceNumber: seq)
seq += 1
// ...continue with seq += 1 for each event
```

### Handle errors

All errors surface as `PicoResponsesError` with `LocalizedError` conformance.

| Error | Description |
|-------|-------------|
| `invalidURL` | Request URL could not be constructed |
| `requestEncodingFailed` | Failed to encode request payload |
| `responseDecodingFailed` | Failed to decode server response |
| `httpError(statusCode:data:)` | Non-2xx HTTP status |
| `apiError(statusCode:error:data:)` | Structured API error response |
| `networkError` | Network connectivity issue |
| `streamDecodingFailed` | Failed to parse SSE event |
| `validationError` | Request validation failed |

```swift
do {
    let response = try await client.responses.create(request: request)
} catch let error as PicoResponsesError {
    switch error {
    case .apiError(_, let apiError, _):
        print("API error: \(apiError.message ?? "Unknown")")
    case .validationError(let message):
        print("Validation: \(message)")
    default:
        print(error.localizedDescription)
    }
}
```

---

## Troubleshooting

**Request fails with "stream must be true"**

Set `stream: true` when calling `client.responses.stream()`.

**Validation error for temperature**

Temperature must be between 0 and 2. Check your value.

**Connection timeout**

Increase `timeout` or `streamingTimeout` in the configuration. Long-running generations may need higher values.

**"Failed to decode server response"**

The response doesn't match expected types. Check your model and endpoint compatibility with the Open Responses specification.

---

## License

OpenResponses is released under the MIT license. See [LICENSE](LICENSE) for details.
