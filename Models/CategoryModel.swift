import Foundation

// Struct Category mới
struct Category: Identifiable, Codable {
    let id: Int
    var name: String
    var isHidden: Bool? // Thêm để hỗ trợ Show/Hide
    var color: String?  // Thêm để lưu màu (dùng String để tương thích với database)
    var icon: String?   // Thêm để lưu tên icon (ví dụ: "pencil")
    
    // Khởi tạo
    init(id: Int, name: String, isHidden: Bool? = false, color: String? = nil, icon: String? = nil) {
        self.id = id
        self.name = name
        self.isHidden = isHidden
        self.color = color
        self.icon = icon
    }
    
    // CodingKeys để ánh xạ tên thuộc tính từ API
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case isHidden
        case color
        case icon
    }
}
