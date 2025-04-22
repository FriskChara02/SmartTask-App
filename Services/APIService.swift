import Foundation
import UIKit

struct APIService {
    static let baseURL = "http://localhost/SmartTask_API/" // Đổi thành đường dẫn của bạn
    
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
                completion(false, "Lỗi kết nối API!")
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let status = json["status"] as? String ?? "error"
                let message = json["message"] as? String ?? "Có lỗi xảy ra!"
                completion(status == "success", message)
            } else {
                completion(false, "Phản hồi không hợp lệ!")
            }
        }.resume()
    }
    
    // 🟢 Hàm đăng nhập
    static func loginUser(email: String, password: String, completion: @escaping (Bool, String, UserModel?) -> Void) {
        let url = URL(string: baseURL + "login.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["email": email, "password": password]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi kết nối API: \(error.localizedDescription)") // ^^ [NEW] Log để debug
                completion(false, "Lỗi kết nối API: \(error.localizedDescription)", nil)
                return
            }
            
            guard let data = data else {
                print("❌ Không nhận được dữ liệu từ API") // ^^ [NEW] Log để debug
                completion(false, "Không nhận được dữ liệu từ API!", nil)
                return
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "Không decode được"
            print("📥 Login response: \(responseString)") // ^^ [NEW] Log chi tiết response
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    let success = (response as? HTTPURLResponse)?.statusCode == 200
                    let message = json["error"] as? String ?? "Đăng nhập thành công! ✅"
                    
                    if success {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        
                        let user = UserModel(
                            id: json["userId"] as? Int ?? 0,
                            name: json["name"] as? String ?? "",
                            email: json["email"] as? String ?? "",
                            password: password,
                            avatarURL: json["avatar_url"] as? String,
                            description: json["description"] as? String,
                            dateOfBirth: (json["date_of_birth"] as? String).map { dateFormatter.date(from: $0) } ?? nil,
                            location: json["location"] as? String,
                            joinedDate: (json["joined_date"] as? String).map { dateFormatter.date(from: $0) } ?? nil,
                            gender: json["gender"] as? String,
                            hobbies: json["hobbies"] as? String,
                            bio: json["bio"] as? String,
                            token: json["token"] as? String // ^^ [FIX] Thêm token
                        )
                        print("✅ Parsed UserModel: id=\(user.id), email=\(user.email), token=\(user.token ?? "nil")") // ^^ [NEW] Log xác nhận
                        completion(true, message, user)
                    } else {
                        print("❌ Đăng nhập thất bại: \(message)") // ^^ [NEW] Log để debug
                        completion(false, message, nil)
                    }
                } else {
                    print("❌ Phản hồi không phải JSON object") // ^^ [NEW] Log để debug
                    completion(false, "Phản hồi không hợp lệ: Không phải JSON object!", nil)
                }
            } catch {
                print("❌ Lỗi parse JSON: \(error.localizedDescription)") // ^^ [NEW] Log để debug
                completion(false, "Lỗi parse JSON: \(error.localizedDescription)", nil)
            }
        }.resume()
    }
    
    static func uploadAvatar(userId: Int, image: UIImage, completion: @escaping (Bool, String, String?) -> Void) {
        guard let url = URL(string: baseURL + "upload_avatar.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        
        if let imageData = image.jpegData(compressionQuality: 0.8) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(imageData)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(false, "Lỗi upload!", nil)
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let success = json["success"] as? Bool,
               let message = json["message"] as? String {
                let avatarURL = json["avatar_url"] as? String
                completion(success, message, avatarURL)
            } else {
                completion(false, "Phản hồi không hợp lệ!", nil)
            }
        }.resume()
    }
    
    // Thêm struct để decode JSON
    struct APIResponse: Codable {
        let success: Bool
        let message: String
    }
    
    // Sửa hàm updateUser
    static func updateUser(user: UserModel, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "http://localhost/SmartTask_API/update_user.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let parameters: [String: String?] = [
            "user_id": String(user.id),
            "name": user.name,
            "email": user.email,
            "password": user.password,
            "description": user.description,
            "date_of_birth": user.dateOfBirth?.ISO8601Format(),
            "location": user.location,
            "gender": user.gender,
            "hobbies": user.hobbies,
            "bio": user.bio
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
        
        // Debug dữ liệu gửi đi
        print("DEBUG: Update User Request Body = \(String(data: body, encoding: .utf8) ?? "Không có dữ liệu")")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(false, "Lỗi mạng: \(error?.localizedDescription ?? "Không rõ")")
                return
            }
            print("DEBUG: Update User Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // Sửa hàm deleteUser
    static func deleteUser(userId: Int, completion: @escaping (Bool, String) -> Void) {
        guard let url = URL(string: "http://localhost/SmartTask_API/delete_user.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let bodyString = "user_id=\(userId)"
        let body = bodyString.data(using: .utf8)!
        request.httpBody = body
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Debug dữ liệu gửi đi
        print("DEBUG: Delete User Request Body = \(bodyString)")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(false, "Lỗi mạng: \(error?.localizedDescription ?? "Không rõ")")
                return
            }
            print("DEBUG: Delete User Response = \(String(data: data, encoding: .utf8) ?? "Không có dữ liệu")")
            do {
                let response = try JSONDecoder().decode(APIResponse.self, from: data)
                completion(response.success, response.message)
            } catch {
                completion(false, "Lỗi giải mã dữ liệu: \(error.localizedDescription)")
            }
        }.resume()
    }
}
