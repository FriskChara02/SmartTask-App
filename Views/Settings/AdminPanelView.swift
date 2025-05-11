import SwiftUI

struct AdminPanelView: View {
    @StateObject private var viewModel = AdminPanelViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab: AdminTab = .stats
    
    enum AdminTab: String, CaseIterable {
        case stats = "Thống kê ✦"
        case users = "Người dùng ⟢"
        case sensitiveWords = "Từ nhạy cảm .ᐟ"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Chức năng", selection: $selectedTab) {
                    ForEach(AdminTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [themeColor.opacity(0.1), themeColor.opacity(0.05)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .shadow(color: colorScheme == .dark ? .white.opacity(0.1) : .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                .animation(.easeInOut, value: selectedTab)
                
                // Loading
                if viewModel.isLoading {
                    ProgressView("Đang tải...ᐟ")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(UIColor.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 25))
                        .padding(.horizontal)
                } else {
                    ScrollView {
                        switch selectedTab {
                        case .stats:
                            StatsView(stats: viewModel.stats)
                                .transition(.opacity)
                        case .users:
                            UsersView(users: viewModel.users, viewModel: viewModel)
                                .transition(.opacity)
                        case .sensitiveWords:
                            SensitiveWordsView(words: viewModel.sensitiveWords, viewModel: viewModel)
                                .transition(.opacity)
                        }
                    }
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? .black : .white,
                                colorScheme == .dark ? themeColor.opacity(0.1) : themeColor.opacity(0.05)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            .navigationTitle("Bảng quản trị 🏅")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshData) {
                        Image(systemName: viewModel.isLoading ? "arrow.clockwise.circle.fill" : "arrow.clockwise")
                            .foregroundColor(themeColor)
                            .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                            .animation(viewModel.isLoading ? .linear(duration: 1).repeatForever(autoreverses: false) : .none, value: viewModel.isLoading)
                    }
                    .disabled(viewModel.isLoading)
                    .scaleEffect(viewModel.isLoading ? 0.9 : 1.0)
                    .animation(.spring(), value: viewModel.isLoading)
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK (✿ᴗ͈ˬᴗ͈)⁾⁾"))
                )
            }
            .onAppear {
                if let adminId = authVM.currentUser?.id {
                    viewModel.fetchAllData(adminId: adminId)
                }
            }
        }
    }
    
    private func refreshData() {
        if let adminId = authVM.currentUser?.id {
            viewModel.fetchAllData(adminId: adminId)
        }
    }
}

struct StatsView: View {
    let stats: AdminService.AdminStats?
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thống kê hoạt động ✦")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.horizontal)
                .padding(.top)
            
            if let stats = stats {
                VStack(spacing: 8) {
                    StatCard(label: "Tổng người dùng", value: "\(stats.userCount)", icon: "person.3.fill")
                    StatCard(label: "Đang online", value: "\(stats.onlineCount)", icon: "circle.fill")
                    StatCard(label: "Admin", value: "\(stats.adminCount)", icon: "person.badge.shield.checkmark.fill")
                    StatCard(label: "Super Admin", value: "\(stats.superAdminCount)", icon: "person.crop.circle.badge.checkmark")
                    StatCard(label: "Tổng tin nhắn", value: "\(stats.messageCount)", icon: "message.fill")
                    StatCard(label: "Tin nhắn thế giới", value: "\(stats.worldMessageCount)", icon: "globe")
                    StatCard(label: "Tin nhắn riêng", value: "\(stats.privateMessageCount)", icon: "person.2")
                    StatCard(label: "Tin nhắn nhóm", value: "\(stats.groupMessageCount)", icon: "person.3")
                    StatCard(label: "Tổng số nhóm", value: "\(stats.groupCount)", icon: "rectangle.stack.person.crop.fill")
                    StatCard(label: "Tổng dự án", value: "\(stats.projectCount)", icon: "folder.fill")
                    StatCard(label: "Tổng nhiệm vụ", value: "\(stats.taskCount)", icon: "checklist")
                }
                .padding(.horizontal)
            } else {
                Text("Không có dữ liệu thống kê ❀")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.vertical, 16)
            }
        }
        .padding(.bottom)
    }
}

struct StatCard: View {
    let label: String
    let value: String
    let icon: String
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(themeColor)
                .font(.system(size: 16))
                .frame(width: 24, height: 24, alignment: .center)
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text(label)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? .gray.opacity(0.2) : .white,
                    themeColor.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: colorScheme == .dark ? .white.opacity(0.1) : .gray.opacity(0.2), radius: 3, x: 0, y: 2)
    }
}

struct UsersView: View {
    let users: [UserModel]
    @ObservedObject var viewModel: AdminPanelViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText: String = ""
    
    var filteredUsers: [UserModel] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thông tin người dùng ⟢")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.horizontal)
                .padding(.top)
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Tìm kiếm theo tên ❀", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 6)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal)
            .background(colorScheme == .dark ? .gray.opacity(0.2) : .gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .padding(.horizontal)
            
            if filteredUsers.isEmpty {
                Text("Không có người dùng .ᐟ")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.vertical, 16)
            } else {
                ForEach(filteredUsers) { user in
                    UserCard(user: user)
                        .padding(.horizontal)
                        .padding(.vertical, 2)
                        .transition(.opacity)
                }
            }
        }
        .padding(.bottom)
    }
}

struct UserCard: View {
    let user: UserModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: user.avatarURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [themeColor, themeColor.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(user.email)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.gray)
                Text("Role: \(user.role?.capitalized ?? "User") 🏷️")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(themeColor)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    colorScheme == .dark ? .gray.opacity(0.2) : .white,
                    themeColor.opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: colorScheme == .dark ? .white.opacity(0.1) : .gray.opacity(0.2), radius: 3, x: 0, y: 2)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct SensitiveWordsView: View {
    let words: [SensitiveWord]
    @ObservedObject var viewModel: AdminPanelViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var newWord: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quản lý từ nhạy cảm .ᐟ.ᐟ")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .padding(.horizontal)
                .padding(.top)
            
            // Add sensitive word
            HStack {
                TextField("Thêm từ nhạy cảm ᝰ.ᐟ", text: $newWord)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(colorScheme == .dark ? .gray.opacity(0.2) : .gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                
                Button(action: {
                    if let adminId = viewModel.adminId, !newWord.isEmpty {
                        viewModel.addSensitiveWord(adminId: adminId, word: newWord)
                        newWord = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(themeColor)
                        .padding(6)
                        .background(colorScheme == .dark ? .gray.opacity(0.3) : .white)
                        .clipShape(Circle())
                        .shadow(color: colorScheme == .dark ? .white.opacity(0.1) : .gray.opacity(0.2), radius: 3)
                }
                .disabled(newWord.isEmpty || viewModel.isLoading)
                .scaleEffect(newWord.isEmpty || viewModel.isLoading ? 0.9 : 1.0)
                .animation(.spring(), value: newWord.isEmpty || viewModel.isLoading)
            }
            .padding(.horizontal)
            
            if words.isEmpty {
                Text("Không có từ nhạy cảm ᝰ.ᐟ")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.vertical, 16)
            } else {
                ForEach(words) { word in
                    HStack {
                        Text(word.word)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                colorScheme == .dark ? .gray.opacity(0.2) : .white,
                                themeColor.opacity(0.05)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .padding(.horizontal)
                    .transition(.opacity)
                }
            }
        }
        .padding(.bottom)
    }
}

class AdminPanelViewModel: ObservableObject {
    @Published var stats: AdminService.AdminStats?
    @Published var users: [UserModel] = []
    @Published var sensitiveWords: [SensitiveWord] = []
    @Published var showAlert: Bool = false
    @Published var alertTitle: String = ""
    @Published var alertMessage: String = ""
    @Published var isLoading: Bool = false
    var adminId: Int?
    
    func fetchAllData(adminId: Int) {
        print("DEBUG: Fetching all data with adminId: \(adminId)")
        self.adminId = adminId
        DispatchQueue.main.async {
            self.isLoading = true
        }
        
        let group = DispatchGroup()
        
        group.enter()
        fetchStats(adminId: adminId) {
            group.leave()
        }
        
        group.enter()
        fetchUsers(adminId: adminId) {
            group.leave()
        }
        
        group.enter()
        fetchSensitiveWords(adminId: adminId) {
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.isLoading = false
        }
    }
    
    func fetchStats(adminId: Int, completion: @escaping () -> Void = {}) {
        AdminService.fetchStats(adminId: adminId) { success, stats, message in
            DispatchQueue.main.async {
                if success, let stats = stats {
                    print("DEBUG: Stats updated with userCount: \(stats.userCount)")
                    self.stats = stats
                } else {
                    print("DEBUG: Failed to fetch stats: \(message)")
                    self.alertTitle = "Lỗi"
                    self.alertMessage = message
                    self.showAlert = true
                }
                completion()
            }
        }
    }
    
    func fetchUsers(adminId: Int, completion: @escaping () -> Void = {}) {
        AdminService.fetchUsers(adminId: adminId) { success, users, message in
            DispatchQueue.main.async {
                if success, let users = users {
                    self.users = users
                } else {
                    self.alertTitle = "Lỗi"
                    self.alertMessage = message
                    self.showAlert = true
                }
                completion()
            }
        }
    }
    
    func fetchSensitiveWords(adminId: Int, completion: @escaping () -> Void = {}) {
        AdminService.fetchSensitiveWords(adminId: adminId) { success, words, message in
            DispatchQueue.main.async {
                if success, let words = words {
                    self.sensitiveWords = words
                } else {
                    self.alertTitle = "Lỗi"
                    self.alertMessage = message
                    self.showAlert = true
                }
                completion()
            }
        }
    }
    
    func addSensitiveWord(adminId: Int, word: String) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        AdminService.addSensitiveWord(adminId: adminId, word: word) { success, message in
            DispatchQueue.main.async {
                self.isLoading = false
                self.alertTitle = success ? "Thành công" : "Lỗi"
                self.alertMessage = message
                self.showAlert = true
                if success {
                    self.fetchSensitiveWords(adminId: adminId)
                }
            }
        }
    }
}

// PreviewProvider cho AdminPanelView
struct AdminPanelView_Previews: PreviewProvider {
    static var previews: some View {
        let authVM = AuthViewModel()
        AdminPanelView()
            .environmentObject(authVM)
            .environment(\.themeColor, .blue)
    }
}
