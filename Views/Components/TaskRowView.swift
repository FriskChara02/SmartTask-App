import SwiftUI

struct TaskRowView: View {
    let task: TaskModel
    let toggleAction: () -> Void
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    
    // Danh sách màu để ánh xạ từ category.color
    let colors: [(name: String, color: Color)] = [
        ("blue", .blue),
        ("purple", .purple),
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green),
        ("mint", .mint),
        ("teal", .teal),
        ("cyan", .cyan),
        ("indigo", .indigo),
        ("pink", .pink),
        ("brown", .brown),
        ("gray", .gray),
        ("Black", .black),
        ("White", .white)
    ]
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggleAction) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.headline)
                    .foregroundColor(.green)
                    .strikethrough(task.isCompleted, color: .green)
                
                if let categoryName = categoryName(for: task.categoryId) {
                    HStack(spacing: 4) { // Thêm HStack để đặt icon bên phải
                        Text(categoryName)
                            .font(.subheadline)
                            .foregroundColor(categoryColor(for: task.categoryId))
                        
                        if let icon = categoryIcon(for: task.categoryId) {
                            Image(systemName: icon)
                                .font(.subheadline) // Kích thước như categoryName
                                .foregroundColor(categoryColor(for: task.categoryId))
                        }
                    }
                }
                
                if let dueDate = task.dueDate {
                    Text("Hạn: \(dueDate, formatter: taskDateFormatter)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            if let priority = task.priority {
                Text(priority)
                    .font(.caption)
                    .padding(5)
                    .background(priorityColor(priority))
                    .cornerRadius(5)
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 8)
    }
    
    // Lấy tên danh mục từ categoryId
    private func categoryName(for categoryId: Int) -> String? {
        categoryVM.categories.first { $0.id == categoryId }?.name
    }
    
    // Lấy icon từ categoryId
    private func categoryIcon(for categoryId: Int) -> String? {
        categoryVM.categories.first { $0.id == categoryId }?.icon
    }
    
    // Lấy màu từ categoryId (dựa trên category.color trong database)
    private func categoryColor(for categoryId: Int) -> Color {
        if let category = categoryVM.categories.first(where: { $0.id == categoryId }),
           let colorName = category.color,
           let color = colors.first(where: { $0.name == colorName }) {
            return color.color.opacity(0.7) // Nhạt hơn như trước
        }
        return Color.gray.opacity(0.7) // Mặc định nếu không tìm thấy
    }
    
    // Màu cho mức độ ưu tiên
    private func priorityColor(_ priority: String) -> Color {
        switch priority {
        case "High": return .red
        case "Medium": return .orange
        case "Low": return .blue
        default: return .gray
        }
    }
}

let taskDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

private struct TaskRowPreview: View {
    let notificationsVM = NotificationsViewModel()
    let taskVM: TaskViewModel
    let categoryVM = CategoryViewModel()

    init() {
        taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
        taskVM.tasks = [
            TaskModel(
                id: 1,
                userId: 1,
                title: "Học SwiftUI",
                description: "Làm bài tập về SwiftUI",
                categoryId: 2,
                dueDate: Date(),
                isCompleted: false,
                createdAt: Date(),
                priority: "High"
            )
        ]
        categoryVM.categories = [
            Category(id: 2, name: "Work", isHidden: false, color: "blue", icon: "star")
        ]
    }

    var body: some View {
        TaskRowView(
            task: taskVM.tasks[0],
            toggleAction: {}
        )
        .environmentObject(taskVM)
        .environmentObject(categoryVM)
    }
}

#Preview {
    TaskRowPreview()
}
