import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var eventVM: EventViewModel
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                HomeView()
                    .environmentObject(taskVM)
                    .environmentObject(categoryVM)
                    .environmentObject(notificationManager)
                    .environmentObject(notificationsVM)
                    .environmentObject(userVM)
                    .environmentObject(eventVM)
            } else {
                LoginView()
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onReceive(NotificationCenter.default.publisher(for: .showLoginScreen)) { _ in
            // ^^ Chuyển về màn hình đăng nhập khi token hết hạn
            authVM.isAuthenticated = false
            print("🔐 Received showLoginScreen notification, switching to LoginView")
        }
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
    let categoryVM = CategoryViewModel()
    let notificationManager = NotificationManager()
    let userVM = UserViewModel()
    let authVM = AuthViewModel()
    let googleAuthVM = GoogleAuthViewModel()
    let eventVM = EventViewModel(googleAuthVM: googleAuthVM)
    
    ContentView()
        .environmentObject(authVM)
        .environmentObject(taskVM)
        .environmentObject(categoryVM)
        .environmentObject(notificationManager)
        .environmentObject(notificationsVM)
        .environmentObject(userVM)
        .environmentObject(eventVM)
        .environmentObject(googleAuthVM)
}
