//
//  FriendModel.swift
//  SmartTask
//
//  Created by Loi Nguyen on 29/4/25.
//

import Foundation

struct Friend: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let avatarURL: String?
    let status: String?
    let dateOfBirth: Date?
    let mutualFriends: Int?
    let createdAt: Date?
    let isFriend: Bool?

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        return formatter
    }()

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case avatarURL = "avatar_url"
        case dateOfBirth = "date_of_birth"
        case mutualFriends = "mutual_friends"
        case createdAt = "created_at"
        case isFriend = "is_friend"
    }

    // ^^ Thêm hàm so sánh cho Equatable
    static func ==(lhs: Friend, rhs: Friend) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.avatarURL == rhs.avatarURL &&
               lhs.status == rhs.status &&
               lhs.dateOfBirth == rhs.dateOfBirth &&
               lhs.mutualFriends == rhs.mutualFriends &&
               lhs.createdAt == rhs.createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        mutualFriends = try container.decodeIfPresent(Int.self, forKey: .mutualFriends)
        if let isFriendInt = try container.decodeIfPresent(Int.self, forKey: .isFriend) {
            isFriend = isFriendInt != 0
        } else {
            isFriend = nil
        }

        if let dateString = try container.decodeIfPresent(String.self, forKey: .dateOfBirth) {
            dateOfBirth = Friend.dateFormatter.date(from: dateString)
        } else {
            dateOfBirth = nil
        }
        if let dateString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = Friend.dateFormatter.date(from: dateString)
        } else {
            createdAt = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(mutualFriends, forKey: .mutualFriends)
        if let isFriend = isFriend {
            try container.encode(isFriend ? 1 : 0, forKey: .isFriend)
        } else {
            try container.encodeIfPresent(nil as Int?, forKey: .isFriend)
        }
        if let dateOfBirth = dateOfBirth {
            try container.encode(Friend.dateFormatter.string(from: dateOfBirth), forKey: .dateOfBirth)
        }
        if let createdAt = createdAt {
            try container.encode(Friend.dateFormatter.string(from: createdAt), forKey: .createdAt)
        }
    }
}

struct FriendRequest: Codable, Identifiable {
    let id: Int
    let senderId: Int
    let name: String
    let avatarURL: String?
    let createdAt: Date

    // ^^ Thêm DateFormatter cho múi giờ UTC
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        return formatter
    }()

    enum CodingKeys: String, CodingKey {
        case id, name
        case senderId = "sender_id"
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
    }

    // ^^ Tùy chỉnh JSONDecoder để parse Date với UTC
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        senderId = try container.decode(Int.self, forKey: .senderId)
        name = try container.decode(String.self, forKey: .name)
        avatarURL = try container.decodeIfPresent(String.self, forKey: .avatarURL)
        let dateString = try container.decode(String.self, forKey: .createdAt)
        guard let date = FriendRequest.dateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Invalid date format")
        }
        createdAt = date
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(senderId, forKey: .senderId)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(avatarURL, forKey: .avatarURL)
        try container.encode(FriendRequest.dateFormatter.string(from: createdAt), forKey: .createdAt)
    }
}
