import SwiftUI

struct HomeView: View {
    @State private var selectedTab: Int = 0
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @EnvironmentObject var taskVM: TaskViewModel // Thêm taskVM
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var eventVM: EventViewModel

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
            
            EventsView()
                .tabItem {
                    Label("Sự kiện", systemImage: "cloud.sun.bolt")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Cài đặt", systemImage: "gear")
                }
                .tag(3)

            ProfileView()
                .tabItem {
                    Label("Hồ sơ", systemImage: "person.fill")
                }
                .tag(4)
        }
        .accentColor(.green)
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM)
    let userVM = UserViewModel()
    let eventVM = EventViewModel()
    
    HomeView()
        .environmentObject(taskVM)
        .environmentObject(AuthViewModel())
        .environmentObject(CategoryViewModel())
        .environmentObject(notificationsVM)
        .environmentObject(userVM)
        .environmentObject(eventVM)
}
