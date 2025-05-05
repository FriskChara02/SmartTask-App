import Foundation

struct FriendService {
    static let baseURL = "http://localhost/SmartTask_API/"

    struct APIResponse: Codable {
        let success: Bool
        let message: String
        let data: [Friend]?
    }

    struct FriendRequestResponse: Codable {
        let success: Bool
        let message: String
        let data: [FriendRequest]?
    }

    struct FriendResponse: Codable {
        let success: Bool
        let message: String
        let data: Friend?
    }

    // 🟢 Tạo DateFormatter cho múi giờ Asia/Ho_Chi_Minh
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        return formatter
    }()

    // 🟢 Lấy danh sách bạn bè
    static func fetchFriends(userId: Int, completion: @escaping (Bool, [Friend]?, String) -> Void) {
        let url = URL(string: baseURL + "friends.php?action=list&user_id=\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi kết nối API fetchFriends: \(error.localizedDescription)")
                completion(false, nil, "Lỗi kết nối API: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Không nhận được HTTP response từ API fetchFriends")
                completion(false, nil, "Không nhận được HTTP response!")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Lỗi server fetchFriends: HTTP \(httpResponse.statusCode)")
                completion(false, nil, "Lỗi server: HTTP \(httpResponse.statusCode)")
                return
            }

            guard let data = data, !data.isEmpty else {
                print("❌ Dữ liệu rỗng từ API fetchFriends")
                completion(false, nil, "Dữ liệu rỗng từ API!")
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let response = try decoder.decode(APIResponse.self, from: data)
                print("✅ Parsed \(response.data?.count ?? 0) friends")
                completion(response.success, response.data ?? [], response.message)
            } catch {
                print("❌ Lỗi parse JSON fetchFriends: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Lấy danh sách yêu cầu kết bạn
    static func fetchFriendRequests(userId: Int, completion: @escaping (Bool, [FriendRequest]?, String) -> Void) {
        let url = URL(string: baseURL + "friends.php?action=requests&user_id=\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi kết nối API fetchFriendRequests: \(error.localizedDescription)")
                completion(false, nil, "Lỗi kết nối API: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Không nhận được HTTP response từ API fetchFriendRequests")
                completion(false, nil, "Không nhận được HTTP response!")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Lỗi server fetchFriendRequests: HTTP \(httpResponse.statusCode)")
                completion(false, nil, "Lỗi server: HTTP \(httpResponse.statusCode)")
                return
            }

            guard let data = data, !data.isEmpty else {
                print("❌ Dữ liệu rỗng từ API fetchFriendRequests")
                completion(false, nil, "Dữ liệu rỗng từ API!")
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let response = try decoder.decode(FriendRequestResponse.self, from: data)
                print("✅ Parsed \(response.data?.count ?? 0) friend requests")
                completion(response.success, response.data ?? [], response.message)
            } catch {
                print("❌ Lỗi parse JSON fetchFriendRequests: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Tìm kiếm người dùng
    static func searchUsers(userId: Int, query: String, completion: @escaping (Bool, [Friend]?, String) -> Void) {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let url = URL(string: baseURL + "friends.php?action=search&user_id=\(userId)&query=\(encodedQuery)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi kết nối API searchUsers: \(error.localizedDescription)")
                completion(false, nil, "Lỗi kết nối API: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Không nhận được HTTP response từ API searchUsers")
                completion(false, nil, "Không nhận được HTTP response!")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Lỗi server searchUsers: HTTP \(httpResponse.statusCode)")
                completion(false, nil, "Lỗi server: HTTP \(httpResponse.statusCode)")
                return
            }

            guard let data = data, !data.isEmpty else {
                print("❌ Dữ liệu rỗng từ API searchUsers")
                completion(false, nil, "Dữ liệu rỗng từ API!")
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let response = try decoder.decode(APIResponse.self, from: data)
                print("✅ Parsed \(response.data?.count ?? 0) users")
                completion(response.success, response.data ?? [], response.message)
            } catch {
                print("❌ Lỗi parse JSON searchUsers: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Gợi ý bạn bè
    static func fetchFriendSuggestions(userId: Int, completion: @escaping (Bool, [Friend]?, String) -> Void) {
        let url = URL(string: baseURL + "friends.php?action=suggestions&user_id=\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi kết nối API fetchFriendSuggestions: \(error.localizedDescription)")
                completion(false, nil, "Lỗi kết nối API: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Không nhận được HTTP response từ API fetchFriendSuggestions")
                completion(false, nil, "Không nhận được HTTP response!")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Lỗi server fetchFriendSuggestions: HTTP \(httpResponse.statusCode)")
                completion(false, nil, "Lỗi server: HTTP \(httpResponse.statusCode)")
                return
            }

            guard let data = data, !data.isEmpty else {
                print("❌ Dữ liệu rỗng từ API fetchFriendSuggestions")
                completion(false, nil, "Dữ liệu rỗng từ API!")
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let response = try decoder.decode(APIResponse.self, from: data)
                print("✅ Parsed \(response.data?.count ?? 0) friend suggestions")
                completion(response.success, response.data ?? [], response.message)
            } catch {
                print("❌ Lỗi parse JSON fetchFriendSuggestions: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Lấy danh sách bạn bè có sinh nhật
    static func fetchBirthdayFriends(userId: Int, completion: @escaping (Bool, [Friend]?, String) -> Void) {
        let url = URL(string: baseURL + "friends.php?action=birthdays&user_id=\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi kết nối API fetchBirthdayFriends: \(error.localizedDescription)")
                completion(false, nil, "Lỗi kết nối API: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Không nhận được HTTP response từ API fetchBirthdayFriends")
                completion(false, nil, "Không nhận được HTTP response!")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Lỗi server fetchBirthdayFriends: HTTP \(httpResponse.statusCode)")
                completion(false, nil, "Lỗi server: HTTP \(httpResponse.statusCode)")
                return
            }

            guard let data = data, !data.isEmpty else {
                print("❌ Dữ liệu rỗng từ API fetchBirthdayFriends")
                completion(false, nil, "Dữ liệu rỗng từ API!")
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let response = try decoder.decode(APIResponse.self, from: data)
                print("✅ Parsed \(response.data?.count ?? 0) birthday friends")
                completion(response.success, response.data ?? [], response.message)
            } catch {
                print("❌ Lỗi parse JSON fetchBirthdayFriends: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Hủy kết bạn hoặc chặn người dùng
    static func removeFriendOrBlock(userId: Int, friendId: Int, action: String, reason: String? = nil, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "friends.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var jsonBody: [String: Any] = [
            "user_id": userId,
            "friend_id": friendId,
            "action": action
        ]
        if let reason = reason {
            jsonBody["reason"] = reason
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            print("❌ Lỗi tạo JSON body: \(error.localizedDescription)")
            completion(false, "Lỗi tạo JSON body")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi kết nối API removeFriendOrBlock: \(error.localizedDescription)")
                completion(false, "Lỗi kết nối API: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Không nhận được HTTP response từ API removeFriendOrBlock")
                completion(false, "Không nhận được HTTP response!")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Lỗi server removeFriendOrBlock: HTTP \(httpResponse.statusCode)")
                completion(false, "Lỗi server: HTTP \(httpResponse.statusCode)")
                return
            }

            guard let data = data, !data.isEmpty else {
                print("❌ Dữ liệu rỗng từ API removeFriendOrBlock")
                completion(false, "Dữ liệu rỗng từ API!")
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let response = try decoder.decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu removeFriendOrBlock: \(error.localizedDescription)")
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Cập nhật trạng thái cá nhân
    static func updateUserStatus(userId: Int, status: String, completion: @escaping (Bool, String) -> Void) {
        let validStatuses = ["online", "offline", "idle", "dnd", "invisible"]
        guard validStatuses.contains(status) else {
            print("❌ Trạng thái không hợp lệ: \(status)")
            completion(false, "Trạng thái không hợp lệ")
            return
        }

        let url = URL(string: baseURL + "friends.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonBody: [String: Any] = [
            "user_id": userId,
            "status": status
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            print("❌ Lỗi tạo JSON body: \(error.localizedDescription)")
            completion(false, "Lỗi tạo JSON body")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi kết nối API updateUserStatus: \(error.localizedDescription)")
                completion(false, "Lỗi kết nối API: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Không nhận được HTTP response từ API updateUserStatus")
                completion(false, "Không nhận được HTTP response!")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Lỗi server updateUserStatus: HTTP \(httpResponse.statusCode)")
                completion(false, "Lỗi server: HTTP \(httpResponse.statusCode)")
                return
            }

            guard let data = data, !data.isEmpty else {
                print("❌ Dữ liệu rỗng từ API updateUserStatus")
                completion(false, "Dữ liệu rỗng từ API!")
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let response = try decoder.decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu updateUserStatus: \(error.localizedDescription)")
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Gửi yêu cầu kết bạn
    static func sendFriendRequest(senderId: Int, receiverId: Int, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "friends.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonBody: [String: Any] = [
            "action": "send_request",
            "sender_id": senderId,
            "receiver_id": receiverId
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            print("❌ Lỗi tạo JSON body: \(error.localizedDescription)")
            completion(false, "Lỗi tạo JSON body")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi kết nối API sendFriendRequest: \(error.localizedDescription)")
                completion(false, "Lỗi kết nối API: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Không nhận được HTTP response từ API sendFriendRequest")
                completion(false, "Không nhận được HTTP response!")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Lỗi server sendFriendRequest: HTTP \(httpResponse.statusCode)")
                completion(false, "Lỗi server: HTTP \(httpResponse.statusCode)")
                return
            }

            guard let data = data, !data.isEmpty else {
                print("❌ Dữ liệu rỗng từ API sendFriendRequest")
                completion(false, "Dữ liệu rỗng từ API!")
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let response = try decoder.decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu sendFriendRequest: \(error.localizedDescription)")
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Phản hồi yêu cầu kết bạn
    static func respondToFriendRequest(requestId: Int, action: String, completion: @escaping (Bool, Friend?, String) -> Void) {
        let url = URL(string: baseURL + "friends.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonBody: [String: Any] = [
            "action": "respond_request",
            "request_id": requestId,
            "response": action
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            print("❌ Lỗi tạo JSON body: \(error.localizedDescription)")
            completion(false, nil, "Lỗi tạo JSON body")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi kết nối API respondToFriendRequest: \(error.localizedDescription)")
                completion(false, nil, "Lỗi kết nối API: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Không nhận được HTTP response từ API respondToFriendRequest")
                completion(false, nil, "Không nhận được HTTP response!")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Lỗi server respondToFriendRequest: HTTP \(httpResponse.statusCode)")
                completion(false, nil, "Lỗi server: HTTP \(httpResponse.statusCode)")
                return
            }

            guard let data = data, !data.isEmpty else {
                print("❌ Dữ liệu rỗng từ API respondToFriendRequest")
                completion(false, nil, "Dữ liệu rỗng từ API!")
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let response = try decoder.decode(FriendResponse.self, from: data)
                completion(response.success, response.data, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu respondToFriendRequest: \(error.localizedDescription)")
                completion(false, nil, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Lấy danh sách người bị chặn
    static func fetchBlockedUsers(userId: Int, completion: @escaping (Bool, [Friend]?, String) -> Void) {
        let url = URL(string: baseURL + "friends.php?action=blocked_users&user_id=\(userId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi kết nối API fetchBlockedUsers: \(error.localizedDescription)")
                completion(false, nil, "Lỗi kết nối API: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Không nhận được HTTP response từ API fetchBlockedUsers")
                completion(false, nil, "Không nhận được HTTP response!")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Lỗi server fetchBlockedUsers: HTTP \(httpResponse.statusCode)")
                completion(false, nil, "Lỗi server: HTTP \(httpResponse.statusCode)")
                return
            }

            guard let data = data, !data.isEmpty else {
                print("❌ Dữ liệu rỗng từ API fetchBlockedUsers")
                completion(false, nil, "Dữ liệu rỗng từ API!")
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let response = try decoder.decode(APIResponse.self, from: data)
                print("✅ Parsed \(response.data?.count ?? 0) blocked users")
                completion(response.success, response.data ?? [], response.message)
            } catch {
                print("❌ Lỗi parse JSON fetchBlockedUsers: \(error.localizedDescription)")
                completion(false, nil, "Lỗi parse JSON: \(error.localizedDescription)")
            }
        }.resume()
    }

    // 🟢 Bỏ chặn người dùng
    static func unblockUser(userId: Int, blockedUserId: Int, completion: @escaping (Bool, String) -> Void) {
        let url = URL(string: baseURL + "friends.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let jsonBody: [String: Any] = [
            "user_id": userId,
            "friend_id": blockedUserId,
            "action": "unblock"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
        } catch {
            print("❌ Lỗi tạo JSON body: \(error.localizedDescription)")
            completion(false, "Lỗi tạo JSON body")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi kết nối API unblockUser: \(error.localizedDescription)")
                completion(false, "Lỗi kết nối API: \(error.localizedDescription)")
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Không nhận được HTTP response từ API unblockUser")
                completion(false, "Không nhận được HTTP response!")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ Lỗi server unblockUser: HTTP \(httpResponse.statusCode)")
                completion(false, "Lỗi server: HTTP \(httpResponse.statusCode)")
                return
            }

            guard let data = data, !data.isEmpty else {
                print("❌ Dữ liệu rỗng từ API unblockUser")
                completion(false, "Dữ liệu rỗng từ API!")
                return
            }

            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                let response = try decoder.decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                print("❌ Lỗi giải mã dữ liệu unblockUser: \(error.localizedDescription)")
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }
}
