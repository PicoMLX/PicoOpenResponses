import Foundation

public struct PicoResponsesAPIError: Codable, Sendable, Equatable {
    public let message: String?
    public let type: String?
    public let param: String?
    public let code: String?
    public let raw: [String: AnyCodable]

    public init(
        message: String? = nil,
        type: String? = nil,
        param: String? = nil,
        code: String? = nil,
        raw: [String: AnyCodable] = [:]
    ) {
        self.message = message
        self.type = type
        self.param = param
        self.code = code
        self.raw = raw
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode([String: AnyCodable].self)
        self.message = raw["message"]?.stringValue
        self.type = raw["type"]?.stringValue
        self.param = raw["param"]?.stringValue
        self.code = raw["code"]?.stringValue
        self.raw = raw
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(raw)
    }

    public var errorType: PicoResponsesErrorType? {
        guard let type else { return nil }
        return PicoResponsesErrorType(type)
    }
}

public enum PicoResponsesErrorType: Codable, Sendable, Equatable {
    case serverError
    case invalidRequest
    case notFound
    case modelError
    case tooManyRequests
    case other(String)

    public init(_ value: String) {
        switch value {
        case "server_error":
            self = .serverError
        case "invalid_request":
            self = .invalidRequest
        case "not_found":
            self = .notFound
        case "model_error":
            self = .modelError
        case "too_many_requests":
            self = .tooManyRequests
        default:
            self = .other(value)
        }
    }

    public var rawValue: String {
        switch self {
        case .serverError:
            return "server_error"
        case .invalidRequest:
            return "invalid_request"
        case .notFound:
            return "not_found"
        case .modelError:
            return "model_error"
        case .tooManyRequests:
            return "too_many_requests"
        case .other(let value):
            return value
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = PicoResponsesErrorType(value)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public enum PicoResponsesError: Error, Sendable {
    case invalidURL
    case requestEncodingFailed(underlying: Error)
    case responseDecodingFailed(underlying: Error)
    case httpError(statusCode: Int, data: Data?)
    case apiError(statusCode: Int, error: PicoResponsesAPIError, data: Data?)
    case networkError(underlying: Error)
    case streamDecodingFailed(underlying: Error)
    case validationError(String)
}

extension PicoResponsesError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL could not be constructed."
        case .requestEncodingFailed(let underlying):
            return "Failed to encode the request payload: \(underlying.localizedDescription)"
        case .responseDecodingFailed(let underlying):
            return "Failed to decode the server response: \(underlying.localizedDescription)"
        case .httpError(let statusCode, _):
            return "Request failed with HTTP status code \(statusCode)."
        case .apiError(_, let apiError, _):
            if let message = apiError.message, !message.isEmpty {
                return message
            }
            if let type = apiError.type {
                return "Request failed with API error type \(type)."
            }
            return "The server reported an API error."
        case .networkError(let underlying):
            return "A network error occurred: \(underlying.localizedDescription)"
        case .streamDecodingFailed(let underlying):
            return "Failed to process the streaming response: \(underlying.localizedDescription)"
        case .validationError(let message):
            return "Validation error: \(message)"
        }
    }
}
