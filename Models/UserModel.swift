import Foundation

extension Date {
    func ISO8601Format() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }
}

struct UserModel: Identifiable, Codable, Equatable, Hashable {
    var id: Int
    var name: String
    var email: String
    var password: String
    var avatarURL: String?
    var description: String?
    var dateOfBirth: Date?
    var location: String?
    var joinedDate: Date?
    var gender: String?
    var hobbies: String?
    var bio: String?
    var token: String?
    var status: String? // online, offline, idle, dnd, invisible
    var role: String? // user, admin, super_admin

    // Triển khai Equatable: so sánh dựa trên id và email
    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        return lhs.id == rhs.id && lhs.email == rhs.email
    }

    enum CodingKeys: String, CodingKey {
        case id, name, email, password
        case avatarURL = "avatar_url"
        case description
        case dateOfBirth = "date_of_birth"
        case location
        case joinedDate = "joined_date"
        case gender, hobbies, bio, token, status, role
    }
}
