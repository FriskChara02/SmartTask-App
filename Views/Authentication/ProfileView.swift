//  ProfileView.swift
//  SmartTask
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var friendVM: FriendsViewModel
    @EnvironmentObject var groupVM: GroupsViewModel
    @EnvironmentObject var chatVM: ChattingViewModel
    @Environment(\.themeColor) var themeColor

    // Dữ liệu bạn bè từ API
    @State private var friends: [Friend] = []
    @State private var onlineFriendsCount: Int = 0
    @State private var isLoadingFriends: Bool = false
    @State private var errorMessage: String?
    
    @AppStorage("themeColor") private var themeColorStorage: String = ""
    @AppStorage("themeTexture") private var themeTexture: String = ""
    @AppStorage("themeScenery") private var themeScenery: String = ""
    @AppStorage("customPhotoData") private var customPhotoData: Data?

    // Danh sách để ánh xạ
    private let colors: [(name: String, color: Color)] = [
        ("Default", .gray), ("Blue", .blue), ("Green", .green), ("Pink", .pink),
        ("Purple", .purple), ("Red", .red), ("Black", .black), ("Yellow", .yellow),
        ("Orange", .orange), ("Mint", .mint), ("Teal", .teal), ("Cyan", .cyan),
        ("Indigo", .indigo), ("Brown", .brown), ("White", .white)
    ]

    private let textures: [(name: String, gradient: Gradient?)] = [
        ("Default", nil),
        ("Sunset Gradient", Gradient(colors: [.orange, .pink, .purple])),
        ("Ocean Gradient", Gradient(colors: [.blue, .cyan, .teal])),
        ("Forest Gradient", Gradient(colors: [.green, .mint, .brown])),
        ("Twilight Glow", Gradient(colors: [.purple, .indigo, .blue])),
        ("Desert Heat", Gradient(colors: [.red, .orange, .yellow])),
        ("Aurora", Gradient(colors: [.cyan, .green, .blue])),
        ("Candy Pop", Gradient(colors: [.pink, .cyan, .yellow])),
        ("Midnight", Gradient(colors: [.black, .indigo, .gray])),
        ("Spring Bloom", Gradient(colors: [.mint, .pink, .white])),
        ("Golden Hour", Gradient(colors: [.yellow, .orange, .red])),
        ("Frost", Gradient(colors: [.white, .cyan, .blue]))
    ]

    private let sceneries: [(name: String, imageName: String?)] = [
        ("Default", nil),
        ("Tekapo Lake", "Tekapo Lake"),
        ("Meadow", "meadow-with-trees-wooden-fence"),
        ("Wet Vietnam", "wet-vietnam-mountain-flow-stream-rural"),
        ("Cascade", "cascade-boat-clean-china-natural-rural"),
        ("Fuji", "fuji-mountain-kawaguchiko-lake-sunset-autumn-seasons-fuji-mountain-yamanachi-japan")
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Icon Friend và nút Chatting
                    HStack(spacing: 15) {
                        // Icon Friend
                        NavigationLink(destination: FriendsView()) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 30)
                                Text("Friends (\(onlineFriendsCount) Online)")
                                    .foregroundColor(.green)
                                    .font(.headline)
                                Circle()
                                    .fill(.green)
                                    .frame(width: 8, height: 8)
                            }
                        }
                        
                        Spacer()
                        
                        // Nút Chatting
                        NavigationLink(destination: ChattingView()) {
                            Image(systemName: "ellipsis.message.fill")
                                .foregroundColor(themeColor)
                                .frame(width: 30)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)

                    avatarSection
                    userInfoSection
                    actionButtonsSection
                }
                .background(Color.gray.opacity(0.03))
            }
            .navigationTitle("Hồ sơ ㅤ✧˚ ⋆｡˚")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if userVM.isEditing {
                        Button(action: {
                            userVM.isEditing = false // Hủy chỉnh sửa
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.blue)
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !userVM.isEditing {
                        Button("Sửa༄") {
                            if let user = userVM.currentUser {
                                userVM.loadUserDataForEditing(user: user)
                                userVM.isEditing = true
                            }
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 20)
                        .background(LinearGradient(gradient: Gradient(colors: [.cyan, .green]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(25)
                        .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .disabled(userVM.currentUser == nil)
                    }
                }
            }
            .onAppear {
                if let user = authVM.currentUser {
                    userVM.currentUser = user
                    userVM.loadUserDataForEditing(user: user)
                    print("DEBUG: Loaded user on appear - \(user)")
                    fetchFriends(userId: user.id)
                } else {
                    print("DEBUG: No user found in authVM on appear")
                }
            }
            .overlay {
                if isLoadingFriends {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeColor))
                }
            }
            .background(backgroundView().opacity(0.5).ignoresSafeArea())
            .alert(isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Avatar Section
    private var avatarSection: some View {
        VStack {
            if let image = userVM.avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.blue.opacity(0.5), lineWidth: 2))
                    .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
            } else if let avatarURL = userVM.currentUser?.avatarURL, !avatarURL.isEmpty {
                AsyncImage(url: URL(string: avatarURL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue.opacity(0.5), lineWidth: 2))
                            .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 130, height: 130)
                            .clipShape(Circle())
                            .foregroundColor(.gray.opacity(0.7))
                            .overlay(Circle().stroke(Color.blue.opacity(0.5), lineWidth: 2))
                            .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 130, height: 130)
                    .clipShape(Circle())
                    .foregroundColor(.gray.opacity(0.7))
                    .overlay(Circle().stroke(Color.blue.opacity(0.5), lineWidth: 2))
                    .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
            }
            if userVM.isEditing {
                ZStack {
                    PhotosPicker("Chọn Avatar", selection: $userVM.selectedPhoto, matching: .images)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(25)
                        .shadow(color: Color.primary.opacity(0.2), radius: 5, x: 0, y: 2)
                        .disabled(userVM.isUploadingAvatar)
                        .onChange(of: userVM.selectedPhoto) {
                            Task {
                                guard let data = try? await userVM.selectedPhoto?.loadTransferable(type: Data.self),
                                      let uiImage = UIImage(data: data) else {
                                    userVM.errorMessage = "Không thể tải ảnh. Vui lòng chọn lại."
                                    userVM.showError = true
                                    return
                                }
                                userVM.avatarImage = uiImage
                                userVM.isUploadingAvatar = true
                                userVM.uploadAvatar(image: uiImage) { success, message, avatarURL in
                                    DispatchQueue.main.async {
                                        userVM.isUploadingAvatar = false
                                        if success, let avatarURL = avatarURL {
                                            userVM.currentUser?.avatarURL = avatarURL
                                            userVM.errorMessage = "Upload avatar thành công! 🎉"
                                            userVM.showError = true
                                        } else {
                                            userVM.errorMessage = "Lỗi: \(message)"
                                            userVM.showError = true
                                        }
                                    }
                                }
                            }
                        }
                    if userVM.isUploadingAvatar {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(10)
                    }
                }
                .alert(isPresented: $userVM.showError) {
                    Alert(
                        title: Text(userVM.errorMessage?.contains("thành công") ?? false ? "Thành công" : "Lỗi"),
                        message: Text(userVM.errorMessage ?? "Đã xảy ra lỗi không xác định"),
                        dismissButton: .default(Text("OK")) {
                            userVM.showError = false
                            userVM.errorMessage = nil
                        }
                    )
                }
            }
        }
        .padding(.top, 40)
    }
    
    // MARK: - User Info Section
    private var userInfoSection: some View {
        Group {
            if let user = userVM.currentUser {
                if userVM.isEditing {
                    editingUserInfo(user: user)
                } else {
                    viewingUserInfo(user: user)
                }
            } else {
                Text("Không có thông tin người dùng")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(25)
                    .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
            }
        }
    }
    
    // Chế độ chỉnh sửa
    private func editingUserInfo(user: UserModel) -> some View {
        VStack(spacing: 15) {
            // VStack 1: Username, Email, Password
            VStack(spacing: 15) {
                HStack(spacing: 10) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    TextField("Tên", text: $userVM.editedName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(themeColor, lineWidth: 1)
                        )
                        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.teal)
                    TextField("Email", text: $userVM.editedEmail)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(themeColor, lineWidth: 1)
                        )
                        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.mint)
                    SecureField("Mật khẩu hiện tại", text: $userVM.currentPassword)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(themeColor, lineWidth: 1)
                        )
                        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                        .frame(width: 200)
                    Button(userVM.showPassword ? "Ẩn ❀" : "Hiện ⏾") {
                        if userVM.currentPassword.isEmpty {
                            userVM.alertMessage = "You need to enter your password"
                            userVM.showPasswordAlert = true
                        } else {
                            authVM.verifyPassword(userVM.currentPassword) { isValid in
                                if isValid {
                                    userVM.showPassword.toggle()
                                } else {
                                    userVM.alertMessage = "Incorrect password"
                                    userVM.showPasswordAlert = true
                                }
                            }
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(themeColor)
                    .cornerRadius(25)
                    .overlay(
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(themeColor, lineWidth: 1)
                    )
                }
                if userVM.showPassword {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.open.fill")
                            .foregroundColor(themeColor)
                        Text(user.password)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(themeColor)
                    SecureField("Mật khẩu mới", text: $userVM.editedPassword)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(themeColor, lineWidth: 1)
                        )
                        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(25)
            .alert(isPresented: $userVM.showPasswordAlert) {
                Alert(
                    title: Text("Thông báo"),
                    message: Text(userVM.alertMessage),
                    dismissButton: .default(Text("OK")) {
                        userVM.showPasswordAlert = false
                    }
                )
            }

            // VStack 2: Description, DateOfBirth, Location, JoinedDate
            VStack(spacing: 15) {
                HStack(spacing: 10) {
                    Image(systemName: "text.quote")
                        .foregroundColor(.cyan)
                    TextField("Mô tả", text: $userVM.editedDescription)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(themeColor, lineWidth: 1)
                        )
                        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .foregroundColor(.yellow)
                    DatePicker("Ngày sinh", selection: $userVM.editedDateOfBirth, displayedComponents: .date)
                        .labelsHidden()
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(themeColor, lineWidth: 1)
                        )
                        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                HStack(spacing: 10) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                    TextField("Địa điểm", text: $userVM.editedLocation)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(themeColor, lineWidth: 1)
                        )
                        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                HStack(spacing: 10) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("Tham gia: \(user.joinedDate ?? Date(), formatter: dateFormatter)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(25)

            // VStack 3: Gender, Hobbies, Bio
            VStack(spacing: 15) {
                HStack(spacing: 10) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.pink)
                    Picker("Giới tính", selection: $userVM.editedGender) {
                        Text("Nam").tag("Nam")
                        Text("Nữ").tag("Nữ")
                        Text("Khác").tag("Khác")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(5)
                    .background(Color(.systemBackground))
                    .cornerRadius(25)
                    .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                HStack(spacing: 10) {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    TextField("Sở thích", text: $userVM.editedHobbies)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(themeColor, lineWidth: 1)
                        )
                        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                }
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    TextField("Giới thiệu", text: $userVM.editedBio)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(Color(.systemBackground))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(themeColor, lineWidth: 1)
                        )
                        .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(25)

            Button("Lưu ❀") {
                userVM.saveProfile {
                    userVM.isEditing = false
                }
            }
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding()
            .contentShape(Rectangle())
            .frame(maxWidth: .infinity)
            .background(LinearGradient(gradient: Gradient(colors: [.green, .blue]), startPoint: .leading, endPoint: .trailing))
            .cornerRadius(25)
            .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
            .padding(.horizontal, 20)
        }
    }
    
    // Chế độ xem thông tin
    private func viewingUserInfo(user: UserModel) -> some View {
        VStack(spacing: 15) {
            VStack(spacing: 15) {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                        .frame(width: 20) // Icon thẳng hàng
                    Text(user.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                HStack(spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.teal)
                        .frame(width: 20) // Icon thẳng hàng
                    Text(user.email)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading) // Canh trái
                }
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.mint)
                        .frame(width: 20) // Icon thẳng hàng
                    Text("••••••••")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading) // Canh trái
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(themeColor, lineWidth: 2)
            )
            .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)

            VStack(spacing: 15) {
                if let description = user.description {
                    HStack(spacing: 12) {
                        Image(systemName: "text.quote")
                            .foregroundColor(.cyan)
                            .frame(width: 20) // Icon thẳng hàng
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading) // Canh trái
                    }
                }
                if let dateOfBirth = user.dateOfBirth {
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundColor(.yellow)
                            .frame(width: 20) // Icon thẳng hàng
                        Text("Ngày sinh: \(dateOfBirth, formatter: dateFormatter)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading) // Canh trái
                    }
                }
                if let location = user.location {
                    HStack(spacing: 12) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.green)
                            .frame(width: 20) // Icon thẳng hàng
                        Text("Địa điểm: \(location)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading) // Canh trái
                    }
                }
                if let joinedDate = user.joinedDate {
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20) // Icon thẳng hàng
                        Text("Tham gia: \(joinedDate, formatter: dateFormatter)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading) // Canh trái
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(themeColor, lineWidth: 2)
            )
            .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)

            VStack(spacing: 15) {
                if let gender = user.gender {
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.pink)
                            .frame(width: 20) // Icon thẳng hàng
                        Text("Giới tính: \(gender)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading) // Canh trái
                    }
                }
                if let hobbies = user.hobbies {
                    HStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .frame(width: 20) // Icon thẳng hàng
                        Text("Sở thích: \(hobbies)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading) // Canh trái
                    }
                }
                if let bio = user.bio {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .frame(width: 20) // Icon thẳng hàng
                        Text("Giới thiệu: \(bio)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading) // Canh trái
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(themeColor, lineWidth: 2)
            )
            .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 15) {
            Button(action: {
                userVM.isLoggingOut = true
            }) {
                Text("Đăng Xuất ✦")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [.red, .orange]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(50)
                    .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
            }
            .alert("Xác nhận (｡Ó﹏Ò｡)", isPresented: $userVM.isLoggingOut) {
                Button("Đăng xuất (つ╥﹏╥)つ", role: .destructive) {
                    userVM.logout(authVM: authVM) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                Button("Hủy (✿ᴗ͈ˬᴗ͈)⁾⁾", role: .cancel) { userVM.isLoggingOut = false }
            } message: {
                Text("Bạn có chắc muốn đăng xuất? ⟢")
            }

            Button(action: {
                userVM.isDeletingAccount = true
            }) {
                Text("Xóa Tài Khoản ✿")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [.red, .pink]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(50)
                    .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
            }
            .alert("Xác nhận (｡•́︿•̀｡)", isPresented: $userVM.isDeletingAccount) {
                Button("Xóa (இ﹏இ`｡)", role: .destructive) {
                    userVM.deleteAccount(authVM: authVM) {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                Button("Hủy (✿´꒳`)ﾉ", role: .cancel) { userVM.isDeletingAccount = false }
            } message: {
                Text("Bạn có chắc muốn xóa tài khoản? Hành động này không thể hoàn tác. ⟢")
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    // MARK: - Fetch Friends
    private func fetchFriends(userId: Int) {
        isLoadingFriends = true
        FriendService.fetchFriends(userId: userId) { success, friends, message in
            DispatchQueue.main.async {
                if success, let friends = friends {
                    self.friends = friends
                    self.onlineFriendsCount = friends.filter { $0.status == "online" }.count
                } else {
                    self.errorMessage = message
                }
                self.isLoadingFriends = false
            }
        }
    }
    
    // MARK: - Background View
    private func backgroundView() -> some View {
        if !themeTexture.isEmpty && themeTexture != "Default" {
            if let selectedGradient = textures.first(where: { $0.name == themeTexture })?.gradient {
                return AnyView(LinearGradient(
                    gradient: selectedGradient,
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
        } else if !themeScenery.isEmpty && themeScenery != "Default" {
            if themeScenery == "Your Photos", let photoData = UserDefaults.standard.data(forKey: "customPhotoData"), let uiImage = UIImage(data: photoData) {
                return AnyView(Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipped())
            } else if let selectedImage = sceneries.first(where: { $0.name == themeScenery })?.imageName {
                return AnyView(Image(selectedImage)
                    .resizable()
                    .scaledToFill()
                    .clipped())
            }
        }
        return AnyView(LinearGradient(
            gradient: Gradient(colors: [
                (colors.first(where: { $0.name == themeColorStorage })?.color ?? .gray).opacity(0.1),
                Color(UIColor.systemBackground)
            ]),
            startPoint: .top,
            endPoint: .bottom
        ))
    }
}

// MARK: - DateFormatter
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
    let authVM = AuthViewModel()
    let userVM = UserViewModel(authVM: authVM)
    let friendVM = FriendsViewModel()
    let groupVM = GroupsViewModel(authVM: authVM)
    let chatVM = ChattingViewModel()

    ProfileView()
        .environmentObject(authVM)
        .environmentObject(taskVM)
        .environmentObject(CategoryViewModel())
        .environmentObject(notificationsVM)
        .environmentObject(userVM)
        .environmentObject(friendVM)
        .environmentObject(groupVM)
        .environmentObject(chatVM)
        .task {
            authVM.currentUser = UserModel(
                id: 1,
                name: "Test User",
                email: "test@example.com",
                password: "password123",
                avatarURL: nil,
                description: "Tôi là người dùng thử nghiệm",
                dateOfBirth: Date().addingTimeInterval(-315360000),
                location: "TPHCM",
                joinedDate: Date().addingTimeInterval(-86400),
                gender: "Nam",
                hobbies: "Đọc sách, chơi game",
                bio: "Một người yêu công nghệ"
            )
        }
}
