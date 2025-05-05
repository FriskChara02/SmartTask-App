//
//  ChatService.swift
//  SmartTask
//
//  Created by Loi Nguyen on 29/4/25.
//

import Foundation

struct ChatService {
    static let baseURL = "http://localhost/SmartTask_API/"

    // 🟢 Lấy tin nhắn kênh thế giới
    static func fetchWorldMessages(userId: Int, completion: @escaping (Bool, [ChatMessage]?, String) -> Void) {
        let url = URL(string: baseURL + "chat.php?type=world&user_id=\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API fetchWorldMessages: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, nil, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Fetch World Messages Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   let message = json["message"] as? String {
                    if success, let messagesData = json["data"] as? [[String: Any]] {
                        let messages = messagesData.compactMap { dict -> ChatMessage? in
                            guard let messageId = dict["message_id"] as? Int,
                                  let userId = dict["user_id"] as? Int,
                                  let name = dict["name"] as? String,
                                  let content = dict["content"] as? String,
                                  let timestampString = dict["timestamp"] as? String else {
                                print("❌ Lỗi parse world message: Missing required fields in \(dict)")
                                return nil
                            }
                            guard let timestamp = ChatMessage.dateFormatter.date(from: timestampString) else {
                                print("❌ Lỗi parse timestamp '\(timestampString)' in world message: \(dict)")
                                return nil
                            }
                            return ChatMessage(
                                id: messageId,
                                messageId: messageId,
                                userId: userId,
                                name: name,
                                avatarURL: dict["avatar_url"] as? String,
                                content: content,
                                timestamp: timestamp,
                                isEdited: {
                                    if let value = dict["is_edited"] {
                                        if let intValue = value as? Int { return intValue == 1 }
                                        if let strValue = value as? String { return strValue == "1" }
                                    }
                                    return false
                                }(),
                                isDeleted: {
                                    if let value = dict["is_deleted"] {
                                        if let intValue = value as? Int { return intValue == 1 }
                                        if let strValue = value as? String { return strValue == "1" }
                                    }
                                    return false
                                }()
                            )
                        }
                        print("✅ Parsed \(messages.count) world messages")
                        completion(true, messages, message)
                    } else {
                        completion(false, nil, message)
                    }
                } else {
                    print("❌ Phản hồi không phải JSON object")
                    completion(false, nil, "Phản hồi không hợp lệ!")
                }
            } catch {
                print("❌ Lỗi parse JSON fetchWorldMessages: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Lấy tin nhắn riêng tư
    static func fetchPrivateMessages(userId: Int, friendId: Int, completion: @escaping (Bool, [ChatMessage]?, String) -> Void) {
        let url = URL(string: baseURL + "chat.php?type=private&user_id=\(userId)&friend_id=\(friendId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API fetchPrivateMessages: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, nil, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Fetch Private Messages Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   let message = json["message"] as? String {
                    if success, let messagesData = json["data"] as? [[String: Any]] {
                        let messages = messagesData.compactMap { dict -> ChatMessage? in
                            guard let messageId = dict["message_id"] as? Int,
                                  let userId = dict["sender_id"] as? Int,
                                  let name = dict["name"] as? String,
                                  let content = dict["content"] as? String,
                                  let timestampString = dict["timestamp"] as? String else {
                                print("❌ Lỗi parse private message: Missing required fields in \(dict)")
                                return nil
                            }
                            guard let timestamp = ChatMessage.dateFormatter.date(from: timestampString) else {
                                print("❌ Lỗi parse timestamp '\(timestampString)' in private message: \(dict)")
                                return nil
                            }
                            return ChatMessage(
                                id: messageId,
                                messageId: messageId,
                                userId: userId,
                                name: name,
                                avatarURL: dict["avatar_url"] as? String,
                                content: content,
                                timestamp: timestamp,
                                isEdited: {
                                    if let value = dict["is_edited"] {
                                        if let intValue = value as? Int { return intValue == 1 }
                                        if let strValue = value as? String { return strValue == "1" }
                                    }
                                    return false
                                }(),
                                isDeleted: {
                                    if let value = dict["is_deleted"] {
                                        if let intValue = value as? Int { return intValue == 1 }
                                        if let strValue = value as? String { return strValue == "1" }
                                    }
                                    return false
                                }()
                            )
                        }
                        print("✅ Parsed \(messages.count) private messages")
                        completion(true, messages, message)
                    } else {
                        completion(false, nil, message)
                    }
                } else {
                    print("❌ Phản hồi không phải JSON object")
                    completion(false, nil, "Phản hồi không hợp lệ!")
                }
            } catch {
                print("❌ Lỗi parse JSON fetchPrivateMessages: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Lấy tin nhắn nhóm
    static func fetchGroupMessages(userId: Int, groupId: Int, completion: @escaping (Bool, [ChatMessage]?, String) -> Void) {
        let url = URL(string: baseURL + "chat.php?type=group&user_id=\(userId)&group_id=\(groupId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API fetchGroupMessages: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, nil, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Fetch Group Messages Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   let message = json["message"] as? String {
                    if success, let messagesData = json["data"] as? [[String: Any]] {
                        let messages = messagesData.compactMap { dict -> ChatMessage? in
                            guard let messageId = dict["message_id"] as? Int,
                                  let userId = dict["user_id"] as? Int,
                                  let name = dict["name"] as? String,
                                  let content = dict["content"] as? String,
                                  let timestampString = dict["timestamp"] as? String else {
                                print("❌ Lỗi parse group message: Missing required fields in \(dict)")
                                return nil
                            }
                            guard let timestamp = ChatMessage.dateFormatter.date(from: timestampString) else {
                                print("❌ Lỗi parse timestamp '\(timestampString)' in group message: \(dict)")
                                return nil
                            }
                            return ChatMessage(
                                id: messageId,
                                messageId: messageId,
                                userId: userId,
                                name: name,
                                avatarURL: dict["avatar_url"] as? String,
                                content: content,
                                timestamp: timestamp,
                                isEdited: {
                                    if let value = dict["is_edited"] {
                                        if let intValue = value as? Int { return intValue == 1 }
                                        if let strValue = value as? String { return strValue == "1" }
                                    }
                                    return false
                                }(),
                                isDeleted: {
                                    if let value = dict["is_deleted"] {
                                        if let intValue = value as? Int { return intValue == 1 }
                                        if let strValue = value as? String { return strValue == "1" }
                                    }
                                    return false
                                }()
                            )
                        }
                        print("✅ Parsed \(messages.count) group messages")
                        completion(true, messages, message)
                    } else {
                        completion(false, nil, message)
                    }
                } else {
                    print("❌ Phản hồi không phải JSON object")
                    completion(false, nil, "Phản hồi không hợp lệ!")
                }
            } catch {
                print("❌ Lỗi parse JSON fetchGroupMessages: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Kiểm tra giới hạn tin nhắn với người lạ
    static func checkMessageLimit(userId: Int, receiverId: Int, completion: @escaping (Bool, Int, String) -> Void) {
        let url = URL(string: baseURL + "chat.php?type=limit&user_id=\(userId)&receiver_id=\(receiverId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API checkMessageLimit: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, 0, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Check Message Limit Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   let message = json["message"] as? String {
                    if success, let data = json["data"] as? [String: Any],
                       let messageCount = data["message_count"] as? Int {
                        print("✅ Message count: \(messageCount)")
                        completion(true, messageCount, message)
                    } else {
                        completion(false, 0, message)
                    }
                } else {
                    print("❌ Phản hồi không phải JSON object")
                    completion(false, 0, "Phản hồi không hợp lệ!")
                }
            } catch {
                print("❌ Lỗi parse JSON checkMessageLimit: \(error.localizedDescription)")
                completion(false, 0, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Gửi tin nhắn
    static func sendMessage(userId: Int, type: String, content: String, receiverId: Int? = nil, groupId: Int? = nil, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "chat.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var parameters: [String: Any] = [
            "user_id": userId,
            "type": type,
            "content": content
        ]
        if let receiverId = receiverId {
            parameters["receiver_id"] = receiverId
        }
        if let groupId = groupId {
            parameters["group_id"] = groupId
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = jsonData
            print("DEBUG: Send Message Request Body = \(String(data: jsonData, encoding: .utf8) ?? "Không có dữ liệu")")
        } catch {
            print("❌ Lỗi tạo JSON sendMessage: \(error.localizedDescription)")
            completion(false, "Lỗi tạo JSON!")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API sendMessage: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Send Message Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   let message = json["message"] as? String {
                    completion(success, message)
                } else {
                    print("❌ Phản hồi không phải JSON object")
                    completion(false, "Phản hồi không hợp lệ!")
                }
            } catch {
                print("❌ Lỗi parse JSON sendMessage: \(error.localizedDescription)")
                completion(false, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Chỉnh sửa hoặc xóa tin nhắn
    static func manageMessage(userId: Int, messageId: Int, type: String, action: String, content: String? = nil, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "chat.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var parameters: [String: Any] = [
            "user_id": userId,
            "message_id": messageId,
            "type": type,
            "action": action
        ]
        if let content = content {
            parameters["content"] = content
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: [])
            request.httpBody = jsonData
            print("DEBUG: Manage Message Request Body = \(String(data: jsonData, encoding: .utf8) ?? "Không có dữ liệu")")
        } catch {
            print("❌ Lỗi tạo JSON manageMessage: \(error.localizedDescription)")
            completion(false, "Lỗi tạo JSON!")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API manageMessage: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Manage Message Response - userId: \(userId), messageId: \(messageId), type: \(type), action: \(action), Response: \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let success = json["success"] as? Bool,
                   let message = json["message"] as? String {
                    completion(success, message)
                } else {
                    print("❌ Phản hồi không phải JSON object")
                    completion(false, "Phản hồi không hợp lệ!")
                }
            } catch {
                print("❌ Lỗi parse JSON manageMessage: \(error.localizedDescription)")
                completion(false, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // Lấy danh sách người dùng bị cấm
    static func fetchBannedUsers(completion: @escaping (Bool, [BannedUser]?, String) -> Void) {
        let url = URL(string: baseURL + "admin.php?action=banned_users")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Lỗi kết nối API fetchBannedUsers: \(error?.localizedDescription ?? "Không rõ")")
                completion(false, nil, "Lỗi kết nối API!")
                return
            }

            print("DEBUG: Fetch Banned Users Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")

            do {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                dateFormatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let response = try decoder.decode(BannedUsersResponse.self, from: data)
                completion(true, response.bannedUsers, "Lấy danh sách người dùng bị cấm thành công!")
            } catch {
                print("❌ Lỗi parse JSON fetchBannedUsers: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // Struct cho response danh sách người dùng bị cấm
    struct BannedUsersResponse: Codable {
        let bannedUsers: [BannedUser]
    }
}
