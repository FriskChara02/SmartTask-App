import SwiftUI
import Combine

struct TaskListView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @State private var showMenu = false
    @State private var selectedTab: String = "All"
    @State private var isAddingTask = false
    
    var body: some View {
        ZStack {
            VStack {
                TopAppBarView(showMenu: $showMenu)
                TabBarView(selectedTab: $selectedTab, selectedCategory: nil)
                
                NavigationView {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if !pendingTasks.isEmpty {
                                SectionHeaderView(title: "Công việc chưa hoàn thành")
                                ForEach(pendingTasks) { task in
                                    NavigationLink(destination: TaskDetailView(task: task)) {
                                        TaskRowView(task: task) {
                                            taskVM.toggleTaskCompletion(id: task.id!)
                                        }
                                    }
                                }
                            }
                            
                            if !completedTasks.isEmpty {
                                SectionHeaderView(title: "Đã hoàn thành")
                                ForEach(completedTasks) { task in
                                    NavigationLink(destination: TaskDetailView(task: task)) {
                                        TaskRowView(task: task) {
                                            taskVM.toggleTaskCompletion(id: task.id!)
                                        }
                                    }
                                    .opacity(0.6)
                                }
                            }
                        }
                        .padding()
                    }
                    .navigationTitle("Danh sách công việc")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: {
                                taskVM.fetchTasks()
                            }) {
                                Image(systemName: "heart.fill")
                            }
                        }
                    }
                }
                .onAppear {
                    categoryVM.fetchCategories()
                    taskVM.fetchTasks()
                }
                
                ButtonAddTasksView {
                    isAddingTask.toggle()
                }
            }
            .blur(radius: isAddingTask || showMenu ? 3 : 0) // Tùy chọn: làm mờ khi menu mở
            
            HamburgerMenuView(showMenu: $showMenu, selectedTab: $selectedTab)
                .environmentObject(categoryVM)
                .environmentObject(taskVM)
                .environmentObject(notificationsVM)
        }
        .sheet(isPresented: $isAddingTask) {
            AddTaskView()
        }
    }
    
    var pendingTasks: [TaskModel] {
        filteredTasks.filter { !$0.isCompleted } // Hiển thị tất cả task chưa hoàn thành
    }
    
    var completedTasks: [TaskModel] {
        filteredTasks.filter { $0.isCompleted }
    }
    
    var filteredTasks: [TaskModel] {
        if selectedTab == "All" {
            return taskVM.tasks
        } else {
            return taskVM.tasks.filter { task in
                categoryVM.categories.first { $0.id == task.categoryId }?.name == selectedTab
            }
        }
    }
    
    private func isToday(_ date: Date?) -> Bool {
        guard let date = date else { return false }
        return Calendar.current.isDateInToday(date)
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM)
    
    TaskListView()
        .environmentObject(taskVM)
        .environmentObject(CategoryViewModel())
        .environmentObject(notificationsVM)
}
