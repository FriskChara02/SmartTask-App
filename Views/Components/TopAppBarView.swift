import SwiftUI

struct TopAppBarView: View {
    @Binding var showMenu: Bool
    @Binding var selectedTab: String
    
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    
    @State private var showOverflowMenu = false
    @State private var searchText = ""
    @State private var selectedTaskIds: Set<Int> = []
    @State private var isSelectingTasks = false
    @State private var showNotifications = false
    @State private var showSearchSheet = false
    
    var body: some View {
        VStack {
            HStack {
                // ☰ Hamburger Menu
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showMenu.toggle()
                    }
                }) {
                    Image(systemName: "line.horizontal.3")
                        .resizable()
                        .frame(width: 24, height: 18)
                        .foregroundColor(.primary)
                }
                .padding(.leading)
                
                // 📌 App Name (SmartTask)
                Spacer()
                Text("SmartTask")
                    .font(.headline)
                    .foregroundColor(.cyan)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showMenu.toggle()
                        }
                    }
                Spacer()
                
                // 🔔 Notification Bell
                Button(action: {
                    showNotifications = true
                    notificationsVM.fetchNotifications()
                }) {
                    ZStack {
                        Image(systemName: "bell")
                            .resizable()
                            .frame(width: 20, height: 22)
                            .foregroundColor(.yellow)
                        if notificationsVM.unreadCount > 0 {
                            Text("\(notificationsVM.unreadCount)")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 10, y: -10)
                        }
                    }
                }
                .padding(.trailing, 8)
                .sheet(isPresented: $showNotifications) {
                    NotificationView(
                        selectedTab: $selectedTab,
                        selectedTaskIds: $selectedTaskIds,
                        onTaskSelected: { taskId in
                            if let notificationId = notificationsVM.notifications.first(where: { $0.taskId == taskId })?.id {
                                notificationsVM.markAsRead(notificationId: notificationId)
                            }
                        }
                    )
                    .environmentObject(taskVM)
                    .environmentObject(notificationsVM)
                    .environmentObject(categoryVM)
                }
                
                // 🔍 Search Icon
                Button(action: { showSearchSheet = true }) {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .frame(width: 22, height: 22)
                        .foregroundColor(Color.blue)
                }
                .padding(.trailing, 8)
                .sheet(isPresented: $showSearchSheet) {
                    SearchView(selectedTab: $selectedTab)
                        .environmentObject(taskVM)
                        .environmentObject(categoryVM)
                }
                
                // ⋮ Overflow Menu
                Menu {
                    Button("Select tasks ❆", action: {
                        isSelectingTasks.toggle()
                        selectedTaskIds.removeAll()
                    })
                    Menu("Sort by ❅") {
                        Button("Due date & Time") { taskVM.tasks.sort { ($0.dueDate ?? Date.distantFuture) < ($1.dueDate ?? Date.distantFuture) }; print("Đã sắp xếp theo ngày & giờ") }
                        Button("Task create time") { taskVM.tasks.sort { ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast) }; print("Đã sắp xếp theo thời gian tạo") }
                        Button("Alphabetical A-Z") { taskVM.tasks.sort { $0.title < $1.title }; print("Đã sắp xếp A-Z") }
                        Button("Alphabetical Z-A") { taskVM.tasks.sort { $0.title > $1.title }; print("Đã sắp xếp Z-A") }
                        Button("Manual") { print("Sắp xếp thủ công - chưa hỗ trợ") }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 22, height: 5)
                        .foregroundColor(.green)
                }
                .padding(.trailing)
            }
            .frame(height: 50)
            .background(Color(.systemGray6))
            
            if isSelectingTasks && !selectedTaskIds.isEmpty {
                Button(action: {
                    taskVM.tasks.removeAll { selectedTaskIds.contains($0.id ?? -1) }
                    selectedTaskIds.removeAll()
                    isSelectingTasks = false
                }) {
                    Text("Delete \(selectedTaskIds.count) task(s)")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .transition(.move(edge: .bottom))
            }
        }
        .animation(.easeInOut, value: isSelectingTasks)
    }
}

// Hàm hỗ trợ khởi tạo dữ liệu cho Preview
private struct TopAppBarPreview: View {
    @Binding var showMenu: Bool // Thêm Binding
    @Binding var selectedTab: String
    let notificationsVM = NotificationsViewModel()
    let taskVM: TaskViewModel
    let categoryVM = CategoryViewModel()
    let notificationManager = NotificationManager()

    init(showMenu: Binding<Bool>, selectedTab: Binding<String>) { // Thêm init để nhận Binding
        self._showMenu = showMenu
        self._selectedTab = selectedTab
        taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
        taskVM.tasks = [
            TaskModel(id: 1, userId: 1, title: "Học SwiftUI", description: "Làm bài tập", categoryId: 1, dueDate: Date(), isCompleted: false, createdAt: Date(), priority: "High"),
            TaskModel(id: 2, userId: 1, title: "Mua quà", description: "Sinh nhật", categoryId: 2, dueDate: nil, isCompleted: true, createdAt: Date().addingTimeInterval(-86400), priority: "Medium")
        ]
        categoryVM.categories = [
            Category(id: 1, name: "Work", isHidden: false, color: "blue", icon: "star"),
            Category(id: 2, name: "Birthday", isHidden: false, color: "pink", icon: "gift.fill")
        ]
        notificationsVM.notifications = [
            NotificationsModel(id: UUID().uuidString, message: "Bạn đã thêm task 'Học SwiftUI' thành công", taskId: 1, isRead: false, createdAt: Date()),
            NotificationsModel(id: UUID().uuidString, message: "Bạn đã thêm task 'Mua quà' thành công", taskId: 2, isRead: false, createdAt: Date())
        ]
    }

    var body: some View {
        TopAppBarView(showMenu: $showMenu, selectedTab: $selectedTab) // Truyền showMenu vào TopAppBarView
            .environmentObject(taskVM)
            .environmentObject(categoryVM)
            .environmentObject(notificationManager)
            .environmentObject(notificationsVM)
    }
}

#Preview {
    struct TopAppBarPreviewWrapper: View {
        @State private var showMenu = false
        @State private var selectedTab = "Tab01"
        
        var body: some View {
            TopAppBarPreview(showMenu: $showMenu, selectedTab: $selectedTab)
        }
    }
    
    return TopAppBarPreviewWrapper()
}
