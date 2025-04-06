//
//  SearchView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 5/4/25.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel // Thêm để tìm category
    @Environment(\.dismiss) var dismiss // Để đóng sheet
    @Binding var selectedTab: String // Thêm binding để điều khiển tab
    @State private var searchText = ""
    
    var filteredTasks: [TaskModel] {
        if searchText.isEmpty {
            return taskVM.tasks
        } else {
            return taskVM.tasks.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Thanh tìm kiếm
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 12)
                    
                    TextField("Search tasks...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 16))
                        .padding(.vertical, 10)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                                .padding(.trailing, 12)
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(25)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Danh sách kết quả
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTasks) { task in
                            TaskSearchRow(task: task) {
                                if let category = categoryVM.categories.first(where: { $0.id == task.categoryId }) {
                                    selectedTab = category.name //Cập nhật task
                                } else {
                                    selectedTab = "All" //Mặc đình về all nếu khong tìm thấy
                                }
                                dismiss() //Đóng SearchView
                            }
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                            .transition(.opacity)
                        }
                    }
                    .padding(.vertical, 10)
                }
                .animation(.easeInOut(duration: 0.5), value: filteredTasks)
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationTitle("Search")
            .navigationBarItems(leading: Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.blue)
                    .font(.system(size: 18, weight: .semibold))
            })
        }
    }
}

// View con cho mỗi task trong danh sách tìm kiếm
struct TaskSearchRow: View {
    let task: TaskModel
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let priority = task.priority {
                Text(priority)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor(priority: priority))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap) // Gọi khi nhấn
    }
    
    private func priorityColor(priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .blue
        default: return .gray
        }
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM)
    let categoryVM = CategoryViewModel()
    taskVM.tasks = [
        TaskModel(id: 1, userId: 1, title: "Học SwiftUI", description: "Làm bài tập", categoryId: 1, dueDate: Date(), isCompleted: false, createdAt: Date(), priority: "High"),
        TaskModel(id: 2, userId: 1, title: "Mua quà", description: "Sinh nhật bạn", categoryId: 2, dueDate: nil, isCompleted: true, createdAt: Date().addingTimeInterval(-86400), priority: "Medium")
    ]
    categoryVM.categories = [
        Category(id: 1, name: "Work", isHidden: false, color: "blue", icon: "star"),
        Category(id: 2, name: "Personal", isHidden: false, color: "pink", icon: "gift.fill")
    ]
    
    return SearchView(selectedTab: .constant("All"))
        .environmentObject(taskVM)
        .environmentObject(categoryVM)
}
