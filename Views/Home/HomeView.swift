import SwiftUI

struct HomeView: View {
    @State private var selectedTab: Int = 0
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @EnvironmentObject var taskVM: TaskViewModel // Thêm taskVM
    @EnvironmentObject var userVM: UserViewModel

    var body: some View {
        TabView(selection: $selectedTab) {
            TaskListView()
                .environmentObject(categoryVM)
                .environmentObject(taskVM)
                .environmentObject(notificationsVM)
                .tabItem {
                    Label("Công việc", systemImage: "checklist")
                }
                .tag(0)

            CalendarView()
                .tabItem {
                    Label("Lịch", systemImage: "calendar")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Cài đặt", systemImage: "gear")
                }
                .tag(2)

            ProfileView()
                .tabItem {
                    Label("Hồ sơ", systemImage: "person.fill")
                }
                .tag(3)
        }
        .accentColor(.green)
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM)
    let userVM = UserViewModel()
    
    HomeView()
        .environmentObject(taskVM)
        .environmentObject(AuthViewModel())
        .environmentObject(CategoryViewModel())
        .environmentObject(notificationsVM)
        .environmentObject(userVM)
}
