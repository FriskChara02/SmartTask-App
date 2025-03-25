import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var notificationsVM: NotificationsViewModel

    var body: some View {
        if authVM.isAuthenticated {
            HomeView()
                .environmentObject(taskVM)
                .environmentObject(categoryVM)
                .environmentObject(notificationManager)
                .environmentObject(notificationsVM)
        } else {
            LoginView()
        }
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM)
    let categoryVM = CategoryViewModel()
    let notificationManager = NotificationManager()
    return ContentView()
        .environmentObject(AuthViewModel())
        .environmentObject(taskVM)
        .environmentObject(categoryVM)
        .environmentObject(notificationManager)
        .environmentObject(notificationsVM)
        .environmentObject(CategoryViewModel())
}
