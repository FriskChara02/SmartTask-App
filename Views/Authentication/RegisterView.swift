import SwiftUI

struct RegisterView: View {
    // MARK: - Properties
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var userVM: UserViewModel
    @Environment(\.themeColor) var themeColor
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isRegistered = false // ✅ Trạng thái đăng ký thành công

    // MARK: - Body
    var body: some View {
        NavigationStack {
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
                        Text("Đăng Ký ❅")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // Name TextField ^^
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(themeColor)
                                .frame(width: 20)
                            TextField("Họ và tên", text: $name)
                                .font(.system(size: 16, design: .rounded))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 10)
                        }
                        .padding(.horizontal)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(15)
                        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        
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
                        
                        // Confirm Password SecureField ^^
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundColor(themeColor)
                                .frame(width: 20)
                            SecureField("Xác nhận mật khẩu", text: $confirmPassword)
                                .font(.system(size: 16, design: .rounded))
                                .padding(.vertical, 12)
                                .padding(.horizontal, 10)
                        }
                        .padding(.horizontal)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .cornerRadius(15)
                        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // Register Button ^^
                        Button(action: {
                            if password == confirmPassword {
                                authVM.register(name: name, email: email, password: password) { message in
                                    DispatchQueue.main.async {
                                        if message == "Đăng ký thành công!" {
                                            isRegistered = true
                                        } else {
                                            errorMessage = message
                                        }
                                    }
                                }
                            } else {
                                errorMessage = "Mật khẩu không khớp!"
                            }
                        }) {
                            Text("Đăng Ký")
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
                                .scaleEffect(isRegistered ? 0.95 : 1.0)
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .animation(.spring(), value: isRegistered)
                        
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
                    }
                    
                    Spacer()
                }
                .animation(.easeInOut(duration: 0.3), value: errorMessage)
                .fullScreenCover(isPresented: $isRegistered) {
                    LoginView()
                        .environmentObject(taskVM)
                        .environmentObject(categoryVM)
                        .environmentObject(authVM)
                }
            }
        }
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
    let authVM = AuthViewModel()
    let userVM = UserViewModel()
    
    RegisterView()
        .environmentObject(taskVM)
        .environmentObject(CategoryViewModel())
        .environmentObject(authVM)
        .environmentObject(notificationsVM)
        .environmentObject(userVM)
        .environment(\.themeColor, .green)
}
