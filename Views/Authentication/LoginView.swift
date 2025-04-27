import SwiftUI

struct LoginView: View {
    // MARK: - Properties
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @Environment(\.themeColor) var themeColor
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoggedIn = false

    // MARK: - Body
    var body: some View {
        NavigationStack {
            if isLoggedIn {
                HomeView()
                    .environmentObject(taskVM)
                    .environmentObject(categoryVM)
                    .environmentObject(authVM)
            } else {
                ZStack {
                    // Gradient background ^^
                    LinearGradient(
                        gradient: Gradient(colors: [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 20) {
                            Text("Đăng Nhập ❀")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            // Email TextField ^^
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(themeColor)
                                    .frame(width: 20)
                                TextField("Email", text: $email)
                                    .font(.system(size: 16, design: .rounded))
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 10)
                            }
                            .padding(.horizontal)
                            .background(Color(UIColor.systemBackground).opacity(0.95))
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                            
                            // Password SecureField ^^
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(themeColor)
                                    .frame(width: 20)
                                SecureField("Mật khẩu", text: $password)
                                    .font(.system(size: 16, design: .rounded))
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 10)
                            }
                            .padding(.horizontal)
                            .background(Color(UIColor.systemBackground).opacity(0.95))
                            .cornerRadius(15)
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                            
                            // Login Button ^^
                            Button(action: login) {
                                Text("Đăng Nhập")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .padding(.vertical, 15)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                                    .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                                    .scaleEffect(authVM.isAuthenticated ? 0.95 : 1.0)
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                            .animation(.spring(), value: authVM.isAuthenticated)
                            
                            // Error Message ^^
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)
                                    .background(Color(UIColor.systemBackground).opacity(0.95))
                                    .cornerRadius(10)
                                    .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                                    .transition(.opacity)
                            }
                            
                            // Register NavigationLink ^^
                            NavigationLink(
                                destination: RegisterView()
                                    .environmentObject(taskVM)
                                    .environmentObject(categoryVM)
                                    .environmentObject(authVM)
                            ) {
                                Text("Chưa có tài khoản? Đăng ký")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(themeColor)
                                    .padding(.top, 10)
                            }
                        }
                        
                        Spacer()
                    }
                    .animation(.easeInOut(duration: 0.3), value: errorMessage)
                }
            }
        }
    }

    // MARK: - Login Function
    func login() {
        authVM.login(email: email, password: password) { message in
            DispatchQueue.main.async {
                if authVM.isAuthenticated {
                    self.isLoggedIn = true
                    self.errorMessage = ""
                    if let userId = authVM.currentUser?.id {
                        self.taskVM.userId = userId
                        UserDefaults.standard.set(userId, forKey: "userId")
                    }
                    self.notificationsVM.fetchNotifications()
                } else {
                    self.errorMessage = message
                }
            }
        }
    }
}

struct AnyCodable: Decodable {
    let value: Any
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let int = try? container.decode(Int.self) {
            value = int
        } else if let string = try? container.decode(String.self) {
            value = string
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
    let authVM = AuthViewModel()
    let userVM = UserViewModel()
    
    LoginView()
        .environmentObject(taskVM)
        .environmentObject(CategoryViewModel())
        .environmentObject(authVM)
        .environmentObject(notificationsVM)
        .environmentObject(userVM)
        .environment(\.themeColor, .blue)
}
