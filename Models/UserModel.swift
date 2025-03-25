import Foundation

struct UserModel: Identifiable, Codable {
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
}
