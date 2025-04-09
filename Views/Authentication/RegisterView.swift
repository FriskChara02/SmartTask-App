import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authVM: AuthViewModel // Sửa thành EnvironmentObject
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var userVM: UserViewModel
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isRegistered = false // ✅ Trạng thái đăng ký thành công

    var body: some View {
        NavigationStack {
            VStack {
                Text("Đăng Ký ❅").font(.largeTitle).bold()

                TextField("Họ và tên", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                SecureField("Mật khẩu", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                SecureField("Xác nhận mật khẩu", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

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
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                Text(errorMessage).foregroundColor(.red)
            }
            .padding()
            .fullScreenCover(isPresented: $isRegistered) {
                LoginView()
                    .environmentObject(taskVM)
                    .environmentObject(categoryVM)
                    .environmentObject(authVM) // Thêm authVM
            }
        }
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM)
    let authVM = AuthViewModel()
    let userVM = UserViewModel()
    
    RegisterView()
        .environmentObject(taskVM)
        .environmentObject(CategoryViewModel())
        .environmentObject(authVM)
        .environmentObject(notificationsVM) // Thêm để đồng bộ
        .environmentObject(userVM)
        
}
