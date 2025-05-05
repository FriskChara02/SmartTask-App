//
//  GroupModel.swift
//  SmartTask
//
//  Created by Loi Nguyen on 29/4/25.
//

import Foundation

struct GroupModel: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let createdBy: Int
    let createdAt: Date
    let color: String?
    let icon: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case createdBy = "created_by"
        case createdAt = "created_at"
        case color, icon
    }
}

struct GroupMember: Codable, Identifiable, Hashable, Equatable {
    let id: Int
    let name: String
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case avatarURL = "avatar_url"
    }

    // Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Equatable
    static func == (lhs: GroupMember, rhs: GroupMember) -> Bool {
        return lhs.id == rhs.id
    }
}

struct GroupProject: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let progress: Float
    let createdAt: Date
    let taskCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name, progress
        case createdAt = "created_at"
        case taskCount = "task_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        progress = try container.decode(Float.self, forKey: .progress)
        taskCount = try container.decode(Int.self, forKey: .taskCount)

        // Parse created_at từ string sang Date
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if let date = formatter.date(from: createdAtString) {
            createdAt = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Date string does not match format 'yyyy-MM-dd HH:mm:ss'")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(progress, forKey: .progress)
        try container.encode(taskCount, forKey: .taskCount)

        // Encode createdAt thành string
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let createdAtString = formatter.string(from: createdAt)
        try container.encode(createdAtString, forKey: .createdAt)
    }
}

struct GroupTask: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let assignedToIds: [Int] // Danh sách ID người được giao
    let assignedToNames: [String] // Danh sách tên người được giao
    let dueDate: Date?
    let isCompleted: Bool
    let priority: String

    enum CodingKeys: String, CodingKey {
        case id, title, description
        case assignedToIds = "assigned_to"
        case assignedToNames = "assigned_to_names"
        case dueDate = "due_date"
        case isCompleted = "is_completed"
        case priority
    }
}
