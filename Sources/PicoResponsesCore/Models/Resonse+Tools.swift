//
//  File 2.swift
//  PicoResponses
//
//  Created by Ronald Mannak on 10/4/25.
//

import Foundation

// MARK: - Built-in Tool Configurations

public struct WebSearchConfig: Codable, Sendable, Equatable {
    public var userLocation: UserLocation?
    public var searchContextSize: SearchContextSize?

    public struct UserLocation: Codable, Sendable, Equatable {
        public var type: String
        public var city: String?
        public var region: String?
        public var country: String?
        public var timezone: String?

        public init(
            type: String = "approximate",
            city: String? = nil,
            region: String? = nil,
            country: String? = nil,
            timezone: String? = nil
        ) {
            self.type = type
            self.city = city
            self.region = region
            self.country = country
            self.timezone = timezone
        }
    }

    public enum SearchContextSize: String, Codable, Sendable {
        case low, medium, high
    }

    public init(
        userLocation: UserLocation? = nil,
        searchContextSize: SearchContextSize? = nil
    ) {
        self.userLocation = userLocation
        self.searchContextSize = searchContextSize
    }

    enum CodingKeys: String, CodingKey {
        case userLocation = "user_location"
        case searchContextSize = "search_context_size"
    }
}

public struct FileSearchConfig: Codable, Sendable, Equatable {
    public var vectorStoreIds: [String]?
    public var maxNumResults: Int?
    public var rankingOptions: RankingOptions?

    public struct RankingOptions: Codable, Sendable, Equatable {
        public var ranker: String?
        public var scoreThreshold: Double?

        public init(ranker: String? = nil, scoreThreshold: Double? = nil) {
            self.ranker = ranker
            self.scoreThreshold = scoreThreshold
        }

        enum CodingKeys: String, CodingKey {
            case ranker
            case scoreThreshold = "score_threshold"
        }
    }

    public init(
        vectorStoreIds: [String]? = nil,
        maxNumResults: Int? = nil,
        rankingOptions: RankingOptions? = nil
    ) {
        self.vectorStoreIds = vectorStoreIds
        self.maxNumResults = maxNumResults
        self.rankingOptions = rankingOptions
    }

    enum CodingKeys: String, CodingKey {
        case vectorStoreIds = "vector_store_ids"
        case maxNumResults = "max_num_results"
        case rankingOptions = "ranking_options"
    }
}

public struct ComputerUseConfig: Codable, Sendable, Equatable {
    public var displayWidth: Int
    public var displayHeight: Int
    public var environment: String?

    public init(displayWidth: Int, displayHeight: Int, environment: String? = nil) {
        self.displayWidth = displayWidth
        self.displayHeight = displayHeight
        self.environment = environment
    }

    enum CodingKeys: String, CodingKey {
        case displayWidth = "display_width"
        case displayHeight = "display_height"
        case environment
    }
}

public struct CodeInterpreterConfig: Codable, Sendable, Equatable {
    public var container: ContainerConfig?

    public struct ContainerConfig: Codable, Sendable, Equatable {
        public var type: String?
        public var containerId: String?

        public init(type: String? = nil, containerId: String? = nil) {
            self.type = type
            self.containerId = containerId
        }

        enum CodingKeys: String, CodingKey {
            case type
            case containerId = "container_id"
        }
    }

    public init(container: ContainerConfig? = nil) {
        self.container = container
    }
}

public struct MCPToolConfig: Codable, Sendable, Equatable {
    public var serverLabel: String
    public var serverUrl: String?
    public var allowedTools: [String]?

    public init(serverLabel: String, serverUrl: String? = nil, allowedTools: [String]? = nil) {
        self.serverLabel = serverLabel
        self.serverUrl = serverUrl
        self.allowedTools = allowedTools
    }

    enum CodingKeys: String, CodingKey {
        case serverLabel = "server_label"
        case serverUrl = "server_url"
        case allowedTools = "allowed_tools"
    }
}

// MARK: - ResponseTool Enum

public enum ResponseTool: Codable, Sendable, Equatable {
    case webSearch(WebSearchConfig? = nil)
    case fileSearch(FileSearchConfig? = nil)
    case codeInterpreter(CodeInterpreterConfig? = nil)
    case computerUse(ComputerUseConfig)
    case function(ResponseToolDefinition)
    case mcp(MCPToolConfig)
    case other(type: String, payload: [String: AnyCodable])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dictionary = try container.decode([String: AnyCodable].self)

        guard let type = dictionary["type"]?.stringValue else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Missing 'type' field in tool definition"
            )
        }

        switch type {
        case "web_search":
            if dictionary.count > 1 {
                let data = try JSONSerialization.data(withJSONObject: dictionary.jsonObject())
                let config = try JSONDecoder().decode(WebSearchConfig.self, from: data)
                self = .webSearch(config)
            } else {
                self = .webSearch(nil)
            }

        case "file_search":
            if dictionary.count > 1 {
                let data = try JSONSerialization.data(withJSONObject: dictionary.jsonObject())
                let config = try JSONDecoder().decode(FileSearchConfig.self, from: data)
                self = .fileSearch(config)
            } else {
                self = .fileSearch(nil)
            }

        case "code_interpreter":
            if dictionary.count > 1 {
                let data = try JSONSerialization.data(withJSONObject: dictionary.jsonObject())
                let config = try JSONDecoder().decode(CodeInterpreterConfig.self, from: data)
                self = .codeInterpreter(config)
            } else {
                self = .codeInterpreter(nil)
            }

        case "computer_use":
            let data = try JSONSerialization.data(withJSONObject: dictionary.jsonObject())
            let config = try JSONDecoder().decode(ComputerUseConfig.self, from: data)
            self = .computerUse(config)

        case "function":
            let data = try JSONSerialization.data(withJSONObject: dictionary.jsonObject())
            let definition = try JSONDecoder().decode(ResponseToolDefinition.self, from: data)
            self = .function(definition)

        case "mcp":
            let data = try JSONSerialization.data(withJSONObject: dictionary.jsonObject())
            let config = try JSONDecoder().decode(MCPToolConfig.self, from: data)
            self = .mcp(config)

        default:
            self = .other(type: type, payload: dictionary)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .webSearch(let config):
            var payload: [String: AnyCodable] = ["type": AnyCodable("web_search")]
            if let config {
                if let userLocation = config.userLocation {
                    var locationDict: [String: Any] = ["type": userLocation.type]
                    if let city = userLocation.city { locationDict["city"] = city }
                    if let region = userLocation.region { locationDict["region"] = region }
                    if let country = userLocation.country { locationDict["country"] = country }
                    if let timezone = userLocation.timezone { locationDict["timezone"] = timezone }
                    payload["user_location"] = AnyCodable(locationDict)
                }
                if let size = config.searchContextSize {
                    payload["search_context_size"] = AnyCodable(size.rawValue)
                }
            }
            try container.encode(payload)

        case .fileSearch(let config):
            var payload: [String: AnyCodable] = ["type": AnyCodable("file_search")]
            if let config {
                if let ids = config.vectorStoreIds {
                    payload["vector_store_ids"] = AnyCodable(ids)
                }
                if let max = config.maxNumResults {
                    payload["max_num_results"] = AnyCodable(max)
                }
                if let ranking = config.rankingOptions {
                    var rankingDict: [String: Any] = [:]
                    if let ranker = ranking.ranker { rankingDict["ranker"] = ranker }
                    if let threshold = ranking.scoreThreshold { rankingDict["score_threshold"] = threshold }
                    if !rankingDict.isEmpty {
                        payload["ranking_options"] = AnyCodable(rankingDict)
                    }
                }
            }
            try container.encode(payload)

        case .codeInterpreter(let config):
            var payload: [String: AnyCodable] = ["type": AnyCodable("code_interpreter")]
            if let config, let containerConfig = config.container {
                var containerDict: [String: Any] = [:]
                if let type = containerConfig.type { containerDict["type"] = type }
                if let id = containerConfig.containerId { containerDict["container_id"] = id }
                if !containerDict.isEmpty {
                    payload["container"] = AnyCodable(containerDict)
                }
            }
            try container.encode(payload)

        case .computerUse(let config):
            var payload: [String: AnyCodable] = [
                "type": AnyCodable("computer_use"),
                "display_width": AnyCodable(config.displayWidth),
                "display_height": AnyCodable(config.displayHeight)
            ]
            if let env = config.environment {
                payload["environment"] = AnyCodable(env)
            }
            try container.encode(payload)

        case .function(let definition):
            try container.encode(definition)

        case .mcp(let config):
            var payload: [String: AnyCodable] = [
                "type": AnyCodable("mcp"),
                "server_label": AnyCodable(config.serverLabel)
            ]
            if let url = config.serverUrl {
                payload["server_url"] = AnyCodable(url)
            }
            if let allowed = config.allowedTools {
                payload["allowed_tools"] = AnyCodable(allowed)
            }
            try container.encode(payload)

        case .other(_, let payload):
            try container.encode(payload)
        }
    }
}

// MARK: - ResponseTool Convenience Initializers

public extension ResponseTool {
    static var webSearch: ResponseTool { .webSearch(nil) }
    static var fileSearch: ResponseTool { .fileSearch(nil) }
    static var codeInterpreter: ResponseTool { .codeInterpreter(nil) }

    static func function(
        name: String,
        description: String? = nil,
        parameters: JSONSchema
    ) -> ResponseTool {
        .function(ResponseToolDefinition(
            name: name,
            description: description,
            inputSchema: parameters
        ))
    }
}

// MARK: - Tool Definitions

public struct ResponseToolDefinition: Codable, Sendable, Equatable {
    public struct MCPServer: Codable, Sendable, Equatable {
        public var label: String?
        public var url: URL?
        public var transport: String?
        public var version: String?
        public var auth: [String: AnyCodable]?
        public var options: [String: AnyCodable]?
        public var metadata: [String: AnyCodable]?

        enum CodingKeys: String, CodingKey {
            case label
            case url
            case transport
            case version
            case auth
            case options
            case metadata
        }

        public init(
            label: String? = nil,
            url: URL? = nil,
            transport: String? = nil,
            version: String? = nil,
            auth: [String: AnyCodable]? = nil,
            options: [String: AnyCodable]? = nil,
            metadata: [String: AnyCodable]? = nil
        ) {
            self.label = label
            self.url = url
            self.transport = transport
            self.version = version
            self.auth = auth
            self.options = options
            self.metadata = metadata
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.label = try container.decodeIfPresent(String.self, forKey: .label)
            if let urlString = try container.decodeIfPresent(String.self, forKey: .url) {
                self.url = URL(string: urlString)
            } else {
                self.url = nil
            }
            self.transport = try container.decodeIfPresent(String.self, forKey: .transport)
            self.version = try container.decodeIfPresent(String.self, forKey: .version)
            self.auth = try container.decodeIfPresent([String: AnyCodable].self, forKey: .auth)
            self.options = try container.decodeIfPresent([String: AnyCodable].self, forKey: .options)
            self.metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(label, forKey: .label)
            if let url {
                try container.encode(url.absoluteString, forKey: .url)
            }
            try container.encodeIfPresent(transport, forKey: .transport)
            try container.encodeIfPresent(version, forKey: .version)
            try container.encodeIfPresent(auth, forKey: .auth)
            try container.encodeIfPresent(options, forKey: .options)
            try container.encodeIfPresent(metadata, forKey: .metadata)
        }
    }

    public var type: String
    public var name: String
    public var description: String?
    public var inputSchema: JSONSchema
    public var mcpServer: MCPServer?

    public init(
        type: String = "function",
        name: String,
        description: String? = nil,
        inputSchema: JSONSchema,
        mcpServer: MCPServer? = nil
    ) {
        self.type = type
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
        self.mcpServer = mcpServer
    }

    enum CodingKeys: String, CodingKey {
        case type
        case name
        case description
        case inputSchema = "parameters"
        case server
        case serverLabel = "server_label"
        case serverURL = "server_url"
        case serverTransport = "server_transport"
        case serverVersion = "server_version"
        case serverAuth = "server_auth"
        case serverOptions = "server_options"
        case serverMetadata = "server_metadata"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "function"
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.inputSchema = try container.decode(JSONSchema.self, forKey: .inputSchema)

        if let nested = try container.decodeIfPresent(MCPServer.self, forKey: .server) {
            self.mcpServer = nested
        } else {
            let label = try container.decodeIfPresent(String.self, forKey: .serverLabel)
            let urlString = try container.decodeIfPresent(String.self, forKey: .serverURL)
            let transport = try container.decodeIfPresent(String.self, forKey: .serverTransport)
            let version = try container.decodeIfPresent(String.self, forKey: .serverVersion)
            let auth = try container.decodeIfPresent([String: AnyCodable].self, forKey: .serverAuth)
            let options = try container.decodeIfPresent([String: AnyCodable].self, forKey: .serverOptions)
            let metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .serverMetadata)
            if label != nil || urlString != nil || transport != nil || version != nil || auth != nil || options != nil || metadata != nil {
                let url = urlString.flatMap(URL.init(string:))
                self.mcpServer = MCPServer(
                    label: label,
                    url: url,
                    transport: transport,
                    version: version,
                    auth: auth,
                    options: options,
                    metadata: metadata
                )
            } else {
                self.mcpServer = nil
            }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(inputSchema, forKey: .inputSchema)

        if let mcpServer {
            try container.encode(mcpServer, forKey: .server)
            try container.encodeIfPresent(mcpServer.label, forKey: .serverLabel)
            if let url = mcpServer.url {
                try container.encode(url.absoluteString, forKey: .serverURL)
            }
            try container.encodeIfPresent(mcpServer.transport, forKey: .serverTransport)
            try container.encodeIfPresent(mcpServer.version, forKey: .serverVersion)
            try container.encodeIfPresent(mcpServer.auth, forKey: .serverAuth)
            try container.encodeIfPresent(mcpServer.options, forKey: .serverOptions)
            try container.encodeIfPresent(mcpServer.metadata, forKey: .serverMetadata)
        }
    }
}

public enum ToolChoice: Codable, Sendable, Equatable {
    case none
    case auto
    case required
    case named(String)
    case other(type: String, payload: [String: AnyCodable])

    enum CodingKeys: String, CodingKey {
        case type
        case function
    }

    private struct FunctionPayload: Codable, Sendable, Equatable {
        var name: String
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dictionary = try container.decode([String: AnyCodable].self)
        let type = dictionary["type"]?.stringValue ?? "auto"
        switch type {
        case "none":
            self = .none
        case "auto":
            self = .auto
        case "required":
            self = .required
        case "function", "tool":
            let name = dictionary["function"]?.dictionaryValue? ["name"]?.stringValue
                ?? dictionary["name"]?.stringValue
                ?? ""
            self = .named(name)
        default:
            self = .other(type: type, payload: dictionary)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .none:
            try container.encode(["type": AnyCodable("none")])
        case .auto:
            try container.encode(["type": AnyCodable("auto")])
        case .required:
            try container.encode(["type": AnyCodable("required")])
        case .named(let name):
            let payload: [String: AnyCodable] = [
                "type": AnyCodable("function"),
                "function": AnyCodable(["name": name])
            ]
            try container.encode(payload)
        case .other(_, let payload):
            try container.encode(payload)
        }
    }
}

public struct ResponseToolCall: Codable, Sendable, Equatable, Identifiable {
    public struct Arguments: Codable, Sendable, Equatable {
        public var string: String?
        public var json: [String: AnyCodable]?

        public init(string: String? = nil, json: [String: AnyCodable]? = nil) {
            self.string = string
            self.json = json
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let string = try? container.decode(String.self) {
                self.string = string
                if let data = string.data(using: .utf8),
                   let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    self.json = jsonObject.mapValues { AnyCodable($0) }
                } else {
                    self.json = nil
                }
            } else if let dictionary = try? container.decode([String: AnyCodable].self) {
                self.json = dictionary
                self.string = nil
            } else {
                self.string = nil
                self.json = nil
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            if let string {
                try container.encode(string)
            } else if let json {
                try container.encode(json)
            } else {
                try container.encodeNil()
            }
        }

        public var dictionaryValue: [String: AnyCodable]? {
            if let json {
                return json
            }
            guard
                let string,
                let data = string.data(using: .utf8),
                let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            else {
                return nil
            }
            return jsonObject.mapValues { AnyCodable($0) }
        }
    }

    public var type: String
    public var id: String
    public var name: String
    public var arguments: Arguments
    public var status: String?
    public var startedAt: Date?
    public var completedAt: Date?
    public var metadata: [String: AnyCodable]?
    public var executionContext: [String: AnyCodable]?
    public var fileIds: [String]?
    public var error: ResponseToolInvocationError?

    public init(
        type: String = "tool_call",
        id: String,
        name: String,
        arguments: Arguments,
        status: String? = nil,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        metadata: [String: AnyCodable]? = nil,
        executionContext: [String: AnyCodable]? = nil,
        fileIds: [String]? = nil,
        error: ResponseToolInvocationError? = nil
    ) {
        self.type = type
        self.id = id
        self.name = name
        self.arguments = arguments
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.metadata = metadata
        self.executionContext = executionContext
        self.fileIds = fileIds
        self.error = error
    }

    enum CodingKeys: String, CodingKey {
        case type
        case id
        case name
        case arguments
        case status
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case metadata
        case executionContext = "execution_context"
        case fileIds = "file_ids"
        case error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "tool_call"
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.arguments = try container.decode(Arguments.self, forKey: .arguments)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.startedAt = ResponseToolCall.decodeTimestamp(in: container, forKey: .startedAt)
        self.completedAt = ResponseToolCall.decodeTimestamp(in: container, forKey: .completedAt)
        self.metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        self.executionContext = try container.decodeIfPresent([String: AnyCodable].self, forKey: .executionContext)
        self.fileIds = try container.decodeIfPresent([String].self, forKey: .fileIds)
        self.error = try container.decodeIfPresent(ResponseToolInvocationError.self, forKey: .error)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(arguments, forKey: .arguments)
        try container.encodeIfPresent(status, forKey: .status)
        if let startedAt {
            try container.encode(startedAt.timeIntervalSince1970, forKey: .startedAt)
        }
        if let completedAt {
            try container.encode(completedAt.timeIntervalSince1970, forKey: .completedAt)
        }
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(executionContext, forKey: .executionContext)
        try container.encodeIfPresent(fileIds, forKey: .fileIds)
        try container.encodeIfPresent(error, forKey: .error)
    }

    private static func decodeTimestamp(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) -> Date? {
        if let seconds = try? container.decodeIfPresent(Double.self, forKey: key) {
            return Date(timeIntervalSince1970: seconds)
        }
        if let secondsInt = try? container.decodeIfPresent(Int.self, forKey: key) {
            return Date(timeIntervalSince1970: TimeInterval(secondsInt))
        }
        if let stringValue = try? container.decodeIfPresent(String.self, forKey: key) {
            if let seconds = Double(stringValue) {
                return Date(timeIntervalSince1970: seconds)
            }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: stringValue) {
                return date
            }
            return ISO8601DateFormatter().date(from: stringValue)
        }
        if let date = try? container.decodeIfPresent(Date.self, forKey: key) {
            return date
        }
        return nil
    }
}

public struct ResponseToolOutput: Codable, Sendable, Equatable {
    public enum Payload: Codable, Sendable, Equatable {
        case string(String)
        case integer(Int64)
        case number(Double)
        case boolean(Bool)
        case array([AnyCodable])
        case json([String: AnyCodable])
        case null
        case raw(AnyCodable)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .null
            } else if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let intValue = try? container.decode(Int64.self) {
                self = .integer(intValue)
            } else if let doubleValue = try? container.decode(Double.self) {
                self = .number(doubleValue)
            } else if let boolValue = try? container.decode(Bool.self) {
                self = .boolean(boolValue)
            } else if let jsonArray = try? container.decode([AnyCodable].self) {
                self = .array(jsonArray)
            } else if let jsonObject = try? container.decode([String: AnyCodable].self) {
                self = .json(jsonObject)
            } else {
                let rawValue = try container.decode(AnyCodable.self)
                self = .raw(rawValue)
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .integer(let value):
                try container.encode(value)
            case .number(let value):
                try container.encode(value)
            case .boolean(let value):
                try container.encode(value)
            case .array(let value):
                try container.encode(value)
            case .json(let value):
                try container.encode(value)
            case .null:
                try container.encodeNil()
            case .raw(let value):
                try container.encode(value)
            }
        }

        public var anyCodable: AnyCodable {
            switch self {
            case .string(let value):
                return AnyCodable(value)
            case .integer(let value):
                return AnyCodable(value)
            case .number(let value):
                return AnyCodable(value)
            case .boolean(let value):
                return AnyCodable(value)
            case .array(let value):
                return AnyCodable(value.map { $0.jsonObject })
            case .json(let value):
                return AnyCodable(value.jsonObject())
            case .null:
                return AnyCodable(NSNull())
            case .raw(let value):
                return value
            }
        }

        public var stringValue: String? {
            if case let .string(value) = self { return value }
            return nil
        }

        public var dictionaryValue: [String: AnyCodable]? {
            if case let .json(value) = self { return value }
            return nil
        }
    }

    public var type: String
    public var toolCallId: String
    public var payload: Payload
    public var contentType: String?
    public var metadata: [String: AnyCodable]?
    public var error: ResponseToolInvocationError?

    public init(
        type: String = "tool_output",
        toolCallId: String,
        payload: Payload,
        contentType: String? = nil,
        metadata: [String: AnyCodable]? = nil,
        error: ResponseToolInvocationError? = nil
    ) {
        self.type = type
        self.toolCallId = toolCallId
        self.payload = payload
        self.contentType = contentType
        self.metadata = metadata
        self.error = error
    }

    public var output: AnyCodable {
        payload.anyCodable
    }

    public var stringValue: String? {
        payload.stringValue
    }

    public var jsonValue: [String: AnyCodable]? {
        payload.dictionaryValue
    }

    enum CodingKeys: String, CodingKey {
        case type
        case toolCallId = "tool_call_id"
        case payload = "output"
        case contentType = "content_type"
        case metadata
        case error
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "tool_output"
        self.toolCallId = try container.decode(String.self, forKey: .toolCallId)
        self.payload = try container.decode(Payload.self, forKey: .payload)
        self.contentType = try container.decodeIfPresent(String.self, forKey: .contentType)
        self.metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        self.error = try container.decodeIfPresent(ResponseToolInvocationError.self, forKey: .error)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(toolCallId, forKey: .toolCallId)
        try container.encode(payload, forKey: .payload)
        try container.encodeIfPresent(contentType, forKey: .contentType)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(error, forKey: .error)
    }
}
