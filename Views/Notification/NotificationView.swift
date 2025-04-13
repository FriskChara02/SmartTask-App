//
//  NotificationView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 23/3/25.
//

import SwiftUI

struct NotificationView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @Environment(\.themeColor) var themeColor // Thêm để dùng themeColor
    @Environment(\.dismiss) var dismiss // Để đóng sheet
    
    @Binding var selectedTab: String // Thêm để điều khiển TabBarView
    @Binding var selectedTaskIds: Set<Int>
    
    let onTaskSelected: (Int?) -> Void
    
    @State private var highlightedTaskId: Int? = nil
    @State private var selectedNotificationIds: Set<String> = [] // Để tích chọn thông báo
    @State private var isSelecting: Bool = false // Chế độ chọn nhiều
    @State private var selectedNotification: NotificationsModel? // Theo dõi thông báo được chọn
    
    
    var body: some View {
        NavigationView {
            List(notificationsVM.notifications) { notification in
                notificationRow(notification: notification) // Tách thành view riêng
            }
            .listStyle(.plain) // Loại bỏ viền mặc định của List
            .navigationTitle("Notifications ❀")
            .toolbar {
                // MARK: - Toolbar Left
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(themeColor) // Dùng themeColor thay .blue
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                
                // MARK: - Toolbar Right
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if isSelecting && !selectedNotificationIds.isEmpty {
                            Button(action: {
                                notificationsVM.deleteNotifications(ids: Array(selectedNotificationIds))
                                selectedNotificationIds.removeAll()
                                isSelecting = false
                            }) {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 18))
                            }
                        }
                        
                        Button(action: {
                            isSelecting.toggle()
                            if !isSelecting { selectedNotificationIds.removeAll() }
                        }) {
                            Text(isSelecting ? "Cancel" : "Select")
                                .foregroundColor(themeColor) // Dùng themeColor thay .blue
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Button("Mark all as read") { notificationsVM.markAllAsRead() }
                            .foregroundColor(themeColor) // Dùng themeColor thay .blue
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
            .overlay(
                Group {
                    if let taskId = highlightedTaskId,
                       let task = taskVM.tasks.first(where: { $0.id == taskId }) {
                        TaskRowView(task: task, toggleAction: {})
                            .background(Color.yellow.opacity(0.3))
                            .cornerRadius(8)
                            .padding()
                            .transition(.opacity)
                            .animation(.easeInOut(duration: 0.3), value: highlightedTaskId)
                    }
                }
            )
            .overlay(
                Group {
                    if let notification = selectedNotification {
                        NotificationDetailOverlay(notification: notification) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedNotification = nil // Đóng overlay
                            }
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
            )
            .background(Color(.systemBackground).ignoresSafeArea()) // Nền tổng thể hiện đại
        }
        .environmentObject(categoryVM) // Đảm bảo categoryVM có sẵn để tìm category
    }
    
    // MARK: - Notification Row
    private func notificationRow(notification: NotificationsModel) -> some View {
        HStack {
            if isSelecting {
                Image(systemName: selectedNotificationIds.contains(notification.id) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(themeColor)
                    .onTapGesture {
                        toggleSelection(notification.id)
                    }
            }
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedNotification = notification // Hiển thị overlay
                }
            }) {
                Text(notification.message)
                    .font(.body)
                    .foregroundColor(notification.isRead ? .gray : .primary) // Dùng .primary cho Dark/Light Mode
                    .lineLimit(2)
                    .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle()) // Loại bỏ hiệu ứng mặc định
            
            Spacer()
            
            Menu {
                Button(action: { notificationsVM.deleteNotification(notificationId: notification.id) }) {
                    Label("Delete", systemImage: "trash")
                }
                Button(action: { print("Manage Notification Settings - Chưa hỗ trợ") }) {
                    Label("Manage Notification Settings", systemImage: "gear")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(themeColor)
                    .padding(.trailing, 8)
            }
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(notification.isRead ? Color(.systemBackground) : themeColor.opacity(0.1)) // Nền hiện đại
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal, 8)
    }
    
    // MARK: - Helper Functions
    private func toggleSelection(_ notificationId: String) {
        if selectedNotificationIds.contains(notificationId) {
            selectedNotificationIds.remove(notificationId)
        } else {
            selectedNotificationIds.insert(notificationId)
        }
    }
}

// Overlay hiển thị chi tiết thông báo
struct NotificationDetailOverlay: View {
    let notification: NotificationsModel
    let onDismiss: () -> Void
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var notificationsVM: NotificationsViewModel
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss) // Đóng khi nhấn ngoài
            
            VStack(spacing: 16) {
                Text(notification.message)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, 16)
                
                if let taskId = notification.taskId,
                   let task = taskVM.tasks.first(where: { $0.id == taskId }) {
                    if let description = task.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let dueDate = task.dueDate {
                        Text("Due: \(dueDate, formatter: dateFormatter)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                                        
                    HStack(spacing: 20) {
                        Text("Completed: \(task.isCompleted ? "Yes" : "No")")
                            .font(.system(size: 14))
                            .foregroundColor(task.isCompleted ? .green : .red)
                        
                        if let priority = task.priority {
                            Text(priority)
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(priorityColor(priority: priority))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
                
                Button("Close") {
                    notificationsVM.markAsRead(notificationId: notification.id)
                    onDismiss()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .padding(.bottom, 16)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            .frame(maxWidth: 300)
        }
    }
    
    private func priorityColor(priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .blue
        default: return .gray
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Preview
private struct NotificationPreview: View {
    let notificationsVM = NotificationsViewModel()
    let taskVM: TaskViewModel
    @State private var selectedTab = "All" // Thêm để preview TabBarView
    
    init() {
        taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
        taskVM.tasks = [
            TaskModel(id: 1, userId: 1, title: "Học SwiftUI", description: "Làm bài tập", categoryId: 1, dueDate: Date(), isCompleted: false, createdAt: Date(), priority: "High"),
            TaskModel(id: 2, userId: 1, title: "Mua quà", description: "Sinh nhật", categoryId: 2, dueDate: nil, isCompleted: true, createdAt: Date().addingTimeInterval(-86400), priority: "Medium")
        ]
        notificationsVM.notifications = [
            NotificationsModel(id: UUID().uuidString, message: "Bạn đã thêm task 'Học SwiftUI' thành công", taskId: 1, isRead: false, createdAt: Date()),
            NotificationsModel(id: UUID().uuidString, message: "Bạn đã thêm task 'Mua quà' thành công", taskId: 2, isRead: false, createdAt: Date())
        ]
    }

    var body: some View {
        NotificationView(
            selectedTab: $selectedTab, // Truyền binding cho selectedTab
            selectedTaskIds: .constant([]),
            onTaskSelected: { _ in }
        )
        .environmentObject(taskVM)
        .environmentObject(notificationsVM)
        .environmentObject(CategoryViewModel()) // Thêm categoryVM cho preview
    }
}

#Preview {
    NotificationPreview()
}
