import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        NavigationView {
            List {
                // Section 1: Account
                Section(header: Text("Account ✿").font(.headline)) {
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
                }
                
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
                        Text("0.3.8")
                            .foregroundColor(.gray)
                    }
                }
            }
            .tint(.green)
            .navigationTitle("Settings ❀")
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

struct HelpView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🎉 Help Page 🎉")
                .font(.title)
            Text("Mình FriskChara ở đây để giúp bạn! Hãy vui vẻ nhé! 😊")
        }
        .navigationTitle("Help")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🔒 Privacy Policy")
                .font(.title)
            Text("Thông tin của bạn được bảo mật tuyệt đối!")
        }
        .navigationTitle("Privacy Policy")
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("📜 Terms of Service")
                .font(.title)
            Text("Sử dụng SmartTask theo các điều khoản vui vẻ này!")
        }
        .navigationTitle("Terms of Service")
    }
}

struct SendFeedbackView: View {
    @State private var feedback: String = ""
    @State private var showAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Your Feedback")
                .font(.title2)
            TextField("Enter your feedback", text: $feedback)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Send") {
                showAlert = true
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
        }
        .navigationTitle("Send Feedback")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Thank You!"), message: Text("Thank you for feedback to us!"), dismissButton: .default(Text("OK")))
        }
    }
}

struct RateUsView: View {
    @State private var rating: Int = 0
    @State private var showAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Rate Us")
                .font(.title2)
            HStack(spacing: 10) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: rating >= star ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .onTapGesture {
                            rating = star
                            showAlert = true
                        }
                }
            }
            .font(.title)
        }
        .navigationTitle("Rate Us")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Thank You!"), message: Text("Thank you for Rate Us to us!"), dismissButton: .default(Text("OK")))
        }
    }
}

struct ShareAppView: View {
    var body: some View {
        Text("Share App - Coming Soon")
            .navigationTitle("Share App")
    }
}

struct FAQView: View {
    var body: some View {
        List {
            Section(header: Text("Những câu hỏi thường gặp").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. Làm sao để thêm task mới?")
                        .font(.subheadline).bold()
                    Text("Bạn vào màn hình chính, nhấn nút 'leaf' và điền thông tin task.")
                        .font(.subheadline)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("2. Theme có thể thay đổi ở đâu?")
                        .font(.subheadline).bold()
                    Text("Vào Settings > Theme để chọn màu yêu thích!")
                        .font(.subheadline)
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("3. Làm sao để xóa category?")
                        .font(.subheadline).bold()
                    Text("Gốc bên phải ở trên hình Pháo Hoa > Manage Categories, chọn dấu 3 chấm ngang và nhấn Delete.")
                        .font(.subheadline)
                }
            }
        }
        .navigationTitle("FAQ")
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM)
    let authVM = AuthViewModel()
    let categoryVM = CategoryViewModel()
    let userVM = UserViewModel(authVM: authVM)
    
    SettingsView()
        .environmentObject(authVM)
        .environmentObject(taskVM)
        .environmentObject(categoryVM)
        .environmentObject(notificationsVM)
        .environmentObject(userVM)
}
