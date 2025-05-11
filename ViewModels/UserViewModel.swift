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
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isUploadingAvatar: Bool = false

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
    @Published var editedStatus = "offline" // online, offline, idle, dnd, invisible
    @Published var editedRole = "user" // user, admin, super_admin

    private var authVM: AuthViewModel?

    // Khởi tạo với AuthViewModel
    init(authVM: AuthViewModel? = nil) {
        self.authVM = authVM
        self.currentUser = authVM?.currentUser
        if let user = currentUser {
            loadUserDataForEditing(user: user)
        }
        
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
            editedStatus = user.status ?? "offline"
            editedRole = user.role ?? "user"
            avatarImage = nil
        }
    }

    // Lưu thông tin
        func saveProfile(completion: @escaping () -> Void) {
            guard let user = currentUser, currentUser?.id != nil else {
                alertMessage = "Không tìm thấy người dùng"
                showPasswordAlert = true
                return
            }

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
                bio: editedBio,
                token: user.token,
                status: editedStatus,
                role: nil // Không gửi role vì chỉ liên quan đến chat/group
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
                            bio: updatedUser.bio,
                            token: updatedUser.token,
                            status: updatedUser.status,
                            role: self?.currentUser?.role // Giữ role cũ
                        )
                        self?.authVM?.currentUser = self?.currentUser
                        print("DEBUG: ✅ Cập nhật hồ sơ thành công")
                        completion()
                    } else {
                        self?.alertMessage = message
                        self?.showPasswordAlert = true
                        print("DEBUG: ❌ Cập nhật hồ sơ thất bại - \(message)")
                    }
                }
            }
        }

        // Cập nhật trạng thái (online, offline, idle, dnd, invisible)
        func updateStatus(_ status: String, completion: @escaping (Bool) -> Void) {
            guard let userId = currentUser?.id else {
                alertMessage = "Không tìm thấy người dùng"
                showPasswordAlert = true
                completion(false)
                return
            }

            APIService.updateStatus(userId: userId, status: status) { [weak self] success, message in
                DispatchQueue.main.async {
                    if success {
                        self?.currentUser?.status = status
                        self?.authVM?.currentUser?.status = status
                        self?.editedStatus = status
                        print("DEBUG: ✅ Cập nhật trạng thái thành công: \(status)")
                        completion(true)
                    } else {
                        self?.alertMessage = message
                        self?.showPasswordAlert = true
                        print("DEBUG: ❌ Cập nhật trạng thái thất bại - \(message)")
                        completion(false)
                    }
                }
            }
        }

    // Gửi yêu cầu kết bạn
    func sendFriendRequest(to userId: Int, completion: @escaping (Bool) -> Void) {
        guard let currentUserId = currentUser?.id else {
            alertMessage = "Không tìm thấy người dùng"
            showPasswordAlert = true
            completion(false)
            return
        }

        APIService.sendFriendRequest(from: currentUserId, to: userId) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    print("DEBUG: ✅ Gửi yêu cầu kết bạn thành công tới user \(userId)")
                    completion(true)
                } else {
                    self?.alertMessage = message
                    self?.showPasswordAlert = true
                    print("DEBUG: ❌ Gửi yêu cầu kết bạn thất bại - \(message)")
                    completion(false)
                }
            }
        }
    }

    // Chấp nhận yêu cầu kết bạn
    func acceptFriendRequest(requestId: Int, completion: @escaping (Bool) -> Void) {
        APIService.acceptFriendRequest(requestId: requestId) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    print("DEBUG: ✅ Chấp nhận yêu cầu kết bạn thành công: \(requestId)")
                    completion(true)
                } else {
                    self?.alertMessage = message
                    self?.showPasswordAlert = true
                    print("DEBUG: ❌ Chấp nhận yêu cầu kết bạn thất bại - \(message)")
                    completion(false)
                }
            }
        }
    }

    // Từ chối yêu cầu kết bạn
    func rejectFriendRequest(requestId: Int, completion: @escaping (Bool) -> Void) {
        APIService.rejectFriendRequest(requestId: requestId) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    print("DEBUG: ✅ Từ chối yêu cầu kết bạn thành công: \(requestId)")
                    completion(true)
                } else {
                    self?.alertMessage = message
                    self?.showPasswordAlert = true
                    print("DEBUG: ❌ Từ chối yêu cầu kết bạn thất bại - \(message)")
                    completion(false)
                }
            }
        }
    }

    // Khởi tạo phiên chat riêng
    func startPrivateChat(with userId: Int, completion: @escaping (Bool, String?) -> Void) {
        guard let currentUserId = currentUser?.id else {
            alertMessage = "Không tìm thấy người dùng"
            showPasswordAlert = true
            completion(false, nil)
            return
        }

        APIService.startPrivateChat(from: currentUserId, to: userId) { [weak self] success, message, chatId in
            DispatchQueue.main.async {
                if success, let chatId = chatId {
                    print("DEBUG: ✅ Khởi tạo phiên chat riêng thành công: \(chatId)")
                    completion(true, chatId)
                } else {
                    self?.alertMessage = message
                    self?.showPasswordAlert = true
                    print("DEBUG: ❌ Khởi tạo phiên chat riêng thất bại - \(message)")
                    completion(false, nil)
                }
            }
        }
    }

    // Đăng xuất
    func logout(authVM: AuthViewModel, completion: @escaping () -> Void) {
        authVM.logout()
        self.currentUser = nil
        print("DEBUG: ✅ Đăng xuất thành công")
        completion()
    }

    // Xóa tài khoản
        func deleteAccount(authVM: AuthViewModel, completion: @escaping () -> Void) {
            guard let userId = currentUser?.id else {
                alertMessage = "Không tìm thấy người dùng"
                showPasswordAlert = true
                return
            }
            APIService.deleteUser(userId: userId) { [weak self] success, message in
                DispatchQueue.main.async {
                    if success {
                        authVM.logout()
                        self?.currentUser = nil
                        print("DEBUG: ✅ Xóa tài khoản thành công")
                        completion()
                    } else {
                        self?.alertMessage = message
                        self?.showPasswordAlert = true
                        print("DEBUG: ❌ Xóa tài khoản thất bại - \(message)")
                    }
                }
            }
        }

    // Upload avatar
    func uploadAvatar(image: UIImage, completion: @escaping (Bool, String, String?) -> Void) {
        guard let userId = currentUser?.id else {
            let message = "Không tìm thấy người dùng"
            errorMessage = message
            showError = true
            print("DEBUG: ❌ \(message)")
            completion(false, message, nil)
            return
        }
        // Kiểm tra kích thước ảnh (giới hạn 5MB)
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              imageData.count <= 5 * 1024 * 1024 else {
            let message = "Ảnh quá lớn (giới hạn 5MB)"
            errorMessage = message
            showError = true
            print("DEBUG: ❌ Ảnh quá lớn: \(image.jpegData(compressionQuality: 0.8)?.count ?? 0) bytes")
            completion(false, message, nil)
            return
        }

        APIService.uploadAvatar(userId: userId, image: image) { [weak self] success, message, avatarURL in
            DispatchQueue.main.async {
                if success, let url = avatarURL {
                    self?.currentUser?.avatarURL = url
                    self?.authVM?.currentUser?.avatarURL = url
                    print("DEBUG: ✅ Upload avatar thành công: \(url)")
                } else {
                    print("DEBUG: ❌ Upload avatar thất bại - \(message)")
                }
                self?.errorMessage = message
                self?.showError = true
                completion(success, message, avatarURL)
            }
        }
    }
}

// Giả định Notification Name (thêm vào nếu cần)
extension Notification.Name {
    static let didUpdateUser = Notification.Name("didUpdateUser")
}
