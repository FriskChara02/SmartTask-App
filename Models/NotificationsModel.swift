import Foundation

struct NotificationsModel: Identifiable, Codable, Equatable {
    let id: String // UUID dạng chuỗi để khớp với Database
    let message: String
    let taskId: Int? // Liên kết với task
    var isRead: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case message
        case taskId = "task_id"
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}
