//
//  AdminService.swift
//  SmartTask
//
//  Created by Loi Nguyen on 29/4/25.
//

import Foundation

struct AdminService {
    static let baseURL = "http://localhost/SmartTask_API/"

    // Thêm struct để decode JSON
    struct APIResponse: Codable {
        let success: Bool
        let message: String
    }

    // Struct cho thống kê hoạt động
    struct AdminStats: Codable {
        let userCount: Int
        let onlineCount: Int
        let adminCount: Int
        let superAdminCount: Int
        let messageCount: Int
        let worldMessageCount: Int
        let privateMessageCount: Int
        let groupMessageCount: Int
        let groupCount: Int
        let projectCount: Int
        let taskCount: Int

        enum CodingKeys: String, CodingKey {
            case userCount = "user_count"
            case onlineCount = "online_count"
            case adminCount = "admin_count"
            case superAdminCount = "super_admin_count"
            case messageCount = "message_count"
            case worldMessageCount = "world_message_count"
            case privateMessageCount = "private_message_count"
            case groupMessageCount = "group_message_count"
            case groupCount = "group_count"
            case projectCount = "project_count"
            case taskCount = "task_count"
        }
    }

    // 🟢 Lấy danh sách người dùng
    static func fetchUsers(adminId: Int, completion: @escaping (Bool, [UserModel]?, String) -> Void) {
        let url = URL(string: baseURL + "admin.php?action=users&admin_id=\(adminId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API fetchUsers: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, nil, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Fetch Users Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   let message = json["message"] as? String {
                    if success, let usersData = json["data"] as? [[String: Any]] {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

                        let users = usersData.compactMap { dict -> UserModel? in
                            // ^^ [NEW] Xử lý user_id kiểu String và convert sang Int
                            let id: Int
                            if let userId = dict["user_id"] as? Int {
                                id = userId
                            } else if let userIdStr = dict["user_id"] as? String, let convertedId = Int(userIdStr) {
                                id = convertedId
                            } else {
                                print("❌ Lỗi parse user_id: \(dict)")
                                return nil
                            }

                            guard let name = dict["name"] as? String,
                                  let email = dict["email"] as? String else {
                                print("❌ Lỗi parse user: \(dict)")
                                return nil
                            }

                            // ^^ [NEW] Xử lý hobbies như String thay vì [String]
                            let hobbies = dict["hobbies"] as? String

                            return UserModel(
                                id: id,
                                name: name,
                                email: email,
                                password: "",
                                avatarURL: dict["avatar_url"] as? String,
                                description: dict["description"] as? String,
                                dateOfBirth: (dict["date_of_birth"] as? String).flatMap { dateFormatter.date(from: $0) },
                                location: dict["location"] as? String,
                                joinedDate: (dict["joined_date"] as? String).flatMap { dateFormatter.date(from: $0) },
                                gender: dict["gender"] as? String,
                                hobbies: hobbies,
                                bio: dict["bio"] as? String,
                                token: nil,
                                status: dict["status"] as? String,
                                role: dict["role"] as? String
                            )
                        }
                        print("✅ Parsed \(users.count) users")
                        completion(true, users, message)
                    } else {
                        completion(false, nil, message)
                    }
                } else {
                    print("❌ Phản hồi không phải JSON object")
                    completion(false, nil, "Phản hồi không hợp lệ!")
                }
            } catch {
                print("❌ Lỗi parse JSON fetchUsers: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Nâng cấp vai trò người dùng
    static func promoteUser(adminId: Int, userId: Int, newRole: String, completion: @escaping (Bool, String) -> Void) {
        guard ["user", "admin", "super_admin"].contains(newRole) else {
            completion(false, "Vai trò không hợp lệ!")
            return
        }
        
        let url = URL(string: baseURL + "admin.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let parameters: [String: String] = [
            "admin_id": String(adminId),
            "user_id": String(userId),
            "new_role": newRole,
            "action": "promote"
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("DEBUG: Promote User Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")")
        print("DEBUG: Sending promoteUser request for userId: \(userId), newRole: \(newRole), adminId: \(adminId)")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API promoteUser: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Promote User Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu promoteUser: \(error.localizedDescription)")
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Lấy thống kê hoạt động
    static func fetchStats(adminId: Int, completion: @escaping (Bool, AdminStats?, String) -> Void) {
        let url = URL(string: baseURL + "admin.php?action=stats&admin_id=\(adminId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API fetchStats: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, nil, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Fetch Stats Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   let message = json["message"] as? String {
                    if success, let statsData = json["data"] as? [String: Any] {
                        let stats = AdminStats(
                            userCount: (statsData["user_count"] as? String).flatMap { Int($0) } ?? statsData["user_count"] as? Int ?? 0,
                            onlineCount: (statsData["online_count"] as? String).flatMap { Int($0) } ?? statsData["online_count"] as? Int ?? 0,
                            adminCount: (statsData["admin_count"] as? String).flatMap { Int($0) } ?? statsData["admin_count"] as? Int ?? 0,
                            superAdminCount: (statsData["super_admin_count"] as? String).flatMap { Int($0) } ?? statsData["super_admin_count"] as? Int ?? 0,
                            messageCount: (statsData["message_count"] as? String).flatMap { Int($0) } ?? statsData["message_count"] as? Int ?? 0,
                            worldMessageCount: (statsData["world_message_count"] as? String).flatMap { Int($0) } ?? statsData["world_message_count"] as? Int ?? 0,
                            privateMessageCount: (statsData["private_message_count"] as? String).flatMap { Int($0) } ?? statsData["private_message_count"] as? Int ?? 0,
                            groupMessageCount: (statsData["group_message_count"] as? String).flatMap { Int($0) } ?? statsData["group_message_count"] as? Int ?? 0,
                            groupCount: (statsData["group_count"] as? String).flatMap { Int($0) } ?? statsData["group_count"] as? Int ?? 0,
                            projectCount: (statsData["project_count"] as? String).flatMap { Int($0) } ?? statsData["project_count"] as? Int ?? 0,
                            taskCount: (statsData["task_count"] as? String).flatMap { Int($0) } ?? statsData["task_count"] as? Int ?? 0
                        )
                        print("✅ Parsed admin stats: users=\(stats.userCount), messages=\(stats.messageCount)")
                        completion(true, stats, message)
                    } else {
                        completion(false, nil, message)
                    }
                } else {
                    print("❌ Phản hồi không phải JSON object")
                    completion(false, nil, "Phản hồi không hợp lệ!")
                }
            } catch {
                print("❌ Lỗi parse JSON fetchStats: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // 🟢 Thêm từ nhạy cảm
    static func addSensitiveWord(adminId: Int, word: String, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "admin.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let parameters: [String: String] = [
            "admin_id": String(adminId),
            "word": word,
            "action": "add_sensitive_word"
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("DEBUG: Add Sensitive Word Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API addSensitiveWord: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Add Sensitive Word Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu addSensitiveWord: \(error.localizedDescription)")
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Lấy danh sách từ nhạy cảm
    static func fetchSensitiveWords(adminId: Int, completion: @escaping (Bool, [SensitiveWord]?, String) -> Void) {
        let url = URL(string: baseURL + "admin.php?action=sensitive_words&admin_id=\(adminId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API fetchSensitiveWords: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, nil, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Fetch Sensitive Words Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   let message = json["message"] as? String {
                    if success, let wordsData = json["data"] as? [[String: Any]] {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

                        let words = wordsData.compactMap { dict -> SensitiveWord? in
                            let id: Int
                            if let idInt = dict["id"] as? Int {
                                id = idInt
                            } else if let idStr = dict["id"] as? String, let convertedId = Int(idStr) {
                                id = convertedId
                            } else {
                                print("❌ Lỗi parse sensitive word id: \(dict)")
                                return nil
                            }
                            guard let word = dict["word"] as? String else {
                                print("❌ Lỗi parse sensitive word: \(dict)")
                                return nil
                            }
                            let createdAt = (dict["created_at"] as? String).flatMap { dateFormatter.date(from: $0) }
                            return SensitiveWord(id: id, word: word, createdAt: createdAt)
                        }
                        print("✅ Parsed \(words.count) sensitive words")
                        completion(true, words, message)
                    } else {
                        completion(false, nil, message)
                    }
                } else {
                    print("❌ Phản hồi không phải JSON object")
                    completion(false, nil, "Phản hồi không hợp lệ!")
                }
            } catch {
                print("❌ Lỗi parse JSON fetchSensitiveWords: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Cập nhật vai trò người dùng (alias cho promoteUser)
    static func updateUserRole(adminId: Int, userId: Int, newRole: String, completion: @escaping (Bool, String) -> Void) {
        promoteUser(adminId: adminId, userId: userId, newRole: newRole, completion: completion)
    }
}

struct CreateGroupResponse: Codable {
    let success: Bool
    let message: String
    let data: CreateGroupData?

    struct CreateGroupData: Codable {
        let groupId: Int

        enum CodingKeys: String, CodingKey {
            case groupId = "group_id"
        }
    }
}
