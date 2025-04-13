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
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
    let categoryVM = CategoryViewModel()
    let notificationManager = NotificationManager()
    let userVM = UserViewModel()
    let eventVM = EventViewModel()
    let authVM = AuthViewModel()
    return ContentView()
        .environmentObject(authVM)
        .environmentObject(taskVM)
        .environmentObject(categoryVM)
        .environmentObject(notificationManager)
        .environmentObject(notificationsVM)
        .environmentObject(userVM)
        .environmentObject(eventVM)
}
