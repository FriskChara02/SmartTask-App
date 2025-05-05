import SwiftUI

struct AdminPanelView: View {
    @StateObject private var viewModel = AdminPanelViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedTab: AdminTab = .stats
    
    enum AdminTab: String, CaseIterable {
        case stats = "Thống kê"
        case users = "Người dùng"
        case sensitiveWords = "Từ nhạy cảm"
        case reports = "Báo cáo"
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab selector
                Picker("Chức năng", selection: $selectedTab) {
                    ForEach(AdminTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content based on selected tab
                ScrollView {
                    switch selectedTab {
                    case .stats:
                        StatsView(stats: viewModel.stats)
                    case .users:
                        UsersView(users: viewModel.users, viewModel: viewModel)
                    case .sensitiveWords:
                        SensitiveWordsView(words: viewModel.sensitiveWords, viewModel: viewModel)
                    case .reports:
                        ReportsView(reports: viewModel.reports)
                    }
                }
            }
            .navigationTitle("Bảng quản trị")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Thông báo"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Thống kê hoạt động")
                .font(.headline)
                .padding(.horizontal)
            
            if let stats = stats {
                StatRow(label: "Tổng số người dùng", value: "\(stats.userCount)")
                StatRow(label: "Người dùng đang online", value: "\(stats.onlineCount)")
                StatRow(label: "Admin", value: "\(stats.adminCount)")
                StatRow(label: "Super Admin", value: "\(stats.superAdminCount)")
                StatRow(label: "Tổng số tin nhắn", value: "\(stats.messageCount)")
                StatRow(label: "Tin nhắn thế giới", value: "\(stats.worldMessageCount)")
                StatRow(label: "Tin nhắn riêng", value: "\(stats.privateMessageCount)")
                StatRow(label: "Tin nhắn nhóm", value: "\(stats.groupMessageCount)")
                StatRow(label: "Số nhóm", value: "\(stats.groupCount)")
                StatRow(label: "Số dự án", value: "\(stats.projectCount)")
                StatRow(label: "Số nhiệm vụ", value: "\(stats.taskCount)")
            } else {
                Text("Không có dữ liệu")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct UsersView: View {
    let users: [UserModel]
    @ObservedObject var viewModel: AdminPanelViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quản lý người dùng")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(users) { user in
                HStack {
                    AsyncImage(url: URL(string: user.avatarURL ?? "")) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.circle.fill")
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(user.name)
                            .font(.subheadline)
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button("Cấm") {
                            if let adminId = viewModel.adminId {
                                viewModel.banUser(adminId: adminId, userId: user.id, reason: "Vi phạm quy định")
                            }
                        }
                        Button("Bỏ cấm") {
                            if let adminId = viewModel.adminId {
                                viewModel.unbanUser(adminId: adminId, userId: user.id)
                            }
                        }
                        Button("Nâng cấp vai trò") {
                            if let adminId = viewModel.adminId {
                                viewModel.promoteUser(adminId: adminId, userId: user.id, newRole: user.role == "admin" ? "super_admin" : "admin")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .padding()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical)
    }
}

struct SensitiveWordsView: View {
    let words: [SensitiveWord]
    @ObservedObject var viewModel: AdminPanelViewModel
    @State private var newWord: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quản lý từ nhạy cảm")
                .font(.headline)
                .padding(.horizontal)
            
            HStack {
                TextField("Thêm từ nhạy cảm", text: $newWord)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(action: {
                    if let adminId = viewModel.adminId, !newWord.isEmpty {
                        viewModel.addSensitiveWord(adminId: adminId, word: newWord)
                        newWord = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            ForEach(words) { word in
                HStack {
                    Text(word.word)
                    Spacer()
                    Button(action: {
                        if let adminId = viewModel.adminId {
                            viewModel.removeSensitiveWord(adminId: adminId, wordId: word.id)
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical)
    }
}

struct ReportsView: View {
    let reports: [Report]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Báo cáo")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(reports) { report in
                VStack(alignment: .leading) {
                    Text("Người dùng ID: \(report.userId)")
                        .font(.subheadline)
                    Text("Loại: \(report.type)")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Nội dung: \(report.content)")
                        .font(.caption)
                    Text("Thời gian: \(report.createdAt, style: .date) \(report.createdAt, style: .time)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
        .padding(.vertical)
    }
}

class AdminPanelViewModel: ObservableObject {
    @Published var stats: AdminService.AdminStats?
    @Published var users: [UserModel] = []
    @Published var sensitiveWords: [SensitiveWord] = []
    @Published var reports: [Report] = []
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    var adminId: Int?
    
    func fetchAllData(adminId: Int) {
        self.adminId = adminId
        fetchStats(adminId: adminId)
        fetchUsers(adminId: adminId)
        fetchSensitiveWords(adminId: adminId)
        fetchReports(adminId: adminId)
    }
    
    func fetchStats(adminId: Int) {
        AdminService.fetchStats(adminId: adminId) { success, stats, message in
            if success, let stats = stats {
                DispatchQueue.main.async {
                    self.stats = stats
                }
            } else {
                DispatchQueue.main.async {
                    self.alertMessage = message
                    self.showAlert = true
                }
            }
        }
    }
    
    func fetchUsers(adminId: Int) {
        AdminService.fetchUsers(adminId: adminId) { success, users, message in
            if success, let users = users {
                DispatchQueue.main.async {
                    self.users = users
                }
            } else {
                DispatchQueue.main.async {
                    self.alertMessage = message
                    self.showAlert = true
                }
            }
        }
    }
    
    func fetchSensitiveWords(adminId: Int) {
        AdminService.fetchSensitiveWords(adminId: adminId) { success, words, message in
            if success, let words = words {
                DispatchQueue.main.async {
                    self.sensitiveWords = words
                }
            } else {
                DispatchQueue.main.async {
                    self.alertMessage = message
                    self.showAlert = true
                }
            }
        }
    }
    
    func fetchReports(adminId: Int) {
        AdminService.fetchReports(adminId: adminId) { success, reports, message in
            if success, let reports = reports {
                DispatchQueue.main.async {
                    self.reports = reports
                }
            } else {
                DispatchQueue.main.async {
                    self.alertMessage = message
                    self.showAlert = true
                }
            }
        }
    }
    
    func banUser(adminId: Int, userId: Int, reason: String?) {
        AdminService.banUser(adminId: adminId, userId: userId, reason: reason) { success, message in
            DispatchQueue.main.async {
                self.alertMessage = message
                self.showAlert = true
                if success {
                    self.fetchUsers(adminId: adminId)
                }
            }
        }
    }
    
    func unbanUser(adminId: Int, userId: Int) {
        AdminService.unbanUser(adminId: adminId, userId: userId) { success, message in
            DispatchQueue.main.async {
                self.alertMessage = message
                self.showAlert = true
                if success {
                    self.fetchUsers(adminId: adminId)
                }
            }
        }
    }
    
    func promoteUser(adminId: Int, userId: Int, newRole: String) {
        AdminService.promoteUser(adminId: adminId, userId: userId, newRole: newRole) { success, message in
            DispatchQueue.main.async {
                self.alertMessage = message
                self.showAlert = true
                if success {
                    self.fetchUsers(adminId: adminId)
                }
            }
        }
    }
    
    func addSensitiveWord(adminId: Int, word: String) {
        APIService.addSensitiveWord(word: word, adminId: adminId) { success, message in
            DispatchQueue.main.async {
                self.alertMessage = message
                self.showAlert = true
                if success {
                    self.fetchSensitiveWords(adminId: adminId)
                }
            }
        }
    }
    
    func removeSensitiveWord(adminId: Int, wordId: Int) {
        AdminService.removeSensitiveWord(adminId: adminId, wordId: wordId) { success, message in
            DispatchQueue.main.async {
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
    }
}
