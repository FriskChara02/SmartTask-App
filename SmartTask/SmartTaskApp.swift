import SwiftUI
import AppAuth

// ✅ Định nghĩa EnvironmentKey cho themeColor
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
    @StateObject private var authVM: AuthViewModel  // ✅ Quản lý trạng thái đăng nhập
    @StateObject private var notificationsVM = NotificationsViewModel() // Khai báo trước
    @StateObject private var taskVM = TaskViewModel(notificationsVM: NotificationsViewModel(), userId: nil) // Khởi tạo với userId ban đầu là nil
    @StateObject private var categoryVM = CategoryViewModel()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var userVM = UserViewModel()
    @StateObject private var googleAuthVM: GoogleAuthViewModel // ✅ Quản lý trạng thái đăng nhập Google
    @StateObject private var calendarService = GoogleCalendarService.shared
    @StateObject private var eventVM: EventViewModel
    @StateObject private var weatherVM = WeatherViewModel()
    @StateObject private var friendVM = FriendsViewModel()
    @StateObject private var groupVM: GroupsViewModel
    @StateObject private var chatVM = ChattingViewModel()
    
    @AppStorage("themeColor") private var themeColor: String = "Blue"
    
    // Danh sách màu để ánh xạ từ themeColor
    private let colors: [(name: String, color: Color)] = [
        ("Default", .gray),
        ("Blue", .blue),
        ("Green", .green),
        ("Pink", .pink),
        ("Purple", .purple),
        ("Red", .red),
        ("Black", .black),
        ("Yellow", .yellow),
        ("Orange", .orange),
        ("Mint", .mint),
        ("Teal", .teal),
        ("Cyan", .cyan),
        ("Indigo", .indigo),
        ("Brown", .brown),
        ("White", .white)

    ]
    
    // Tính toán màu từ themeColor
    private var selectedThemeColor: Color {
        colors.first(where: { $0.name == themeColor })?.color ?? .blue // Mặc định là .blue nếu không tìm thấy
    }
    
    // ✅ Khởi tạo thủ công các StateObject phụ thuộc lẫn nhau
    init() {
        let authVMInstance = AuthViewModel()
        let googleAuthVMInstance = GoogleAuthViewModel()
        let eventVMInstance = EventViewModel(googleAuthVM: googleAuthVMInstance)
        let groupVMInstance = GroupsViewModel(authVM: authVMInstance)
        
        _authVM = StateObject(wrappedValue: authVMInstance)
        _googleAuthVM = StateObject(wrappedValue: googleAuthVMInstance)
        _eventVM = StateObject(wrappedValue: eventVMInstance)
        _groupVM = StateObject(wrappedValue: groupVMInstance)
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
                .environmentObject(eventVM)
                .environmentObject(googleAuthVM) // ✅ Truyền googleAuthVM
                .environmentObject(calendarService)
                .environmentObject(weatherVM)
                .environmentObject(friendVM)
                .environmentObject(groupVM)
                .environmentObject(chatVM)
                .onChange(of: authVM.currentUser) {
                    if let userId = authVM.currentUser?.id {
                        taskVM.userId = userId
                        taskVM.fetchTasks() // Gọi fetchTasks sau khi userId được cập nhật
                    }
                }
                .onOpenURL { url in
                    if let authFlow = calendarService.currentAuthorizationFlow, authFlow.resumeExternalUserAgentFlow(with: url) {
                        calendarService.currentAuthorizationFlow = nil
                    }
                }
        }
    }
}
