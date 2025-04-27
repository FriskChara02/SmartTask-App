import SwiftUI
import GoogleSignIn

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var googleAuthVM: GoogleAuthViewModel // ✅ Theo dõi trạng thái Google Calendar
    
    var body: some View {
        NavigationView {
            List {
                // Section 1: Account
                AccountSectionView()
                
                // Section 2: Customize
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
                
                // Section 3: Help and Policies
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
                
                // Section 4: About
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
                        Text("0.8.1")
                            .foregroundColor(.gray)
                    }
                }
            }
            .tint(.green)
            .navigationTitle("Settings ❀")
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
    
    SettingsView()
        .environmentObject(authVM)
        .environmentObject(taskVM)
        .environmentObject(categoryVM)
        .environmentObject(notificationsVM)
        .environmentObject(userVM)
        .environmentObject(GoogleAuthViewModel())
}
