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

    @Binding var selectedTaskIds: Set<Int>
    @Environment(\.dismiss) var dismiss // Để đóng sheet
    let onTaskSelected: (Int?) -> Void
    @State private var highlightedTaskId: Int? = nil
    
    var body: some View {
        NavigationView {
            List(notificationsVM.notifications) { notification in
                HStack {
                    Button(action: {
                        if let taskId = notification.taskId {
                            onTaskSelected(taskId)
                            highlightedTaskId = taskId
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                highlightedTaskId = nil
                            }
                        }
                    }) {
                        Text(notification.message)
                            .font(.body)
                            .foregroundColor(notification.isRead ? .gray : .black)
                    }
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
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Mark all as read") { notificationsVM.markAllAsRead() }
                        .foregroundColor(.blue)
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
                    }
                }
            )
        }
    }
}

private struct NotificationPreview: View {
    let notificationsVM = NotificationsViewModel()
    let taskVM: TaskViewModel

    init() {
        taskVM = TaskViewModel(notificationsVM: notificationsVM)
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
            selectedTaskIds: .constant([]),
            onTaskSelected: { _ in }
        )
        .environmentObject(taskVM)
        .environmentObject(notificationsVM)
    }
}

#Preview {
    NotificationPreview()
}
