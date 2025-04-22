import Foundation

struct UserModel: Identifiable, Codable, Equatable {
    var id: Int
    var name: String
    var email: String
    var password: String // Thêm password
    var avatarURL: String?
    var description: String? // Mô tả
    var dateOfBirth: Date? // Ngày sinh
    var location: String? // Địa điểm
    var joinedDate: Date? // Tham gia vào
    var gender: String? // Giới tính
    var hobbies: String? // Sở thích
    var bio: String? // Giới thiệu
    var token: String?
    
    // Triển khai Equatable: so sánh dựa trên id
    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        return lhs.id == rhs.id && lhs.email == rhs.email
    }
}
