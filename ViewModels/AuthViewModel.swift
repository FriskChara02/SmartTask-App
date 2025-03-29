import Foundation

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserModel?
    @Published var isLoggedIn: Bool = true

    // 🟢 Hàm đăng ký
    func register(name: String, email: String, password: String, completion: @escaping (String) -> Void) {
        APIService.registerUser(name: name, email: email, password: password) { success, message in
            DispatchQueue.main.async {
                completion(message)
            }
        }
    }

    // 🟢 Hàm đăng nhập
    func login(email: String, password: String, completion: @escaping (String) -> Void) {
        APIService.loginUser(email: email, password: password) { success, message, user in
            DispatchQueue.main.async {
                // 🟢 Kiểm tra Swift có nhận dữ liệu không
                print("DEBUG: Login Success = \(success), User = \(user != nil ? String(describing: user) : "nil")")
                
                if success, let user = user {
                    self.isAuthenticated = true
                    self.currentUser = user
                    completion("Đăng nhập thành công!")
                    print("✅ Login successful: \(user.email)")
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil // Đảm bảo reset currentUser nếu thất bại
                    completion(message)
                    print("❌ Login failed: \(message)")
                }
            }
        }
    }
    
    func logout() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.objectWillChange.send() // 🔥 Thêm 'self.' để Swift nhận diện

            self.currentUser = nil
            self.isAuthenticated = false
            
            // ✅ Xóa dữ liệu người dùng (nếu cần)
            UserDefaults.standard.removeObject(forKey: "userToken")

            print("Đã đăng xuất!")
        }
    }
    
    // Kiểm tra mật khẩu
    func verifyPassword(_ password: String, completion: @escaping (Bool) -> Void) {
        guard let user = currentUser else {
            completion(false)
            return
        }
        APIService.loginUser(email: user.email, password: password) { success, _, _ in
            DispatchQueue.main.async {
                completion(success) // Dùng login API để kiểm tra hash
                print("DEBUG: Verify Password Result = \(success) for \(password)")
            }
        }
    }
}
