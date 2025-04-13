import SwiftUI

struct HomeView: View {
    @State private var selectedTab: Int = 0
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var userVM: UserViewModel
    @EnvironmentObject var eventVM: EventViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Nội dung chính phụ thuộc vào selectedTab
            Group {
                switch selectedTab {
                case 0:
                    TaskListView()
                        .environmentObject(categoryVM)
                        .environmentObject(taskVM)
                        .environmentObject(notificationsVM)
                case 1:
                    CalendarView()
                case 2:
                    EventsView()
                case 3:
                    HealthWarningView(authVM: authVM, taskVM: taskVM, eventVM: eventVM)
                        .environmentObject(authVM)
                        .environmentObject(taskVM)
                        .environmentObject(eventVM)
                case 4:
                    SettingsView()
                case 5:
                    ProfileView()
                default:
                    Text("Tab không hợp lệ")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom TabBar (6 nút)
            HStack {
                TabBarButton(selectedTab: $selectedTab, tab: 0, label: "Công việc", systemImage: "checklist")
                TabBarButton(selectedTab: $selectedTab, tab: 1, label: "Lịch", systemImage: "calendar")
                TabBarButton(selectedTab: $selectedTab, tab: 2, label: "Sự kiện", systemImage: "cloud.sun")
                TabBarButton(selectedTab: $selectedTab, tab: 3, label: "Sức khỏe", systemImage: "heart.text.square")
                TabBarButton(selectedTab: $selectedTab, tab: 4, label: "Cài đặt", systemImage: "gear")
                TabBarButton(selectedTab: $selectedTab, tab: 5, label: "Hồ sơ", systemImage: "person.fill")
            }
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
        }
        .accentColor(.green)
    }
}

// MARK: - Custom TabBar Button
struct TabBarButton: View {
    @Binding var selectedTab: Int
    let tab: Int
    let label: String
    let systemImage: String

    var body: some View {
        Button(action: {
            selectedTab = tab
        }) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .regular))
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(selectedTab == tab ? .green : .gray)
            .padding(.horizontal, 8)
        }
    }
}

// MARK: - Preview
#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
    let userVM = UserViewModel()
    let eventVM = EventViewModel()
    let authVM = AuthViewModel()
    authVM.currentUser = UserModel(id: 7, name: "Tester01", email: "Test01", password: "123", avatarURL: nil, description: "I’m still newbie.", dateOfBirth: Date(), location: "Cat Islands", joinedDate: nil, gender: "Nam", hobbies: "Love Cats", bio: "Halo")
    authVM.isAuthenticated = true

    return HomeView()
        .environmentObject(taskVM)
        .environmentObject(authVM)
        .environmentObject(CategoryViewModel())
        .environmentObject(notificationsVM)
        .environmentObject(userVM)
        .environmentObject(eventVM)
}
