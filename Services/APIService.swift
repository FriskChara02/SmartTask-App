import Foundation
import UIKit

struct APIService {
    static let baseURL = "http://localhost/SmartTask_API/"

    // Thêm struct để decode JSON
    struct APIResponse: Codable {
        let success: Bool
        let message: String
    }

    // 🟢 Hàm đăng ký
    static func registerUser(name: String, email: String, password: String, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "register.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["name": name, "email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API registerUser: \(error?.localizedDescription ?? "Không rõ")") // ^^ [NEW] Log để debug
                completion(false, "Lỗi kết nối API!")
                return
            }

            let responseString = String(data: data, encoding: .utf8) ?? "Không decode được"
            print("DEBUG: Register Response = \(responseString)") // ^^ [NEW] Log chi tiết response

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool,
               let message = json["message"] as? String {
                completion(success, message)
            } else {
                completion(false, "Phản hồi không hợp lệ!")
            }
        }.resume()
    }

    // Struct cho response đăng nhập
    struct LoginResponse: Codable {
        let userId: Int
        let name: String
        let email: String
        let description: String?
        let dateOfBirth: String?
        let location: String?
        let joinedDate: String?
        let gender: String?
        let hobbies: String?
        let bio: String?
        let avatarUrl: String?
        let token: String
        let role: String? // 🟢 Thêm role

        enum CodingKeys: String, CodingKey {
            case userId = "userId"
            case name, email, description
            case dateOfBirth = "date_of_birth"
            case location
            case joinedDate = "joined_date"
            case gender, hobbies, bio
            case avatarUrl = "avatar_url"
            case token
            case role // 🟢 Thêm CodingKey cho role
        }
    }

    // 🟢 Hàm đăng nhập
    static func loginUser(email: String, password: String, completion: @escaping (Bool, String, UserModel?) -> Void) {
        let url = URL(string: baseURL + "login.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["email": email, "password": password]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ Lỗi tạo JSON body: \(error.localizedDescription)")
            completion(false, "Lỗi tạo JSON body!", nil)
            return
        }

        print("DEBUG: Login Request Body = \(body)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi kết nối API: \(error.localizedDescription)")
                completion(false, "Lỗi kết nối API: \(error.localizedDescription)", nil)
                return
            }

            guard let data = data else {
                print("❌ Không nhận được dữ liệu từ API")
                completion(false, "Không nhận được dữ liệu từ API!", nil)
                return
            }

            let responseString = String(data: data, encoding: .utf8) ?? "Không decode được"
            print("📥 Login response: \(responseString)")

            do {
                // Kiểm tra response lỗi từ backend
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let errorMessage = json["error"] as? String {
                    print("❌ Backend error: \(errorMessage)")
                    completion(false, errorMessage, nil)
                    return
                }

                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Khớp với joined_date

                let user = UserModel(
                    id: loginResponse.userId,
                    name: loginResponse.name,
                    email: loginResponse.email,
                    password: "", // Không trả mật khẩu
                    avatarURL: loginResponse.avatarUrl,
                    description: loginResponse.description,
                    dateOfBirth: loginResponse.dateOfBirth.flatMap { DateFormatter.yyyyMMdd.date(from: $0) },
                    location: loginResponse.location,
                    joinedDate: loginResponse.joinedDate.flatMap { dateFormatter.date(from: $0) },
                    gender: loginResponse.gender,
                    hobbies: loginResponse.hobbies,
                    bio: loginResponse.bio,
                    token: loginResponse.token,
                    status: nil, // Backend không trả status
                    role: loginResponse.role // 🟢 Gán role từ response
                )

                print("✅ Parsed UserModel: id=\(user.id), email=\(user.email), token=\(user.token ?? "nil"), role=\(user.role ?? "nil")") // 🟢 Thêm log role
                completion(true, "Đăng nhập thành công!", user)
            } catch {
                print("❌ Lỗi parse JSON: \(error.localizedDescription)")
                completion(false, "Lỗi parse JSON: \(error.localizedDescription)", nil)
            }
        }.resume()
    }

    // 🟢 Hàm upload avatar
    static func uploadAvatar(userId: Int, image: UIImage, completion: @escaping (Bool, String, String?) -> Void) {
        guard let url = URL(string: baseURL + "upload_avatar.php") else {
            completion(false, "URL không hợp lệ!", nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        // Thêm user_id
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)

        // Kiểm tra và thêm ảnh
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Lỗi: Không thể chuyển UIImage thành JPEG data")
            completion(false, "Không thể xử lý ảnh!", nil)
            return
        }
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar_\(userId).jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("DEBUG: Image Data Size = \(imageData.count) bytes")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API uploadAvatar: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, "Lỗi kết nối API: \(error?.localizedDescription ?? "Không rõ")", nil)
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let success = json?["success"] as? Bool ?? false
                let message = json?["message"] as? String ?? "Phản hồi không hợp lệ"
                let avatarURL = json?["avatar_url"] as? String
                completion(success, message, avatarURL)
            } catch {
                print("❌ Lỗi parse JSON: \(error.localizedDescription)")
                completion(false, "Lỗi parse JSON: \(error.localizedDescription)", nil)
            }
        }.resume()
    }

    // 🟢 Hàm cập nhật user
        static func updateUser(user: UserModel, completion: @escaping (Bool, String) -> Void) {
            guard let url = URL(string: baseURL + "update_user.php") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()
            let parameters: [String: String?] = [
                "user_id": String(user.id),
                "name": user.name,
                "email": user.email,
                "password": user.password.isEmpty ? nil : user.password,
                "description": user.description,
                "date_of_birth": user.dateOfBirth?.ISO8601Format(),
                "location": user.location,
                "gender": user.gender,
                "hobbies": user.hobbies,
                "bio": user.bio,
                "status": user.status
                // Không gửi "role" để tránh lỗi quyền
            ]

            for (key, value) in parameters {
                if let value = value {
                    body.append("--\(boundary)\r\n".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                    body.append("\(value)\r\n".data(using: .utf8)!)
                }
            }
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = body

            print("DEBUG: Update User Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")")

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("❌ Lỗi kết nối API updateUser: \(error?.localizedDescription ?? "Không rõ")")
                    completion(false, "Lỗi mạng: \(error?.localizedDescription ?? "Không rõ")")
                    return
                }

                print("DEBUG: Update User Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

                do {
                    let response = try JSONDecoder().decode(APIResponse.self, from: data)
                    completion(response.success, response.message)
                } catch {
                    print("❌ Lỗi giải mã dữ liệu updateUser: \(error.localizedDescription)")
                    completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
                }
            }.resume()
        }

        // 🟢 Hàm xóa user
        static func deleteUser(userId: Int, completion: @escaping (Bool, String) -> Void) {
            guard let url = URL(string: baseURL + "delete_user.php") else { return }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()
            let parameters: [String: String] = [
                "user_id": String(userId)
            ]

            for (key, value) in parameters {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = body

            print("DEBUG: Delete User Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")")

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("❌ Lỗi kết nối API deleteUser: \(error?.localizedDescription ?? "Không rõ")")
                    completion(false, "Lỗi mạng: \(error?.localizedDescription ?? "Không rõ")")
                    return
                }

                print("DEBUG: Delete User Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

                do {
                    let response = try JSONDecoder().decode(APIResponse.self, from: data)
                    completion(response.success, response.message)
                } catch {
                    print("❌ Lỗi giải mã dữ liệu deleteUser: \(error.localizedDescription)")
                    completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
                }
            }.resume()
        }

    // 🟢 Hàm lưu feedback
    static func saveFeedback(userId: Int, feedback: String, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "save_feedback.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["user_id": userId, "feedback": feedback]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API saveFeedback: \(error?.localizedDescription ?? "Không rõ")") // ^^ [NEW] Log để debug
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Save Feedback Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ [NEW] Log chi tiết response

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool,
               let message = json["message"] as? String {
                completion(success, message)
            } else {
                completion(false, "Phản hồi không hợp lệ!")
            }
        }.resume()
    }

    // 🟢 Hàm lưu rating
    static func saveRating(userId: Int, rating: Int, comment: String?, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "save_rating.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["user_id": userId, "rating": rating]
        if let comment = comment, !comment.isEmpty {
            body["comment"] = comment
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API saveRating: \(error?.localizedDescription ?? "Không rõ")") // ^^ [NEW] Log để debug
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Save Rating Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ [NEW] Log chi tiết response

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool,
               let message = json["message"] as? String {
                completion(success, message)
            } else {
                completion(false, "Phản hồi không hợp lệ!")
            }
        }.resume()
    }

    // 🟢 Hàm lấy danh sách ratings
        static func fetchRatings(completion: @escaping (Bool, [RatingModel]?, String?) -> Void) {
            let url = URL(string: baseURL + "get_ratings.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("❌ Lỗi kết nối API fetchRatings: \(error?.localizedDescription ?? "Không rõ")")
                    completion(false, nil, "Lỗi kết nối API!")
                    return
                }

                print("DEBUG: Fetch Ratings Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

                do {
                    // Decode response trực tiếp vào struct
                    struct RatingsResponse: Codable {
                        let ratings: [RatingModel]
                    }
                    let decoder = JSONDecoder()
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    decoder.dateDecodingStrategy = .formatted(dateFormatter)
                    
                    let response = try decoder.decode(RatingsResponse.self, from: data)
                    print("✅ Parsed \(response.ratings.count) ratings")
                    completion(true, response.ratings, "Lấy danh sách đánh giá thành công!")
                } catch {
                    print("❌ Lỗi parse JSON fetchRatings: \(error)")
                    completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
                }
            }.resume()
        }

    // 🟢 Hàm cập nhật trạng thái
    static func updateStatus(userId: Int, status: String, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "update_user.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["user_id": userId, "status": status]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API updateStatus: \(error?.localizedDescription ?? "Không rõ")") // ^^ Log để debug
                completion(false, "Lỗi kết nối API!")
                return
            }

            let responseString = String(data: data, encoding: .utf8) ?? "Không decode được"
            print("DEBUG: Update Status Response = \(responseString)") // ^^ Log chi tiết response

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu updateStatus: \(error.localizedDescription)") // ^^ Log để debug
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Hàm gửi yêu cầu kết bạn
    static func sendFriendRequest(from fromUserId: Int, to toUserId: Int, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "friends.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        

        var body = Data()
        let parameters: [String: String] = [
            "sender_id": String(fromUserId),
            "receiver_id": String(toUserId),
            "action": "send_request"
        ]
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API sendFriendRequest: \(error?.localizedDescription ?? "Không rõ")") // ^^ Log để debug
                completion(false, "Lỗi kết nối API!")
                return
            }

            let responseString = String(data: data, encoding: .utf8) ?? "Không decode được"
            print("DEBUG: Send Friend Request Response = \(responseString)") // ^^ Log chi tiết response

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu sendFriendRequest: \(error.localizedDescription)") // ^^ Log để debug
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Hàm chấp nhận yêu cầu kết bạn
    static func acceptFriendRequest(requestId: Int, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "friends.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let parameters: [String: String] = [
            "request_id": String(requestId),
            "action": "accept"
        ]
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API acceptFriendRequest: \(error?.localizedDescription ?? "Không rõ")") // ^^ Log để debug
                completion(false, "Lỗi kết nối API!")
                return
            }

            let responseString = String(data: data, encoding: .utf8) ?? "Không decode được"
            print("DEBUG: Accept Friend Request Response = \(responseString)") // ^^ Log chi tiết response

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu acceptFriendRequest: \(error.localizedDescription)") // ^^ Log để debug
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Hàm từ chối yêu cầu kết bạn
    static func rejectFriendRequest(requestId: Int, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "friends.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let parameters: [String: String] = [
            "request_id": String(requestId),
            "action": "reject"
        ]
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API rejectFriendRequest: \(error?.localizedDescription ?? "Không rõ")") // ^^ Log để debug
                completion(false, "Lỗi kết nối API!")
                return
            }

            let responseString = String(data: data, encoding: .utf8) ?? "Không decode được"
            print("DEBUG: Reject Friend Request Response = \(responseString)") // ^^ Log chi tiết response

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu rejectFriendRequest: \(error.localizedDescription)") // ^^ Log để debug
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Hàm khởi tạo phiên chat riêng
    static func startPrivateChat(from fromUserId: Int, to toUserId: Int, completion: @escaping (Bool, String, String?) -> Void) {
        let url = URL(string: baseURL + "chat.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let parameters: [String: String] = [
            "from_user_id": String(fromUserId),
            "to_user_id": String(toUserId),
            "action": "start_private"
        ]
        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API startPrivateChat: \(error?.localizedDescription ?? "Không rõ")") // ^^ Log để debug
                completion(false, "Lỗi kết nối API!", nil)
                return
            }

            let responseString = String(data: data, encoding: .utf8) ?? "Không decode được"
            print("DEBUG: Start Private Chat Response = \(responseString)") // ^^ Log chi tiết response

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   let message = json["message"] as? String {
                    let chatId = json["chat_id"] as? String
                    completion(success, message, chatId)
                } else {
                    print("❌ Phản hồi không phải JSON object") // ^^ Log để debug
                    completion(false, "Phản hồi không hợp lệ!", nil)
                }
            } catch {
                print("❌ Lỗi giải mã dữ liệu startPrivateChat: \(error.localizedDescription)") // ^^ Log để debug
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)", nil)
            }
        }.resume()
    }

    // Struct cho response danh sách người dùng
    struct UsersResponse: Codable {
        let users: [UserModel]
    }
    
    // Cấm người dùng
    static func banUser(userId: Int, bannedBy: Int, reason: String?, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "admin.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = ["user_id": userId, "banned_by": bannedBy]
        if let reason = reason, !reason.isEmpty {
            body["reason"] = reason
        }
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API banUser: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Ban User Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu banUser: \(error.localizedDescription)")
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }
}

// Extension để tái sử dụng date formatter
    private extension DateFormatter {
        static let yyyyMMdd: DateFormatter = {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()
    }
