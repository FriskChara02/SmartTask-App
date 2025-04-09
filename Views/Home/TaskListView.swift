import SwiftUI
import Combine

struct TaskListView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.themeColor) var themeColor
    
    @State private var showMenu = false
    @State private var selectedTab: String = "All"
    @State private var isAddingTask = false
    @State private var isShowingNotifications = false
    @State private var selectedTaskIds: Set<Int> = []
    
    var body: some View {
        ZStack {
            mainContent
            HamburgerMenuView(showMenu: $showMenu, selectedTab: $selectedTab)
                .environmentObject(categoryVM)
                .environmentObject(taskVM)
                .environmentObject(notificationsVM)
            
            // Button Add Task cố định dưới cùng, không mờ
            VStack {
                Spacer()
                ButtonAddTasksView {
                    isAddingTask.toggle()
                }
                .opacity(1.0) // Không mờ
                .padding(.bottom, 20)
            }
        }
        .sheet(isPresented: $isAddingTask) {
            AddTaskView()
        }
        .onAppear {
            // Cập nhật userId từ authVM trước khi fetch
            if let userId = authVM.currentUser?.id {
                taskVM.userId = userId
            }
            categoryVM.fetchCategories()
            taskVM.fetchTasks() // Gọi fetchTasks sau khi đảm bảo userId đã được set
        }
        .onChange(of: authVM.currentUser) { oldUser, newUser in
            if let userId = newUser?.id {
                taskVM.userId = userId
                taskVM.fetchTasks()
            }
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            TopAppBarView(showMenu: $showMenu, selectedTab: $selectedTab)
            TabBarView(selectedTab: $selectedTab, selectedCategory: nil)
            taskListNavigation
        }
        .blur(radius: isAddingTask || showMenu ? 3 : 0)
    }
    
    // MARK: - Task List Navigation
    private var taskListNavigation: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    pendingTasksSection
                    completedTasksSection
                }
                .padding()
                .opacity(taskVM.isRefreshing ? 0 : 1) // Task mờ dần khi refreshing
                .animation(.easeInOut(duration: 0.5), value: taskVM.isRefreshing) // Hiệu ứng 0.5s
            }
            .navigationTitle("Danh sách công việc ✦")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack {
                        Button(action: {
                            taskVM.isRefreshing = true // Bắt đầu hiệu ứng mờ
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                taskVM.fetchTasks() // Tải lại task
                                taskVM.isRefreshing = false // Kết thúc hiệu ứng, task hiện từ từ
                            }
                        }) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(themeColor)
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingNotifications) {
                NotificationView(
                    selectedTab: $selectedTab, // Truyền selectedTab từ TaskListView
                    selectedTaskIds: $selectedTaskIds,
                    onTaskSelected: { taskId in
                        // Logic khi chọn task (nếu cần)
                        if let taskId = taskId {
                            selectedTaskIds.insert(taskId)
                        }
                    }
                )
                .environmentObject(taskVM)
                .environmentObject(notificationsVM)
                .environmentObject(categoryVM)
            }
        }
    }
    
    // MARK: - Pending Tasks Section
    private var pendingTasksSection: some View {
        Group {
            if !pendingTasks.isEmpty {
                SectionHeaderView(title: "Công việc chưa hoàn thành ❅")
                ForEach(pendingTasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        TaskRowView(task: task) {
                            taskVM.toggleTaskCompletion(task: task)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Completed Tasks Section
    private var completedTasksSection: some View {
        Group {
            if !completedTasks.isEmpty {
                SectionHeaderView(title: "Đã hoàn thành ❀")
                ForEach(completedTasks) { task in
                    NavigationLink(destination: TaskDetailView(task: task)) {
                        TaskRowView(task: task) {
                            taskVM.toggleTaskCompletion(task: task)
                        }
                    }
                    .opacity(0.6)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var pendingTasks: [TaskModel] {
        filteredTasks.filter { !$0.isCompleted }
    }
    
    private var completedTasks: [TaskModel] {
        filteredTasks.filter { $0.isCompleted }
    }
    
    private var filteredTasks: [TaskModel] {
        if selectedTab == "All" {
            return taskVM.tasks
        } else {
            return taskVM.tasks.filter { task in
                categoryVM.categories.first { $0.id == task.categoryId }?.name == selectedTab
            }
        }
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 1) // Giả định userId
    
    TaskListView()
        .environmentObject(taskVM)
        .environmentObject(CategoryViewModel())
        .environmentObject(notificationsVM)
        .environmentObject(AuthViewModel())
}
