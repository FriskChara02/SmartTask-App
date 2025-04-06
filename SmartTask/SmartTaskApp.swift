import SwiftUI

//EnvironmentKey cho themeColor
private struct ThemeColorKey: EnvironmentKey {
    static let defaultValue: Color = .blue
}

extension EnvironmentValues {
    var themeColor: Color {
        get { self[ThemeColorKey.self] }
        set { self[ThemeColorKey.self] = newValue }
    }
}

@main
struct SmartTaskApp: App {
    @StateObject private var authVM = AuthViewModel()  // ✅ Quản lý trạng thái đăng nhập
    @StateObject private var notificationsVM = NotificationsViewModel() // Khai báo trước
    @StateObject private var taskVM = TaskViewModel(notificationsVM: NotificationsViewModel()) // Khởi tạo trực tiếp
    @StateObject private var categoryVM = CategoryViewModel()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var userVM = UserViewModel()
    
    @AppStorage("themeColor") private var themeColor: String = "Blue" // Thêm AppStorage
    
    // Danh sách màu để ánh xạ từ themeColor
        private let colors: [(name: String, color: Color)] = [
            ("Default", .gray),
            ("Blue", .blue), ("Green", .green), ("Pink", .pink), ("Purple", .purple),
            ("Red", .red), ("Black", .black), ("Yellow", .yellow), ("Orange", .orange)
        ]
        
        // Tính toán màu từ themeColor
        private var selectedThemeColor: Color {
            colors.first(where: { $0.name == themeColor })?.color ?? .blue // Mặc định là .blue nếu không tìm thấy
        }

    var body: some Scene {
        WindowGroup {
            ContentView()  // ✅ Dùng ContentView để xử lý điều hướng
                .environmentObject(authVM)  // ✅ Truyền authVM xuống toàn bộ app
                .environmentObject(taskVM)
                .environmentObject(categoryVM)
                .environmentObject(notificationManager)
                .environmentObject(notificationsVM)
                .environmentObject(userVM)
                .environment(\.themeColor, selectedThemeColor)
        }
    }
}
