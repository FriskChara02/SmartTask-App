import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    
    @State private var isEditing = false
    @State private var isLoggingOut = false
    @State private var isDeletingAccount = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var avatarImage: UIImage? = nil
    
    // Các trường chỉnh sửa
    @State private var editedName = ""
    @State private var editedEmail = ""
    @State private var editedPassword = ""
    @State private var currentPassword = "" // Để kiểm tra mật khẩu hiện tại
    @State private var showPassword = false
    @State private var editedDescription = ""
    @State private var editedDateOfBirth: Date = Date()
    @State private var editedLocation = ""
    @State private var editedGender = ""
    @State private var editedHobbies = ""
    @State private var editedBio = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Avatar
                    VStack {
                        if let image = avatarImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            AsyncImage(url: URL(string: authVM.currentUser?.avatarURL ?? "")) { phase in
                                if let image = phase.image {
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                }
                            }
                        }
                        if isEditing {
                            PhotosPicker("Chọn Avatar", selection: $selectedPhoto, matching: .images)
                                .onChange(of: selectedPhoto) {
                                    Task {
                                        if let data = try? await selectedPhoto?.loadTransferable(type: Data.self),
                                           let uiImage = UIImage(data: data) {
                                            avatarImage = uiImage
                                            uploadAvatar(image: uiImage)
                                        }
                                    }
                                }
                        }
                    }
                    .padding(.top, 40)
                    
                    // Thông tin người dùng
                    if let user = authVM.currentUser {
                        if isEditing {
                            // VStack 1: Username, Email, Password
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.blue)
                                    TextField("Tên", text: $editedName)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.blue)
                                    TextField("Email", text: $editedEmail)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.blue)
                                    SecureField("Mật khẩu hiện tại", text: $currentPassword)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                        .frame(width: 200)
                                    Button(showPassword ? "Ẩn" : "Hiện") {
                                        if currentPassword == user.password {
                                            showPassword.toggle()
                                        }
                                    }
                                    .disabled(currentPassword != user.password)
                                }
                                if showPassword {
                                    HStack {
                                        Image(systemName: "lock.open.fill")
                                            .foregroundColor(.blue)
                                        Text(user.password)
                                            .font(.subheadline)
                                    }
                                }
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.blue)
                                    SecureField("Mật khẩu mới", text: $editedPassword)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            .padding(.horizontal)
                            
                            // VStack 2: Description, DateOfBirth, Location, JoinedDate
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "text.quote")
                                        .foregroundColor(.blue)
                                    TextField("Mô tả", text: $editedDescription)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.blue)
                                    DatePicker("Ngày sinh", selection: $editedDateOfBirth, displayedComponents: .date)
                                        .labelsHidden()
                                }
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundColor(.blue)
                                    TextField("Địa điểm", text: $editedLocation)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .foregroundColor(.blue)
                                    Text("Tham gia: \(user.joinedDate ?? Date(), formatter: dateFormatter)")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)
                            
                            // VStack 3: Gender, Hobbies, Bio
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(.blue)
                                    Picker("Giới tính", selection: $editedGender) {
                                        Text("Nam").tag("Nam")
                                        Text("Nữ").tag("Nữ")
                                        Text("Khác").tag("Khác")
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                HStack {
                                    Image(systemName: "heart.fill")
                                        .foregroundColor(.blue)
                                    TextField("Sở thích", text: $editedHobbies)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.blue)
                                    TextField("Giới thiệu", text: $editedBio)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                            .padding(.horizontal)
                            
                            Button("Lưu") {
                                saveProfile()
                                isEditing = false
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        } else {
                            // Chế độ xem thông tin
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.blue)
                                    Text(user.name)
                                        .font(.title)
                                        .fontWeight(.bold)
                                }
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.blue)
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.blue)
                                    Text("••••••••")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                if let description = user.description {
                                    HStack {
                                        Image(systemName: "text.quote")
                                            .foregroundColor(.blue)
                                        Text(description)
                                            .font(.subheadline)
                                    }
                                }
                                if let dateOfBirth = user.dateOfBirth {
                                    HStack {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.blue)
                                        Text("Ngày sinh: \(dateOfBirth, formatter: dateFormatter)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                if let location = user.location {
                                    HStack {
                                        Image(systemName: "location.fill")
                                            .foregroundColor(.blue)
                                        Text("Địa điểm: \(location)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                if let joinedDate = user.joinedDate {
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.blue)
                                        Text("Tham gia: \(joinedDate, formatter: dateFormatter)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                if let gender = user.gender {
                                    HStack {
                                        Image(systemName: "person.2.fill")
                                            .foregroundColor(.blue)
                                        Text("Giới tính: \(gender)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                if let hobbies = user.hobbies {
                                    HStack {
                                        Image(systemName: "heart.fill")
                                            .foregroundColor(.blue)
                                        Text("Sở thích: \(hobbies)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                                if let bio = user.bio {
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundColor(.blue)
                                        Text("Giới thiệu: \(bio)")
                                            .font(.subheadline)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                        
                        // Nút Đăng xuất và Xóa tài khoản
                        VStack(spacing: 10) {
                            Button(action: {
                                isLoggingOut = true
                            }) {
                                Text("Đăng Xuất")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .alert("Xác nhận", isPresented: $isLoggingOut) {
                                Button("Đăng xuất", role: .destructive) {
                                    logoutAndReturnToLogin()
                                }
                                Button("Hủy", role: .cancel) { isLoggingOut = false }
                            } message: {
                                Text("Bạn có chắc muốn đăng xuất?")
                            }
                            
                            Button(action: {
                                isDeletingAccount = true
                            }) {
                                Text("Xóa Tài Khoản")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .alert("Xác nhận", isPresented: $isDeletingAccount) {
                                Button("Xóa", role: .destructive) {
                                    deleteAccount()
                                }
                                Button("Hủy", role: .cancel) { isDeletingAccount = false }
                            } message: {
                                Text("Bạn có chắc muốn xóa tài khoản? Hành động này không thể hoàn tác.")
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    } else {
                        Text("Không có thông tin người dùng")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Hồ sơ")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isEditing {
                        Button("Sửa") {
                            loadUserDataForEditing()
                            isEditing = true
                        }
                    }
                }
            }
        }
    }
    
    // Hàm tải dữ liệu người dùng để chỉnh sửa
    private func loadUserDataForEditing() {
        if let user = authVM.currentUser {
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
    
    // Hàm lưu thông tin vào database
    private func saveProfile() {
        guard let user = authVM.currentUser else { return }
        let updatedUser = UserModel(
            id: user.id,
            name: editedName,
            email: editedEmail,
            password: editedPassword.isEmpty ? user.password : editedPassword,
            avatarURL: user.avatarURL,
            description: editedDescription,
            dateOfBirth: editedDateOfBirth,
            location: editedLocation,
            joinedDate: user.joinedDate,
            gender: editedGender,
            hobbies: editedHobbies,
            bio: editedBio
        )
        
        APIService.updateUser(user: updatedUser) { success, message in
            DispatchQueue.main.async {
                if success {
                    authVM.currentUser = updatedUser
                    print("DEBUG: ✅ Cập nhật hồ sơ thành công")
                } else {
                    print("DEBUG: Cập nhật hồ sơ thất bại - \(message)")
                }
            }
        }
    }
    
    // Hàm đăng xuất
    private func logoutAndReturnToLogin() {
        authVM.logout()
        presentationMode.wrappedValue.dismiss()
    }
    
    // Hàm xóa tài khoản
    private func deleteAccount() {
        guard let userId = authVM.currentUser?.id else { return }
        APIService.deleteUser(userId: userId) { success, message in
            DispatchQueue.main.async {
                if success {
                    authVM.logout()
                    presentationMode.wrappedValue.dismiss()
                    print("DEBUG: ✅ Xóa tài khoản thành công")
                } else {
                    print("DEBUG: Xóa tài khoản thất bại - \(message)")
                }
            }
        }
    }
    
    // Hàm upload avatar
    private func uploadAvatar(image: UIImage) {
        guard let userId = authVM.currentUser?.id else { return }
        APIService.uploadAvatar(userId: userId, image: image) { success, message, avatarURL in
            DispatchQueue.main.async {
                if success, let url = avatarURL {
                    authVM.currentUser?.avatarURL = url
                } else {
                    print("DEBUG: Upload avatar failed - \(message)")
                }
            }
        }
    }
}

// DateFormatter cho ngày tháng
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM)
    let authVM = AuthViewModel()
    
    // Tạo ProfileView với các environment objects trong một lần gọi
    ProfileView()
        .environmentObject(authVM)
        .environmentObject(taskVM)
        .environmentObject(CategoryViewModel())
        .environmentObject(notificationsVM)
        .task {
            // Gán currentUser trong .task để tránh lỗi buildExpression
            authVM.currentUser = UserModel(
                id: 1,
                name: "Test User",
                email: "test@example.com",
                password: "password123",
                avatarURL: nil,
                description: "Tôi là người dùng thử nghiệm",
                dateOfBirth: Date().addingTimeInterval(-315360000), // 10 năm trước
                location: "TPHCM",
                joinedDate: Date().addingTimeInterval(-86400), // 1 ngày trước
                gender: "Nam",
                hobbies: "Đọc sách, chơi game",
                bio: "Một người yêu công nghệ"
            )
        }
}
