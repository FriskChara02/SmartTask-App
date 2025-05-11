import SwiftUI
import GoogleSignIn

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var googleAuthVM: GoogleAuthViewModel
    @EnvironmentObject var friendVM: FriendsViewModel
    @EnvironmentObject var groupVM: GroupsViewModel
    @EnvironmentObject var chatVM: ChattingViewModel
    
    var body: some View {
        NavigationView {
            List {
                // Section 1: Account
                AccountSectionView()
                
                // Section 2: Social
                Section(header: Text("Social ✧").font(.headline)) {
                    NavigationLink(destination: FriendsView()) {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.purple)
                            Text("Friends")
                        }
                    }
                    NavigationLink(destination: GroupsView()) {
                        HStack {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.blue)
                            Text("Groups")
                        }
                    }
                    NavigationLink(destination: ChattingView()) {
                        HStack {
                            Image(systemName: "ellipsis.message.fill")
                                .foregroundColor(.green)
                            Text("Chatting")
                        }
                    }
                    if authVM.currentUser?.role == "super_admin" {
                        NavigationLink(destination: AdminPanelView()) {
                            HStack {
                                Image(systemName: "person.badge.shield.checkmark.fill")
                                    .foregroundColor(.purple)
                                Text("Admin Panel")
                            }
                        }
                    }
                }
                
                // Section 3: Customize
                Section(header: Text("Customize ✦").font(.headline)) {
                    NavigationLink(destination: ThemeView()) {
                        HStack {
                            Image(systemName: "paintpalette.fill")
                                .foregroundColor(.blue)
                            Text("Theme")
                        }
                    }
                    NavigationLink(destination: ManageCategoriesView()) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.green)
                            Text("Category")
                        }
                    }
                    NavigationLink(destination: NotificationSettingsView()) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.orange)
                            Text("Notification & Reminder")
                        }
                    }
                    HStack {
                        Image(systemName: "globe")
                            .foregroundColor(.purple)
                        Text("Language")
                        Spacer()
                        Picker("Language", selection: .constant("English")) {
                            Text("English").tag("English")
                            Text("Vietnamese").tag("Vietnamese")
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                // Section 4: Help and Policies
                Section(header: Text("Help and Policies ⋆˙⟡").font(.headline)) {
                    NavigationLink(destination: HelpView()) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.blue)
                            Text("Help")
                        }
                    }
                    NavigationLink(destination: PrivacyPolicyView()) {
                        HStack {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.green)
                            Text("Privacy Policy")
                        }
                    }
                    NavigationLink(destination: TermsOfServiceView()) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.orange)
                            Text("SmartTask Terms of Service")
                        }
                    }
                }
                
                // Section 5: About
                Section(header: Text("About ᝰ.ᐟ").font(.headline)) {
                    NavigationLink(destination: SendFeedbackView()) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.purple)
                            Text("Send Feedback")
                        }
                    }
                    NavigationLink(destination: RateUsView()) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Rate Us")
                        }
                    }
                    NavigationLink(destination: ShareAppView()) {
                        HStack {
                            Image(systemName: "square.and.arrow.up.fill")
                                .foregroundColor(.blue)
                            Text("Share App")
                        }
                    }
                    NavigationLink(destination: FAQView()) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.teal)
                            Text("FAQ")
                        }
                    }
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.gray)
                        Text("Version")
                        Spacer()
                        Text("1.0.2")
                            .foregroundColor(.gray)
                    }
                }
            }
            .tint(.green)
            .navigationTitle("Settings ❀")
        }
        .onAppear {
            if let userId = authVM.currentUser?.id {
                print("DEBUG: SettingsView onAppear - fetching user info for userId=\(userId)")
                if authVM.currentUser?.role == "admin" || authVM.currentUser?.role == "super_admin" {
                    AdminService.fetchUsers(adminId: userId) { success, users, message in
                        DispatchQueue.main.async {
                            if success, let users = users {
                                print("✅ Fetched \(users.count) users")
                                if let currentUser = users.first(where: { $0.id == userId }) {
                                    authVM.currentUser = currentUser
                                }
                            } else {
                                print("❌ Failed to fetch users: \(message)")
                            }
                        }
                    }
                } else {
                    GroupService.fetchUserInfo(userId: userId) { success, user, message in
                        DispatchQueue.main.async {
                            if success, let user = user {
                                authVM.currentUser = user
                                print("✅ Fetched user info: \(user.name), role=\(user.role ?? "nil")")
                            } else {
                                print("❌ Failed to fetch user info: \(message)")
                            }
                        }
                    }
                }
            } else {
                print("❌ No userId available for fetching user info")
            }
        }
    }
}

struct AccountSectionView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var googleAuthVM: GoogleAuthViewModel

    var body: some View {
        VStack(spacing: 10) {
            // 👉 Avatar + Thông tin người dùng
            NavigationLink(destination: ProfileView()) {
                HStack(spacing: 15) {
                    if let avatarURL = authVM.currentUser?.avatarURL, !avatarURL.isEmpty {
                        AsyncImage(url: URL(string: avatarURL)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(.gray)
                            }
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(authVM.currentUser?.name ?? "User Name")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text(authVM.currentUser?.email ?? "user@example.com")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }

            // 👉 Toggle đồng bộ Google Calendar
            Toggle(isOn: $googleAuthVM.isSignedIn) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.green)
                    Text("Sync with Google Calendar")
                        .font(.system(size: 16))
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .green))
            .onChange(of: googleAuthVM.isSignedIn) { _, newValue in
                if newValue {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let rootViewController = windowScene.windows.first?.rootViewController {
                        googleAuthVM.signIn(presentingViewController: rootViewController) { result in
                            if case .failure(let error) = result {
                                print("Google Sign-In failed: \(error.localizedDescription)")
                                googleAuthVM.isSignedIn = false
                            }
                        }
                    }
                } else {
                    googleAuthVM.signOut()
                }
            }
        }
    }
}

// Placeholder Views (giữ nguyên)
struct NotificationSettingsView: View {
    var body: some View {
        Text("Notification & Reminder - Coming Soon")
            .navigationTitle("Notification & Reminder")
    }
}

// MARK: - Toast View
struct Toast: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(.primary) // Tự động điều chỉnh theo Dark/Light Mode
            .padding()
            .background(
                ZStack {
                    Color(UIColor.systemBackground).opacity(0.8) // Nền hệ thống
                    VisualEffectView(effect: UIBlurEffect(style: .systemMaterial)) // Hiệu ứng mờ
                        .opacity(0.9)
                }
            )
            .cornerRadius(10)
            .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 2)
            .padding(.top, 50)
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
    let authVM = AuthViewModel()
    let categoryVM = CategoryViewModel()
    let userVM = UserViewModel(authVM: authVM)
    let friendVM = FriendsViewModel()
    let groupVM = GroupsViewModel(authVM: authVM)
    let chatVM = ChattingViewModel()
    
    SettingsView()
        .environmentObject(authVM)
        .environmentObject(taskVM)
        .environmentObject(categoryVM)
        .environmentObject(notificationsVM)
        .environmentObject(userVM)
        .environmentObject(GoogleAuthViewModel())
        .environmentObject(friendVM)
        .environmentObject(groupVM)
        .environmentObject(chatVM)
}
