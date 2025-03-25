import SwiftUI

@main
struct SmartTaskApp: App {
    @StateObject private var authVM = AuthViewModel()  // ✅ Quản lý trạng thái đăng nhập
    @StateObject private var notificationsVM = NotificationsViewModel() // Khai báo trước
    @StateObject private var taskVM = TaskViewModel(notificationsVM: NotificationsViewModel()) // Khởi tạo trực tiếp
    @StateObject private var categoryVM = CategoryViewModel()
    @StateObject private var notificationManager = NotificationManager()
    

    var body: some Scene {
        WindowGroup {
            ContentView()  // ✅ Dùng ContentView để xử lý điều hướng
                .environmentObject(authVM)  // ✅ Truyền authVM xuống toàn bộ app
                .environmentObject(taskVM)
                .environmentObject(categoryVM)
                .environmentObject(notificationManager)
                .environmentObject(notificationsVM)
        }
    }
}
