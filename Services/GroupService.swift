//
//  GroupService.swift
//  SmartTask
//
//  Created by Loi Nguyen on 29/4/25.
//

import Foundation

struct GroupService {
    static let baseURL = "http://localhost/SmartTask_API/"

    // Thêm struct để decode JSON
    struct APIResponse: Codable {
            let success: Bool
            let message: String
            let groupId: Int? // Optional để tương thích với các action không trả về group_id
            enum CodingKeys: String, CodingKey {
                case success, message
                case groupId = "group_id"
            }
        }

    // 🟢 Lấy danh sách nhóm
    static func fetchGroups(userId: Int, role: String, completion: @escaping (Bool, [GroupModel]?, String) -> Void) {
        let url = URL(string: baseURL + "groups.php?action=list&user_id=\(userId)&role=\(role)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API fetchGroups: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, nil, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Fetch Groups Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   let message = json["message"] as? String {
                    if success, let groupsData = json["data"] as? [[String: Any]] {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

                        let groups = groupsData.compactMap { dict -> GroupModel? in
                            guard let id = dict["id"] as? Int,
                                  let name = dict["name"] as? String,
                                  let createdBy = dict["created_by"] as? Int,
                                  let createdAtString = dict["created_at"] as? String,
                                  let createdAt = dateFormatter.date(from: createdAtString) else {
                                print("❌ Lỗi parse group: \(dict)")
                                return nil
                            }
                            return GroupModel(
                                id: id,
                                name: name,
                                createdBy: createdBy,
                                createdAt: createdAt,
                                color: dict["color"] as? String,
                                icon: dict["icon"] as? String
                            )
                        }
                        print("✅ Parsed \(groups.count) groups")
                        completion(true, groups, message)
                    } else {
                        completion(false, nil, message)
                    }
                } else {
                    print("❌ Phản hồi không phải JSON object")
                    completion(false, nil, "Phản hồi không hợp lệ!")
                }
            } catch {
                print("❌ Lỗi parse JSON fetchGroups: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Lấy danh sách dự án
    static func fetchGroupProjects(groupId: Int, completion: @escaping (Bool, [GroupProject]?, String) -> Void) {
        let url = URL(string: baseURL + "groups.php?action=projects&group_id=\(groupId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API fetchGroupProjects: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, nil, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Fetch Group Projects Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                struct ResponseData: Decodable {
                    let success: Bool
                    let message: String
                    let data: [GroupProject]?
                }

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted({
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    return formatter
                }())

                let result = try decoder.decode(ResponseData.self, from: data)

                if result.success, let projects = result.data {
                    print("✅ Parsed \(projects.count) group projects")
                    completion(true, projects, result.message)
                } else {
                    completion(false, nil, result.message)
                }
            } catch {
                print("❌ Lỗi parse JSON fetchGroupProjects: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // 🟢 Lấy danh sách nhiệm vụ
    static func fetchGroupTasks(projectId: Int, completion: @escaping (Bool, [GroupTask]?, String) -> Void) {
        let url = URL(string: baseURL + "groups.php?action=tasks&project_id=\(projectId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API fetchGroupTasks: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, nil, "Lỗi kết nối API!")
                return
            }

            // Kiểm tra dữ liệu rỗng
            guard !data.isEmpty else {
                print("❌ Dữ liệu trả về rỗng từ API fetchGroupTasks")
                completion(false, nil, "Dữ liệu trả về rỗng!")
                return
            }

            print("DEBUG: Fetch Group Tasks Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted({
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    return formatter
                }())
                // Xóa dòng: decoder.keyDecodingStrategy = .convertFromSnakeCase
                struct ResponseData: Decodable {
                    let success: Bool
                    let message: String
                    let data: [GroupTask]?
                }
                let result = try decoder.decode(ResponseData.self, from: data)

                if result.success {
                    print("✅ Parsed \(result.data?.count ?? 0) group tasks")
                    completion(true, result.data ?? [], result.message)
                } else {
                    print("❌ API trả về success=false: \(result.message)")
                    completion(false, nil, result.message)
                }
            } catch let decodeError as DecodingError {
                // Log chi tiết lỗi decode
                switch decodeError {
                case .typeMismatch(let type, let context):
                    print("❌ Lỗi decode: Type mismatch for \(type), context: \(context.debugDescription), path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .valueNotFound(let type, let context):
                    print("❌ Lỗi decode: Value not found for \(type), context: \(context.debugDescription), path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .keyNotFound(let key, let context):
                    print("❌ Lỗi decode: Key \(key.stringValue) not found, context: \(context.debugDescription), path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                case .dataCorrupted(let context):
                    print("❌ Lỗi decode: Data corrupted, context: \(context.debugDescription), path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                @unknown default:
                    print("❌ Lỗi decode không xác định: \(decodeError.localizedDescription)")
                }
                completion(false, nil, "Lỗi parse JSON: \(decodeError.localizedDescription)")
            } catch {
                print("❌ Lỗi không xác định trong fetchGroupTasks: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Tạo nhóm
    static func createGroup(userId: Int, name: String, color: String, icon: String, completion: @escaping (Bool, String, Int?) -> Void) {
        let url = URL(string: baseURL + "groups.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let parameters: [String: String] = [
            "action": "create",
            "created_by": String(userId),
            "name": name,
            "color": color,
            "icon": icon
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("DEBUG: Create Group Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse {
                print("DEBUG: HTTP Status Code = \(httpResponse.statusCode)")
            }

            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API createGroup: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, "Lỗi kết nối API!", nil)
                return
            }

            let responseString = String(data: data, encoding: .utf8) ?? "Không có dữ liệu"
            print("DEBUG: Create Group Response = \(responseString)")

            if responseString.isEmpty || responseString == "Không có dữ liệu" {
                print("❌ Phản hồi rỗng hoặc không hợp lệ")
                completion(false, "Phản hồi từ server rỗng hoặc không hợp lệ!", nil)
                return
            }

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message, response.groupId)
            } catch {
                print("❌ Lỗi giải mã dữ liệu createGroup: \(error.localizedDescription)")
                print("DEBUG: Raw response = \(responseString)")
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)", nil)
            }
        }.resume()
    }

    // 🟢 Thêm thành viên vào nhóm
    static func addGroupMember(groupId: Int, userId: Int, addedBy: Int, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "groups.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let parameters: [String: String] = [
            "action": "add_member", // ^^ Sửa thành action=add_member
            "group_id": String(groupId),
            "user_id": String(userId)
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("DEBUG: Add Group Member Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ Log chi tiết request

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API addGroupMember: \(error?.localizedDescription ?? "Không rõ")") // ^^ Log để debug
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Add Group Member Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ Log chi tiết response

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu addGroupMember: \(error.localizedDescription)") // ^^ Log để debug
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Tạo dự án
    static func createGroupProject(groupId: Int, name: String, createdBy: Int, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "groups.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let parameters: [String: String] = [
            "action": "create_project", // ^^ Thêm action=create_project
            "group_id": String(groupId),
            "name": name
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("DEBUG: Create Group Project Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ Log chi tiết request

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API createGroupProject: \(error?.localizedDescription ?? "Không rõ")") // ^^ Log để debug
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Create Group Project Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ Log chi tiết response

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu createGroupProject: \(error.localizedDescription)") // ^^ Log để debug
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Tạo nhiệm vụ
    static func createGroupTask(projectId: Int, title: String, description: String?, assignedToIds: [Int], dueDate: Date?, priority: String, createdBy: Int, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "groups.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let parameters: [String: String?] = [
            "action": "add_task",
            "project_id": String(projectId),
            "title": title,
            "description": description,
            "due_date": dueDate.map { dateFormatter.string(from: $0) },
            "priority": priority
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value ?? "")\r\n".data(using: .utf8)!)
        }

        for (index, userId) in assignedToIds.enumerated() {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"assigned_to[\(index)]\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(userId)\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("DEBUG: Create Group Task Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API createGroupTask: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Create Group Task Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu createGroupTask: \(error.localizedDescription)")
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Lấy danh sách thành viên nhóm
    static func fetchGroupMembers(groupId: Int, completion: @escaping (Bool, [GroupMember]?, String) -> Void) {
        let url = URL(string: baseURL + "groups.php?action=members&group_id=\(groupId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API fetchGroupMembers: \(error?.localizedDescription ?? "Không rõ")") // ^^ Log để debug
                completion(false, nil, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Fetch Group Members Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ Log chi tiết response

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   let message = json["message"] as? String {
                    if success, let membersData = json["data"] as? [[String: Any]] {
                        let members = membersData.compactMap { dict -> GroupMember? in
                            guard let id = dict["id"] as? Int,
                                  let name = dict["name"] as? String else {
                                print("❌ Lỗi parse member: \(dict)") // ^^ Log để debug
                                return nil
                            }
                            return GroupMember(
                                id: id,
                                name: name,
                                avatarURL: dict["avatar_url"] as? String
                            )
                        }
                        print("✅ Parsed \(members.count) group members") // ^^ Log xác nhận
                        completion(true, members, message)
                    } else {
                        completion(false, nil, message)
                    }
                } else {
                    print("❌ Phản hồi không phải JSON object") // ^^ Log để debug
                    completion(false, nil, "Phản hồi không hợp lệ!")
                }
            } catch {
                print("❌ Lỗi parse JSON fetchGroupMembers: \(error.localizedDescription)") // ^^ Log để debug
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // 🟢 Lấy thông tin user cá nhân
    static func fetchUserInfo(userId: Int, completion: @escaping (Bool, UserModel?, String) -> Void) {
        let url = URL(string: baseURL + "groups.php?action=get_user&user_id=\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API fetchUserInfo: \(error?.localizedDescription ?? "Không rõ")")
                DispatchQueue.main.async { // 🟢 Chuyển completion sang main thread
                    completion(false, nil, "Lỗi kết nối API!")
                }
                return
            }

            print("DEBUG: Fetch User Info Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   let message = json["message"] as? String {
                    if success, let userData = json["data"] as? [String: Any] {
                        guard let id = userData["id"] as? Int,
                              let name = userData["name"] as? String,
                              let email = userData["email"] as? String else {
                            print("❌ Lỗi parse user info: \(userData)")
                            DispatchQueue.main.async { // 🟢 Chuyển completion sang main thread
                                completion(false, nil, "Lỗi parse dữ liệu user!")
                            }
                            return
                        }
                        let user = UserModel(
                            id: id,
                            name: name,
                            email: email,
                            password: "",
                            avatarURL: userData["avatar_url"] as? String,
                            description: nil,
                            dateOfBirth: nil,
                            location: nil,
                            joinedDate: nil,
                            gender: nil,
                            hobbies: nil,
                            bio: nil,
                            token: nil,
                            status: nil,
                            role: userData["role"] as? String
                        )
                        print("✅ Parsed user info for userId=\(id)")
                        DispatchQueue.main.async { // 🟢 Chuyển completion sang main thread
                            completion(true, user, message)
                        }
                    } else {
                        DispatchQueue.main.async { // 🟢 Chuyển completion sang main thread
                            completion(false, nil, message)
                        }
                    }
                } else {
                    print("❌ Phản hồi không phải JSON object")
                    DispatchQueue.main.async { // 🟢 Chuyển completion sang main thread
                        completion(false, nil, "Phản hồi không hợp lệ!")
                    }
                }
            } catch {
                print("❌ Lỗi parse JSON fetchUserInfo: \(error.localizedDescription)")
                DispatchQueue.main.async { // 🟢 Chuyển completion sang main thread
                    completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    // 🟢 Cập nhật nhóm
        static func updateGroup(groupId: Int, name: String, color: String, icon: String, completion: @escaping (Bool, String) -> Void) {
            let url = URL(string: baseURL + "groups.php")!
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"

            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

            var body = Data()
            let parameters: [String: String] = [
                "action": "update_group",
                "group_id": String(groupId),
                "name": name,
                "color": color,
                "icon": icon
            ]

            for (key, value) in parameters {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
            body.append("--\(boundary)--\r\n".data(using: .utf8)!)

            request.httpBody = body

            print("DEBUG: Update Group Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ Log chi tiết request

            URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    print("❌ Lỗi kết nối API updateGroup: \(error?.localizedDescription ?? "Không rõ")") // ^^ Log để debug
                    completion(false, "Lỗi kết nối API!")
                    return
                }

                print("DEBUG: Update Group Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ Log chi tiết response

                do {
                    let response = try JSONDecoder().decode(APIResponse.self, from: data)
                    completion(response.success, response.message)
                } catch {
                    print("❌ Lỗi giải mã dữ liệu updateGroup: \(error.localizedDescription)") // ^^ Log để debug
                    completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
                }
            }.resume()
        }

    // 🟢 Cập nhật nhiệm vụ
    static func updateGroupTask(taskId: Int, title: String, description: String?, assignedToIds: [Int], dueDate: Date?, isCompleted: Bool, priority: String, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "groups.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let parameters: [String: String?] = [
            "action": "update_task",
            "task_id": String(taskId),
            "title": title,
            "description": description,
            "assigned_to": try? JSONEncoder().encode(assignedToIds).base64EncodedString(),
            "due_date": dueDate.map { dateFormatter.string(from: $0) },
            "is_completed": isCompleted.description, // Gửi true/false thay vì "1"/"0"
            "priority": priority
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value ?? "")\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("DEBUG: Update Group Task Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API updateGroupTask: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Update Group Task Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu updateGroupTask: \(error.localizedDescription)")
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Xóa nhóm
    static func deleteGroup(groupId: Int, userId: Int, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "groups.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let parameters: [String: String] = [
            "action": "delete_group",
            "group_id": String(groupId),
            "user_id": String(userId)
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("DEBUG: Delete Group Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ Log chi tiết request

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API deleteGroup: \(error?.localizedDescription ?? "Không rõ")") // ^^ Log để debug
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Delete Group Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ Log chi tiết response

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu deleteGroup: \(error.localizedDescription)") // ^^ Log để debug
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Xóa thành viên khỏi nhóm
    static func removeGroupMember(groupId: Int, userId: Int, requestingUserId: Int, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "groups.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let parameters: [String: String] = [
            "action": "remove_member",
            "group_id": String(groupId),
            "user_id": String(userId),
            "requesting_user_id": String(requestingUserId)
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("DEBUG: Remove Group Member Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ Log chi tiết request

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API removeGroupMember: \(error?.localizedDescription ?? "Không rõ")") // ^^ Log để debug
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Remove Group Member Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ Log chi tiết response

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu removeGroupMember: \(error.localizedDescription)") // ^^ Log để debug
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Xóa nhiệm vụ
    static func deleteGroupTask(taskId: Int, userId: Int, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "groups.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let parameters: [String: String] = [
            "action": "delete_task",
            "task_id": String(taskId),
            "user_id": String(userId)
        ]

        for (key, value) in parameters {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        print("DEBUG: Delete Group Task Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ Log chi tiết request

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API deleteGroupTask: \(error?.localizedDescription ?? "Không rõ")") // ^^ Log để debug
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Delete Group Task Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")") // ^^ Log chi tiết response

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu deleteGroupTask: \(error.localizedDescription)") // ^^ Log để debug
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // 🟢 Lấy groupId từ projectId
    static func fetchGroupIdForProject(projectId: Int, completion: @escaping (Bool, Int?, String) -> Void) {
        let url = URL(string: baseURL + "groups.php?action=get_group_id&project_id=\(projectId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API fetchGroupIdForProject: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, nil, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Fetch GroupId Response for projectId=\(projectId) = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                print("DEBUG: Parsed groupId=\(response.groupId ?? 0), success=\(response.success), message=\(response.message)")
                completion(response.success, response.groupId, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu fetchGroupIdForProject: \(error.localizedDescription)")
                completion(false, nil, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }
}
