//
//  EventModel.swift
//  SmartTask
//
//  Created by Loi Nguyen on 14/3/25.
//

import Foundation

struct EventModel: Identifiable, Codable, Equatable { // ^^ Thêm Equatable
    let id: Int
    let userId: Int
    let title: String
    let description: String?
    let startDate: Date
    let endDate: Date?
    let priority: String
    let isAllDay: Bool
    let createdAt: Date
    let updatedAt: Date
    let googleEventId: String?
    let attendeeEmail: String?
    let colorName: String?
    
    init(id: Int, userId: Int, title: String, description: String? = nil, startDate: Date, endDate: Date? = nil, priority: String, isAllDay: Bool, createdAt: Date, updatedAt: Date, googleEventId: String? = nil, attendeeEmail: String? = nil, colorName: String? = nil) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.priority = priority
        self.isAllDay = isAllDay
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.googleEventId = googleEventId
        self.attendeeEmail = attendeeEmail
        self.colorName = colorName
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "userId"
        case title
        case description
        case startDate = "startDate"
        case endDate = "endDate"
        case priority
        case isAllDay = "isAllDay"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
        case googleEventId = "googleEventId"
        case attendeeEmail = "attendeeEmail"
        case colorName = "colorName"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        priority = try container.decode(String.self, forKey: .priority)
        let isAllDayValue = try container.decode(Int.self, forKey: .isAllDay)
        isAllDay = isAllDayValue != 0
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        googleEventId = try container.decodeIfPresent(String.self, forKey: .googleEventId)
        attendeeEmail = try container.decodeIfPresent(String.self, forKey: .attendeeEmail)
        colorName = try container.decodeIfPresent(String.self, forKey: .colorName)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encode(priority, forKey: .priority)
        try container.encode(isAllDay ? 1 : 0, forKey: .isAllDay)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(googleEventId, forKey: .googleEventId)
        try container.encodeIfPresent(attendeeEmail, forKey: .attendeeEmail)
        try container.encodeIfPresent(colorName, forKey: .colorName)
    }
    
    // ^^ Triển khai Equatable để so sánh sự kiện
    static func == (lhs: EventModel, rhs: EventModel) -> Bool {
        lhs.id == rhs.id && lhs.googleEventId == rhs.googleEventId
    }
}
