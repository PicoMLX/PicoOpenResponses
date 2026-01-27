# PicoResponses

Handcrafted Swift clients and SwiftUI utilities for OpenAI-style Responses, Conversations, and Files endpoints. The package is split into two layers:

- `OpenResponses` – Codable/Sendable models, JSONSchema helpers, structured errors, and an EventSource-powered HTTP client.
- `OpenResponsesSwiftUI` – streaming reducers, conversation state snapshots, and an `@Observable` view model for SwiftUI apps.

## Requirements

- Xcode 16 / Swift 6.2+
- iOS 17, macOS 14, tvOS 17, or visionOS 1 minimum (per `Package.swift`)

## Installation

1. In Xcode choose **File ▸ Add Packages… ▸ Add Local…**.
2. Select the root directory of this repository.
3. Add the products you need (typically both `OpenResponses` and `OpenResponsesSwiftUI`).
4. Import the modules where you intend to use them:

```swift
import OpenResponses
import OpenResponsesSwiftUI
```

## Configuring the Core Client

`PicoResponsesConfiguration` accepts an optional API key plus additional headers if your deployment requires them. Local servers that do not use bearer tokens can pass `nil`.

```swift
let configuration = PicoResponsesConfiguration(
    apiKey: Secrets.openAIKey,            // or nil for auth-less servers
    organizationId: nil,
    projectId: nil,
    baseURL: URL(string: "https://api.openai.com/v1")!,
    timeout: 120,
    streamingTimeout: 300                // optional override for SSE
)

let responsesClient = ResponsesClient(configuration: configuration)
```

### Building Conversation Services

`ConversationRequestBuilder` collects the model-level defaults. You can choose how much prior history to send using the `historyStrategy` and optionally supply a `previousResponseId` to let the API resume a prior response chain.

```swift
var builder = ConversationRequestBuilder(
    model: "gpt-4.1-mini",
    temperature: 0.7,
    frequencyPenalty: 0.2,
    presencePenalty: 0.1,
    maxOutputTokens: 512,
    historyStrategy: .latestMessage      // or .fullConversation
)

let liveService = LiveConversationService(
    client: responsesClient,
    requestBuilder: builder
)

let viewModel = ConversationViewModel(service: liveService)
```

## Conversation Flows

### SwiftUI Observation

`ConversationViewModel` adopts Swift 6.2's `@Observable` macro, so SwiftUI views work with bindings via `@Bindable`. The observation system keeps derived state such as `snapshot.lastMessageAt` up to date for features like recency sorting.

```swift
struct ConversationList: View {
    @State private var conversations: [ConversationViewModel] = []

    var body: some View {
        List(sortedConversations) { conversation in
            NavigationLink {
                ConversationView(conversation: conversation)
            } label: {
                Text(conversation.snapshot.topic ?? "New Conversation")
            }
        }
    }

    private var sortedConversations: [ConversationViewModel] {
        conversations.sorted { $0.snapshot.lastMessageAt > $1.snapshot.lastMessageAt }
    }
}
```

### Streaming Conversations

Call `submitPrompt()` from the SwiftUI layer. The view model sends only the most recent user message (per the `historyStrategy`) and includes `previous_response_id` automatically when available.

```swift
struct ChatView: View {
    @Bindable var conversation: ConversationViewModel

    var body: some View {
        VStack {
            List(conversation.snapshot.messages) { message in
                Text("\(message.role.rawValue.capitalized): \(message.text)")
            }

            if conversation.isStreaming {
                ProgressView("Streaming response…")
            }

            HStack {
                TextField("Ask anything", text: $conversation.draft, axis: .vertical)
                Button("Send", action: conversation.submitPrompt)
                    .disabled(conversation.isStreaming || conversation.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding()
    }
}
```

### Non-Streaming (One-Shot) Requests

Invoke `submitOneShotPrompt()` to run the Responses API with `stream = false`. The view model reuses the same builder settings and still appends `previous_response_id` where appropriate.

```swift
Button("Send without streaming") {
    conversation.submitOneShotPrompt()
}
```

## Customising Sampling & History at Runtime

You can mutate the builder’s properties, create a new `LiveConversationService`, and swap the view model when users adjust settings such as model, temperature, penalties, and token limits.

```swift
func apply(settings: ConversationSettings) {
    var builder = ConversationRequestBuilder(
        model: settings.model,
        temperature: settings.temperature,
        topP: settings.topP,
        maxOutputTokens: settings.maxTokens,
        historyStrategy: settings.useFullHistory ? .fullConversation : .latestMessage
    )

    let service = LiveConversationService(client: responsesClient, requestBuilder: builder)
    conversation = ConversationViewModel(service: service)
}
```

### Manually Providing `previous_response_id`

If you maintain the transcript outside of `ConversationViewModel`, you can pass the identifier into `LiveConversationService` manually:

```swift
let stream = await liveService.startConversation(
    with: messages,
    previousResponseId: lastResponseId     // nil to start fresh
)
```

`ConversationStateSnapshot` exposes `lastResponseId` so you can persist it between runs.

## Files API & Multipart Uploads

`FilesClient` provides helpers for multi-part uploads via `sendMultipart` and raw downloads via `sendRawData`. Construct an array of `HTTPClient.MultipartPart` for each upload part, then call `filesClient.upload(...)`.

## Server-Side Usage (Hummingbird / MLX)

OpenResponses can also be used server-side to produce OpenAI-compatible Responses API output. The package provides type-safe factory methods and convenience initializers for building responses.

### Validating Incoming Requests

```swift
func handleRequest(_ input: ResponseCreateRequest) async throws -> Response {
    try input.validate()  // Validates temperature, topP, penalties, token limits
    // ... process request
}
```

### Building Non-Streaming Responses

Use the convenience initializers to construct properly formatted response objects:

```swift
let output = ResponseOutput.message(
    text: completionText,
    role: .assistant,
    status: "completed",
    finishReason: "stop"
)

let response = ResponseObject.completed(
    model: modelName,
    output: [output],
    usage: ResponseUsage(
        inputTokens: promptTokenCount,
        outputTokens: generationTokenCount,
        totalTokens: promptTokenCount + generationTokenCount
    )
)
```

For error responses:

```swift
let response = ResponseObject.failed(
    model: modelName,
    error: ResponseError(code: "server_error", message: "Generation failed")
)
```

### Building Streaming Events

Use the type-safe factory methods on `ResponseStreamEvent` to construct SSE events:

```swift
var sequenceNumber = 0

// Send response.created event
let createdEvent = ResponseStreamEvent.created(
    response: ResponseObject.inProgress(model: modelName),
    sequenceNumber: sequenceNumber
)
sequenceNumber += 1

// Send text deltas during generation
for token in tokenStream {
    let deltaEvent = ResponseStreamEvent.outputTextDelta(
        itemId: messageId,
        outputIndex: 0,
        contentIndex: 0,
        delta: token,
        sequenceNumber: sequenceNumber
    )
    sequenceNumber += 1
    // yield deltaEvent to SSE stream
}

// Send completion event
let completedEvent = ResponseStreamEvent.completed(
    response: finalResponseObject,
    sequenceNumber: sequenceNumber
)

// Send done event
let doneEvent = ResponseStreamEvent.done()
```

### Event Type Safety

All 40+ OpenAI streaming event types are available as enum cases:

```swift
// Use the Kind enum for type-safe event construction
let event = ResponseStreamEvent(kind: .responseOutputTextDelta, data: [...])

// Check event types
switch event.kind {
case .responseOutputTextDelta:
    // Handle text delta
case .responseReasoningTextDelta:
    // Handle reasoning text
case .responseFunctionCallArgumentsDelta:
    // Handle function call
case .responseCompleted, .responseFailed, .responseIncomplete:
    // Terminal states
default:
    break
}
```

### Accessing Event Properties

```swift
let event: ResponseStreamEvent = ...

// Common accessors
event.sequenceNumber   // Int?
event.itemId           // String?
event.outputIndex      // Int?
event.contentIndex     // Int?
event.isTerminal       // Bool - true for completed/failed/done
event.isKnownEventType // Bool - true if type matches a known Kind
```

## Error Handling

- All networking errors are surfaced as `PicoResponsesError` with `LocalizedError` descriptions.
- Structured API errors decode the standard `{ "error": { "message": … } }` envelope, so `error.localizedDescription` returns the server’s message.
- Streaming failures retry once via EventSource and, on HTTP errors, re-fetch the body to decode the API payload.

## Testing & Previews

- `PreviewConversationService` feeds canned snapshots to SwiftUI previews.
- Reducer tests in `OpenResponsesSwiftUITests` demonstrate how to simulate SSE events for unit testing.

## License

PicoResponses is released under the MIT license. See `LICENSE` for details.
