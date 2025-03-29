import SwiftUI
import PhotosUI

class UserViewModel: ObservableObject {
    @Published var currentUser: UserModel? // Lấy từ AuthViewModel hoặc API
    @Published var isEditing = false
    @Published var isLoggingOut = false
    @Published var isDeletingAccount = false
    @Published var selectedPhoto: PhotosPickerItem? = nil
    @Published var avatarImage: UIImage? = nil
    @Published var showPasswordAlert: Bool = false
    @Published var alertMessage: String = ""

    // Các trường chỉnh sửa
    @Published var editedName = ""
    @Published var editedEmail = ""
    @Published var editedPassword = ""
    @Published var currentPassword = ""
    @Published var showPassword = false
    @Published var editedDescription = ""
    @Published var editedDateOfBirth = Date()
    @Published var editedLocation = ""
    @Published var editedGender = ""
    @Published var editedHobbies = ""
    @Published var editedBio = ""

    private var authVM: AuthViewModel?

    // Khởi tạo với AuthViewModel
    init(authVM: AuthViewModel? = nil) {
        self.authVM = authVM
        self.currentUser = authVM?.currentUser
        if let user = currentUser {
            loadUserDataForEditing(user: user)
        }
        // Lắng nghe thay đổi từ authVM (nếu cần)
        if let auth = authVM {
            NotificationCenter.default.addObserver(forName: .didUpdateUser, object: auth, queue: .main) { [weak self] _ in
                self?.currentUser = auth.currentUser
                if let user = auth.currentUser {
                    self?.loadUserDataForEditing(user: user)
                }
            }
        }
    }

    // Tải dữ liệu để chỉnh sửa
    func loadUserDataForEditing(user: UserModel? = nil) {
        let userToLoad = user ?? currentUser
        if let user = userToLoad {
            editedName = user.name
            editedEmail = user.email
            editedPassword = user.password
            editedDescription = user.description ?? ""
            editedDateOfBirth = user.dateOfBirth ?? Date()
            editedLocation = user.location ?? ""
            editedGender = user.gender ?? ""
            editedHobbies = user.hobbies ?? ""
            editedBio = user.bio ?? ""
        }
    }

    // Lưu thông tin
    func saveProfile(completion: @escaping () -> Void) {
        guard let user = currentUser else { return }
        let updatedUser = UserModel(
            id: user.id,
            name: editedName,
            email: editedEmail,
            password: editedPassword.isEmpty ? user.password : editedPassword, // Gửi plaintext
            avatarURL: user.avatarURL,
            description: editedDescription,
            dateOfBirth: editedDateOfBirth,
            location: editedLocation,
            joinedDate: user.joinedDate,
            gender: editedGender,
            hobbies: editedHobbies,
            bio: editedBio
        )

        APIService.updateUser(user: updatedUser) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    // Cập nhật currentUser với dữ liệu mới, nhưng không thay đổi password ở đây
                    self?.currentUser = UserModel(
                        id: user.id,
                        name: updatedUser.name,
                        email: updatedUser.email,
                        password: self?.currentUser?.password ?? updatedUser.password, // Giữ hash cũ ở local
                        avatarURL: updatedUser.avatarURL,
                        description: updatedUser.description,
                        dateOfBirth: updatedUser.dateOfBirth,
                        location: updatedUser.location,
                        joinedDate: updatedUser.joinedDate,
                        gender: updatedUser.gender,
                        hobbies: updatedUser.hobbies,
                        bio: updatedUser.bio
                    )
                    self?.authVM?.currentUser = self?.currentUser
                    print("DEBUG: ✅ Cập nhật hồ sơ thành công")
                    completion()
                } else {
                    print("DEBUG: Cập nhật hồ sơ thất bại - \(message)")
                }
            }
        }
    }

    // Hàm hash mật khẩu (giả định, thay bằng thư viện thực tế như BCrypt)
    private func hashPassword(_ password: String) -> String {
        // Thay bằng hàm hash thực tế từ backend hoặc thư viện như CryptoKit/BCrypt
        // Ví dụ: return BCrypt.hash(password)
        return "$2y$10$/86RvwhBRrYPDZnTGu4sf.LS8b5sQM5M.8ApKicYKwtlEJbZrXToa" // Placeholder
    }

    // Đăng xuất
    func logout(authVM: AuthViewModel, completion: @escaping () -> Void) {
        authVM.logout()
        self.currentUser = nil
        completion()
    }

    // Xóa tài khoản
    func deleteAccount(authVM: AuthViewModel, completion: @escaping () -> Void) {
        guard let userId = currentUser?.id else { return }
        APIService.deleteUser(userId: userId) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    authVM.logout()
                    self?.currentUser = nil
                    print("DEBUG: ✅ Xóa tài khoản thành công")
                    completion()
                } else {
                    print("DEBUG: Xóa tài khoản thất bại - \(message)")
                }
            }
        }
    }

    // Upload avatar
    func uploadAvatar(image: UIImage) {
        guard let userId = currentUser?.id else { return }
        APIService.uploadAvatar(userId: userId, image: image) { [weak self] success, message, avatarURL in
            DispatchQueue.main.async {
                if success, let url = avatarURL {
                    self?.currentUser?.avatarURL = url
                    self?.authVM?.currentUser?.avatarURL = url // Đồng bộ với authVM
                } else {
                    print("DEBUG: Upload avatar failed - \(message)")
                }
            }
        }
    }
}

// Giả định Notification Name (thêm vào nếu cần)
extension Notification.Name {
    static let didUpdateUser = Notification.Name("didUpdateUser")
}
