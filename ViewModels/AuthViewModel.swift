import Foundation
import Combine

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserModel?
    @Published var allUsers: [UserModel] = []
    var cancellables = Set<AnyCancellable>()
    
    
    init() {
        // ^^ [NEW] Kiểm tra token trong UserDefaults để khôi phục trạng thái
        if let token = UserDefaults.standard.string(forKey: "authToken"),
           let userId = UserDefaults.standard.string(forKey: "userId") {
            self.isAuthenticated = true
            print("✅ Restored authToken: \(token), userId: \(userId)") // ^^ [NEW] Log để debug
            // Tải thông tin user nếu cần
            if let id = Int(userId) {
                fetchUserProfile(userId: id)
            }
        } else {
            print("⚠️ No authToken found in UserDefaults") // ^^ [NEW] Log để debug
        }
    }
    
    // 🟢 Hàm đăng ký
    func register(name: String, email: String, password: String, completion: @escaping (String) -> Void) {
        APIService.registerUser(name: name, email: email, password: password) { success, message in
            DispatchQueue.main.async {
                completion(message)
                print("📋 Register result: \(success ? "Success" : "Failed"), message: \(message)") // ^^ [NEW] Log để debug
            }
        }
    }
    
    // 🟢 Hàm đăng nhập
    func login(email: String, password: String, completion: @escaping (String) -> Void) {
        APIService.loginUser(email: email, password: password) { success, message, user in
            DispatchQueue.main.async {
                print("📥 Login response: success=\(success), message=\(message), user=\(user != nil ? String(describing: user) : "nil")") // ^^ [NEW] Log chi tiết response
                
                if success, let user = user {
                    self.currentUser = UserModel(
                        id: user.id,
                        name: user.name,
                        email: user.email,
                        password: "",
                        avatarURL: user.avatarURL,
                        description: user.description,
                        dateOfBirth: user.dateOfBirth,
                        location: user.location,
                        joinedDate: user.joinedDate,
                        gender: user.gender,
                        hobbies: user.hobbies,
                        bio: user.bio,
                        token: user.token,
                        status: user.status,
                        role: user.role // 🟢 Lưu role từ response
                    )
                    self.isAuthenticated = true
                    if let token = user.token {
                        UserDefaults.standard.set(token, forKey: "authToken")
                        UserDefaults.standard.set(user.id, forKey: "userId")
                        print("✅ Saved authToken: \(token), userId: \(user.id)") // ^^ [NEW] Log xác nhận lưu
                    } else {
                        print("⚠️ No token in user object: \(String(describing: user))") // ^^ [NEW] Log khi thiếu token
                        self.isAuthenticated = false
                        completion("Đăng nhập thất bại: Không tìm thấy token")
                        return
                    }
                    completion("Đăng nhập thành công!")
                    print("✅ Login successful: \(user.email), role=\(user.role ?? "nil")") // 🟢 Thêm log role
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                    UserDefaults.standard.removeObject(forKey: "authToken")
                    UserDefaults.standard.removeObject(forKey: "userId")
                    print("❌ Login failed: \(message)")
                    completion(message)
                }
            }
        }
    }
    
    func logout() {
        DispatchQueue.main.async {
            self.currentUser = nil
            self.isAuthenticated = false
            UserDefaults.standard.removeObject(forKey: "authToken")
            UserDefaults.standard.removeObject(forKey: "userId")
            print("✅ Đã đăng xuất và xóa authToken, userId") // ^^ [NEW] Log chi tiết
        }
    }
    
    // Kiểm tra mật khẩu
    func verifyPassword(_ password: String, completion: @escaping (Bool) -> Void) {
        guard let user = currentUser else {
            completion(false)
            print("⚠️ No current user for password verification") // ^^ [NEW] Log để debug
            return
        }
        APIService.loginUser(email: user.email, password: password) { success, _, _ in
            DispatchQueue.main.async {
                completion(success)
                print("📋 Verify password result: \(success) for email: \(user.email)") // ^^ [NEW] Log để debug
            }
        }
    }
    
    private func fetchUserProfile(userId: Int) {
        // ^^ [NEW] Hàm tải thông tin user nếu cần
        print("🔍 Fetching profile for userId: \(userId)") // ^^ [NEW] Log để debug
        GroupService.fetchUserInfo(userId: userId) { success, user, message in
            DispatchQueue.main.async {
                if success, let user = user {
                    self.currentUser = user
                    print("✅ Fetched user profile: \(user.name), role=\(user.role ?? "nil")") // 🟢 Log role
                } else {
                    print("❌ Failed to fetch user profile: \(message)")
                    // Nếu thất bại, không đặt lại isAuthenticated để tránh đăng xuất nhầm
                }
            }
        }
    }
    
    func fetchAllUsers(adminId: Int) {
            AdminService.fetchUsers(adminId: adminId) { [weak self] success, users, message in
                DispatchQueue.main.async {
                    if success, let users = users {
                        self?.allUsers = users
                        print("✅ Fetched \(users.count) users")
                    } else {
                        print("❌ Failed to fetch users: \(message)")
                    }
                }
            }
        }
}
