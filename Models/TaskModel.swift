import Foundation

struct TaskModel: Identifiable, Codable {
    var id: Int?
    var userId: Int?
    var title: String
    var description: String?
    var categoryId: Int
    var dueDate: Date?
    var isCompleted: Bool
    var createdAt: Date?
    var priority: String?
    

    // Khởi tạo
    init(id: Int? = nil, userId: Int? = nil, title: String, description: String? = nil, categoryId: Int, dueDate: Date? = nil, isCompleted: Bool = false, createdAt: Date? = nil, priority: String? = "Medium") {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.categoryId = categoryId
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.priority = priority
    }

    // CodingKeys để ánh xạ tên thuộc tính
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case categoryId = "category_id"
        case dueDate = "due_date"
        case isCompleted = "isCompleted"
        case createdAt = "created_at"
        case priority
    }
}
