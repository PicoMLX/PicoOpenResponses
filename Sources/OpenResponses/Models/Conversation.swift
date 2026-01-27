import Foundation

public struct ConversationObject: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let object: String
    public let createdAt: Date
    public let updatedAt: Date
    public let metadata: [String: String]?

    public init(id: String, object: String = "conversation", createdAt: Date, updatedAt: Date, metadata: [String: String]? = nil) {
        self.id = id
        self.object = object
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.metadata = metadata
    }

}

public struct ConversationList: Codable, Sendable, Equatable {
    public let object: String
    public let data: [ConversationObject]
    public let hasMore: Bool
    public let firstId: String?
    public let lastId: String?

    public init(object: String = "list", data: [ConversationObject], hasMore: Bool, firstId: String? = nil, lastId: String? = nil) {
        self.object = object
        self.data = data
        self.hasMore = hasMore
        self.firstId = firstId
        self.lastId = lastId
    }

}

public struct ConversationItemList: Codable, Sendable, Equatable {
    public let object: String
    public let data: [ResponseOutput]
    public let hasMore: Bool
    public let firstId: String?
    public let lastId: String?

    public init(object: String = "list", data: [ResponseOutput], hasMore: Bool, firstId: String? = nil, lastId: String? = nil) {
        self.object = object
        self.data = data
        self.hasMore = hasMore
        self.firstId = firstId
        self.lastId = lastId
    }

}

public struct ConversationCreateRequest: Codable, Sendable, Equatable {
    public let metadata: [String: String]?
    public let title: String?

    public init(metadata: [String: String]? = nil, title: String? = nil) {
        self.metadata = metadata
        self.title = title
    }
}

public struct ConversationUpdateRequest: Codable, Sendable, Equatable {
    public let metadata: [String: String]?
    public let title: String?
    public init(metadata: [String: String]? = nil, title: String? = nil) {
        self.metadata = metadata
        self.title = title
    }
}

public struct ConversationDeletion: Codable, Sendable, Equatable {
    public let id: String
    public let object: String
    public let deleted: Bool
}
