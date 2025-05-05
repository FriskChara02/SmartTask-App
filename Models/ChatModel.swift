//
//  ChatModel.swift
//  SmartTask
//
//  Created by Loi Nguyen on 29/4/25.
//

import Foundation

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: Int
    let messageId: Int
    let userId: Int
    let name: String
    let avatarURL: String?
    let content: String
    let timestamp: Date
    let isEdited: Bool
    let isDeleted: Bool

    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        return formatter
    }()

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case userId = "user_id"
        case name
        case avatarURL = "avatar_url"
        case content
        case timestamp
        case isEdited = "is_edited"
        case isDeleted = "is_deleted"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.messageId = try container.decode(Int.self, forKey: .messageId)
        self.id = messageId
        self.userId = try container.decode(Int.self, forKey: .userId)
        self.name = try container.decode(String.self, forKey: .name)
        self.avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        self.content = try container.decode(String.self, forKey: .content)
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        guard let timestamp = Self.dateFormatter.date(from: timestampString) else {
            throw DecodingError.dataCorruptedError(forKey: .timestamp, in: container, debugDescription: "Invalid timestamp format")
        }
        self.timestamp = timestamp
        self.isEdited = try container.decode(Bool.self, forKey: .isEdited)
        self.isDeleted = try container.decode(Bool.self, forKey: .isDeleted)
    }

    init(id: Int, messageId: Int, userId: Int, name: String, avatarURL: String?, content: String, timestamp: Date, isEdited: Bool, isDeleted: Bool) {
        self.id = id
        self.messageId = messageId
        self.userId = userId
        self.name = name
        self.avatarURL = avatarURL
        self.content = content
        self.timestamp = timestamp
        self.isEdited = isEdited
        self.isDeleted = isDeleted
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(messageId, forKey: .messageId)
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
        try container.encode(content, forKey: .content)
        try container.encode(Self.dateFormatter.string(from: timestamp), forKey: .timestamp)
        try container.encode(isEdited, forKey: .isEdited)
        try container.encode(isDeleted, forKey: .isDeleted)
    }
}

struct ChatLimit: Codable {
    let messageCount: Int

    enum CodingKeys: String, CodingKey {
        case messageCount = "message_count"
    }
}

struct SensitiveWord: Codable, Identifiable {
    let id: Int
    let word: String
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, word
        case createdAt = "created_at"
    }
}

struct BannedUser: Codable {
    let userId: Int
    let bannedBy: Int
    let reason: String?
    let bannedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case bannedBy = "banned_by"
        case reason
        case bannedAt = "banned_at"
    }
}
