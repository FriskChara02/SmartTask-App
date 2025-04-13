import SwiftUI

struct LoginView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var userVM: UserViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoggedIn = false

    var body: some View {
        NavigationStack {
            if isLoggedIn {
                HomeView()
                    .environmentObject(taskVM)
                    .environmentObject(categoryVM)
                    .environmentObject(authVM) // Thêm authVM để HomeView dùng
            } else {
                VStack {
                    Text("Đăng Nhập ❀").font(.largeTitle).bold()

                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    SecureField("Mật khẩu", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: login) {
                        Text("Đăng Nhập")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()

                    Text(errorMessage).foregroundColor(.red)

                    NavigationLink("Chưa có tài khoản? Đăng ký", destination: RegisterView())
                }
                .padding()
            }
        }
    }

    func login() {
        authVM.login(email: email, password: password) { message in
            DispatchQueue.main.async {
                if authVM.isAuthenticated {
                    self.isLoggedIn = true
                    self.errorMessage = ""
                    // Lưu userId vào taskVM nếu cần
                    if let userId = authVM.currentUser?.id {
                        self.taskVM.userId = userId
                        UserDefaults.standard.set(userId, forKey: "userId")
                    }
                } else {
                    self.errorMessage = message
                }
            }
        }
    }
}

// Struct hỗ trợ decode JSON linh hoạt (giữ nguyên vì không dùng trong login mới)
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
        .environmentObject(notificationsVM) // Thêm để đồng bộ với HomeView
        .environmentObject(userVM)
}
