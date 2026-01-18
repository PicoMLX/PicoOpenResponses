//
//  File 2.swift
//  PicoResponses
//
//  Created by Ronald Mannak on 10/4/25.
//

import Foundation

// MARK: - Built-in Tool Configurations

public struct WebSearchConfig: Codable, Sendable, Equatable {
    public let userLocation: UserLocation?
    public let searchContextSize: SearchContextSize?

    public struct UserLocation: Codable, Sendable, Equatable {
        public let type: String
        public let city: String?
        public let region: String?
        public let country: String?
        public let timezone: String?

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

}

public struct FileSearchConfig: Codable, Sendable, Equatable {
    public let vectorStoreIds: [String]?
    public let maxNumResults: Int?
    public let rankingOptions: RankingOptions?

    public struct RankingOptions: Codable, Sendable, Equatable {
        public let ranker: String?
        public let scoreThreshold: Double?

        public init(ranker: String? = nil, scoreThreshold: Double? = nil) {
            self.ranker = ranker
            self.scoreThreshold = scoreThreshold
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

}

public struct ComputerUseConfig: Codable, Sendable, Equatable {
    public let displayWidth: Int
    public let displayHeight: Int
    public let environment: String?

    public init(displayWidth: Int, displayHeight: Int, environment: String? = nil) {
        self.displayWidth = displayWidth
        self.displayHeight = displayHeight
        self.environment = environment
    }

}

public struct CodeInterpreterConfig: Codable, Sendable, Equatable {
    public let container: ContainerConfig?

    public struct ContainerConfig: Codable, Sendable, Equatable {
        public let type: String?
        public let containerId: String?

        public init(type: String? = nil, containerId: String? = nil) {
            self.type = type
            self.containerId = containerId
        }

    }

    public init(container: ContainerConfig? = nil) {
        self.container = container
    }
}

public struct MCPToolConfig: Codable, Sendable, Equatable {
    public let serverLabel: String
    public let serverUrl: String?
    public let allowedTools: [String]?

    public init(serverLabel: String, serverUrl: String? = nil, allowedTools: [String]? = nil) {
        self.serverLabel = serverLabel
        self.serverUrl = serverUrl
        self.allowedTools = allowedTools
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
                let config = try ResponsesJSONCoding.makeDecoder().decode(WebSearchConfig.self, from: data)
                self = .webSearch(config)
            } else {
                self = .webSearch(nil)
            }

        case "file_search":
            if dictionary.count > 1 {
                let data = try JSONSerialization.data(withJSONObject: dictionary.jsonObject())
                let config = try ResponsesJSONCoding.makeDecoder().decode(FileSearchConfig.self, from: data)
                self = .fileSearch(config)
            } else {
                self = .fileSearch(nil)
            }

        case "code_interpreter":
            if dictionary.count > 1 {
                let data = try JSONSerialization.data(withJSONObject: dictionary.jsonObject())
                let config = try ResponsesJSONCoding.makeDecoder().decode(CodeInterpreterConfig.self, from: data)
                self = .codeInterpreter(config)
            } else {
                self = .codeInterpreter(nil)
            }

        case "computer_use":
            let data = try JSONSerialization.data(withJSONObject: dictionary.jsonObject())
            let config = try ResponsesJSONCoding.makeDecoder().decode(ComputerUseConfig.self, from: data)
            self = .computerUse(config)

        case "function":
            let data = try JSONSerialization.data(withJSONObject: dictionary.jsonObject())
            let definition = try ResponsesJSONCoding.makeDecoder().decode(ResponseToolDefinition.self, from: data)
            self = .function(definition)

        case "mcp":
            let data = try JSONSerialization.data(withJSONObject: dictionary.jsonObject())
            let config = try ResponsesJSONCoding.makeDecoder().decode(MCPToolConfig.self, from: data)
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
        public let label: String?
        public let url: URL?
        public let transport: String?
        public let version: String?
        public let auth: [String: AnyCodable]?
        public let options: [String: AnyCodable]?
        public let metadata: [String: AnyCodable]?

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

    public let type: String
    public let name: String
    public let description: String?
    public let inputSchema: JSONSchema
    public let mcpServer: MCPServer?

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

// MARK: - Tool Choice

public enum ToolChoiceValueEnum: String, Codable, Sendable {
    case none
    case auto
    case required
}

/// Request-time tool_choice (ToolChoiceParam)
/// Union of: ToolChoiceValueEnum | SpecificFunctionParam | AllowedToolsParam
public enum ToolChoiceParam: Codable, Sendable, Equatable {
    case none
    case auto
    case required
    case specificFunction(name: String)
    case allowedTools(tools: [SpecificToolChoiceParam], mode: ToolChoiceValueEnum? = nil)
    case other(type: String, payload: [String: AnyCodable])

    private struct FunctionPayload: Codable, Sendable, Equatable {
        let name: String
    }

    private struct SpecificFunctionParam: Codable, Sendable, Equatable {
        let type: String
        let function: FunctionPayload

        init(name: String) {
            self.type = "function"
            self.function = FunctionPayload(name: name)
        }
    }

    private struct AllowedToolsParam: Codable, Sendable, Equatable {
        let type: String
        let tools: [SpecificToolChoiceParam]
        let mode: ToolChoiceValueEnum?

        init(tools: [SpecificToolChoiceParam], mode: ToolChoiceValueEnum?) {
            self.type = "allowed_tools"
            self.tools = tools
            self.mode = mode
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // String enum form: "none" | "auto" | "required"
        if let raw = try? container.decode(String.self), let v = ToolChoiceValueEnum(rawValue: raw) {
            switch v {
            case .none: self = .none
            case .auto: self = .auto
            case .required: self = .required
            }
            return
        }

        // Object form
        let dictionary = try container.decode([String: AnyCodable].self)
        let type = dictionary["type"]?.stringValue ?? "auto"

        switch type {
        case "allowed_tools":
            let data = try JSONSerialization.data(withJSONObject: dictionary.jsonObject())
            let decoded = try ResponsesJSONCoding.makeDecoder().decode(AllowedToolsParam.self, from: data)
            self = .allowedTools(tools: decoded.tools, mode: decoded.mode)

        case "function", "tool":
            // Request uses nested {"function":{"name":"..."}}
            let name = dictionary["function"]?.dictionaryValue?["name"]?.stringValue
                ?? dictionary["name"]?.stringValue
                ?? ""
            self = .specificFunction(name: name)

        default:
            self = .other(type: type, payload: dictionary)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .none:
            try container.encode(ToolChoiceValueEnum.none.rawValue)
        case .auto:
            try container.encode(ToolChoiceValueEnum.auto.rawValue)
        case .required:
            try container.encode(ToolChoiceValueEnum.required.rawValue)
        case .specificFunction(let name):
            try container.encode(SpecificFunctionParam(name: name))
        case .allowedTools(let tools, let mode):
            try container.encode(AllowedToolsParam(tools: tools, mode: mode))
        case .other(_, let payload):
            try container.encode(payload)
        }
    }
}

/// Response-time tool_choice (Response.tool_choice)
/// Union of: ToolChoiceValueEnum | FunctionToolChoice | AllowedToolChoice
public enum ToolChoice: Codable, Sendable, Equatable {
    case none
    case auto
    case required
    case function(name: String)
    case allowedTools(tools: [FunctionToolChoice], mode: ToolChoiceValueEnum)
    case other(type: String, payload: [String: AnyCodable])

    private struct AllowedToolChoice: Codable, Sendable, Equatable {
        let type: String
        let tools: [FunctionToolChoice]
        let mode: ToolChoiceValueEnum

        init(tools: [FunctionToolChoice], mode: ToolChoiceValueEnum) {
            self.type = "allowed_tools"
            self.tools = tools
            self.mode = mode
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // String enum form: "none" | "auto" | "required"
        if let raw = try? container.decode(String.self), let v = ToolChoiceValueEnum(rawValue: raw) {
            switch v {
            case .none: self = .none
            case .auto: self = .auto
            case .required: self = .required
            }
            return
        }

        // Object form
        let dictionary = try container.decode([String: AnyCodable].self)
        let type = dictionary["type"]?.stringValue ?? "auto"

        switch type {
        case "allowed_tools":
            let data = try JSONSerialization.data(withJSONObject: dictionary.jsonObject())
            let decoded = try ResponsesJSONCoding.makeDecoder().decode(AllowedToolChoice.self, from: data)
            self = .allowedTools(tools: decoded.tools, mode: decoded.mode)

        case "function":
            // Response uses flat {"type":"function","name":"..."}
            let name = dictionary["name"]?.stringValue
                ?? dictionary["function"]?.dictionaryValue?["name"]?.stringValue
                ?? ""
            self = .function(name: name)

        default:
            self = .other(type: type, payload: dictionary)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch self {
        case .none:
            try container.encode(ToolChoiceValueEnum.none.rawValue)
        case .auto:
            try container.encode(ToolChoiceValueEnum.auto.rawValue)
        case .required:
            try container.encode(ToolChoiceValueEnum.required.rawValue)
        case .function(let name):
            try container.encode(FunctionToolChoice(name: name))
        case .allowedTools(let tools, let mode):
            try container.encode(AllowedToolChoice(tools: tools, mode: mode))
        case .other(_, let payload):
            try container.encode(payload)
        }
    }
}

/// Response object form for selecting a single function tool.
/// Matches FunctionToolChoice: {"type":"function","name":"..."}
public struct FunctionToolChoice: Codable, Sendable, Equatable {
    public let type: String
    public let name: String

    public init(type: String = "function", name: String) {
        self.type = type
        self.name = name
    }
}

/// Request object form for selecting a specific tool.
/// Currently only supports specific function selection.
public enum SpecificToolChoiceParam: Codable, Sendable, Equatable {
    case function(name: String)
    case other(type: String, payload: [String: AnyCodable])

    private struct FunctionPayload: Codable, Sendable, Equatable {
        let name: String
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dictionary = try container.decode([String: AnyCodable].self)
        let type = dictionary["type"]?.stringValue ?? "function"

        switch type {
        case "function", "tool":
            let name = dictionary["function"]?.dictionaryValue?["name"]?.stringValue
                ?? dictionary["name"]?.stringValue
                ?? ""
            self = .function(name: name)
        default:
            self = .other(type: type, payload: dictionary)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .function(let name):
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
    /// The stable identifier for this call item (uses `call_id`).
    public var id: String { callId }

    /// Optional item id (`id`) populated when returned via API.
    public let itemId: String?

    /// Required call id (`call_id`) generated by the model.
    public let callId: String

    /// Always `function_call`.
    public let type: String

    /// The name of the function to call.
    public let name: String

    /// The function arguments as a JSON string (Open Responses spec).
    public let arguments: Arguments

    /// The status of the function tool call.
    public let status: String?

    public init(
        itemId: String? = nil,
        callId: String,
        type: String = "function_call",
        name: String,
        arguments: Arguments,
        status: String? = nil
    ) {
        self.itemId = itemId
        self.callId = callId
        self.type = type
        self.name = name
        self.arguments = arguments
        self.status = status
    }

    enum CodingKeys: String, CodingKey {
        case itemId = "id"
        case callId = "call_id"
        case type
        case name
        case arguments
        case status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.itemId = try container.decodeIfPresent(String.self, forKey: .itemId)
        self.callId = try container.decode(String.self, forKey: .callId)
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "function_call"
        self.name = try container.decode(String.self, forKey: .name)
        self.arguments = try container.decode(Arguments.self, forKey: .arguments)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(itemId, forKey: .itemId)
        try container.encode(callId, forKey: .callId)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)

        // Spec requires `arguments` to be a JSON string.
        // Encode as a string even if it was provided as an object.
        if let s = arguments.string {
            try container.encode(s, forKey: .arguments)
        } else if let json = arguments.json {
            let obj = json.jsonObject()
            let data = try JSONSerialization.data(withJSONObject: obj)
            let s = String(data: data, encoding: .utf8) ?? "{}"
            try container.encode(s, forKey: .arguments)
        } else {
            try container.encode("{}", forKey: .arguments)
        }

        try container.encodeIfPresent(status, forKey: .status)
    }

    public struct Arguments: Codable, Sendable, Equatable {
        public let string: String?
        public let json: [String: AnyCodable]?

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
                // Be tolerant on decode, but we will re-encode as a JSON string.
                self.json = dictionary
                self.string = nil
            } else {
                self.string = nil
                self.json = nil
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            // Spec wants a string.
            if let string {
                try container.encode(string)
            } else if let json {
                let obj = json.jsonObject()
                let data = try JSONSerialization.data(withJSONObject: obj)
                let s = String(data: data, encoding: .utf8) ?? "{}"
                try container.encode(s)
            } else {
                try container.encode("{}")
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
}

public struct ResponseToolOutput: Codable, Sendable, Equatable {
    /// Optional item id (`id`) populated when returned via API.
    public let itemId: String?

    /// Required call id (`call_id`) that this output corresponds to.
    public let callId: String

    /// Always `function_call_output`.
    public let type: String

    /// Output payload.
    public let payload: Payload

    /// The status of the item.
    public let status: String?

    public init(
        itemId: String? = nil,
        callId: String,
        type: String = "function_call_output",
        payload: Payload,
        status: String? = nil
    ) {
        self.itemId = itemId
        self.callId = callId
        self.type = type
        self.payload = payload
        self.status = status
    }

    public enum Payload: Codable, Sendable, Equatable {
        case string(String)
        case array([AnyCodable])
        case json([String: AnyCodable])
        case integer(Int64)
        case number(Double)
        case boolean(Bool)
        case null
        case raw(AnyCodable)

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .null
            } else if let string = try? container.decode(String.self) {
                self = .string(string)
            } else if let jsonArray = try? container.decode([AnyCodable].self) {
                self = .array(jsonArray)
            } else if let jsonObject = try? container.decode([String: AnyCodable].self) {
                self = .json(jsonObject)
            } else if let intValue = try? container.decode(Int64.self) {
                self = .integer(intValue)
            } else if let doubleValue = try? container.decode(Double.self) {
                self = .number(doubleValue)
            } else if let boolValue = try? container.decode(Bool.self) {
                self = .boolean(boolValue)
            } else {
                self = .raw(try container.decode(AnyCodable.self))
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .array(let value):
                try container.encode(value)
            case .json(let value):
                try container.encode(value)
            case .integer(let value):
                try container.encode(value)
            case .number(let value):
                try container.encode(value)
            case .boolean(let value):
                try container.encode(value)
            case .null:
                try container.encodeNil()
            case .raw(let value):
                try container.encode(value)
            }
        }

        /// Returns a JSON string per Open Responses `function_call_output.output` expectations.
        fileprivate func asJSONString() throws -> String {
            switch self {
            case .string(let s):
                return s
            case .json(let obj):
                let data = try JSONSerialization.data(withJSONObject: obj.jsonObject())
                return String(data: data, encoding: .utf8) ?? "{}"
            case .array(let arr):
                let data = try JSONSerialization.data(withJSONObject: arr.map { $0.jsonObject })
                return String(data: data, encoding: .utf8) ?? "[]"
            case .integer(let i):
                return String(i)
            case .number(let d):
                return String(d)
            case .boolean(let b):
                return b ? "true" : "false"
            case .null:
                return "null"
            case .raw(let v):
                let data = try JSONSerialization.data(withJSONObject: v.jsonObject)
                return String(data: data, encoding: .utf8) ?? "null"
            }
        }

        /// Heuristic: checks if this looks like an array of content parts (input_text/input_image/input_file/input_video).
        fileprivate func isContentPartArray() -> Bool {
            guard case .array(let arr) = self, !arr.isEmpty else { return false }
            let allowed: Set<String> = ["input_text", "input_image", "input_file", "input_video"]
            for el in arr {
                // Try to extract dictionary from el.jsonObject
                if let dict = el.jsonObject as? [String: Any],
                   let t = dict["type"] as? String,
                   allowed.contains(t) {
                    continue
                } else {
                    return false
                }
            }
            return true
        }
    }

    enum CodingKeys: String, CodingKey {
        case itemId = "id"
        case callId = "call_id"
        case type
        case output
        case status
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.itemId = try container.decodeIfPresent(String.self, forKey: .itemId)
        self.callId = try container.decode(String.self, forKey: .callId)
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "function_call_output"

        // `output` can be a string or an array of content parts.
        self.payload = try container.decode(Payload.self, forKey: .output)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(itemId, forKey: .itemId)
        try container.encode(callId, forKey: .callId)
        try container.encode(type, forKey: .type)

        // Spec: `output` may be either a JSON string, or an array of content outputs.
        if payload.isContentPartArray() {
            // Preserve as an array.
            try container.encode(payload, forKey: .output)
        } else {
            // Normalize to a JSON string.
            let s = try payload.asJSONString()
            try container.encode(s, forKey: .output)
        }

        try container.encodeIfPresent(status, forKey: .status)
    }

    // Convenience accessors
    public var output: AnyCodable {
        switch payload {
        case .string(let s):
            return AnyCodable(s)
        case .array(let a):
            return AnyCodable(a.map { $0.jsonObject })
        case .json(let j):
            return AnyCodable(j.jsonObject())
        case .integer(let i):
            return AnyCodable(i)
        case .number(let d):
            return AnyCodable(d)
        case .boolean(let b):
            return AnyCodable(b)
        case .null:
            return AnyCodable(NSNull())
        case .raw(let v):
            return v
        }
    }

    public var stringValue: String? {
        if case let .string(value) = payload { return value }
        return nil
    }

    public var jsonValue: [String: AnyCodable]? {
        if case let .json(value) = payload { return value }
        return nil
    }
}
