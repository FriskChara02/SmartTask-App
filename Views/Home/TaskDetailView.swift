import SwiftUI

struct TaskDetailView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @State var task: TaskModel
    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date?
    @State private var priority: String
    @Environment(\.dismiss) var dismiss
    
    init(task: TaskModel) {
        self.task = task
        _title = State(initialValue: task.title)
        _description = State(initialValue: task.description ?? "")
        _dueDate = State(initialValue: task.dueDate)
        _priority = State(initialValue: task.priority ?? "Medium")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Thông tin công việc").font(.headline)) {
                    TextField("Tiêu đề", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    TextField("Mô tả", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("Hạn chót").font(.headline)) {
                    DatePicker("Chọn ngày giờ", selection: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(CompactDatePickerStyle())
                }
                
                Section(header: Text("Mức độ ưu tiên").font(.headline)) {
                    Picker("Ưu tiên", selection: $priority) {
                        Text("Thấp").tag("Low")
                        Text("Trung bình").tag("Medium")
                        Text("Cao").tag("High")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section {
                    Button(action: {
                        updateTask()
                    }) {
                        Text("Lưu thay đổi")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        deleteTask()
                    }) {
                        Text("Xóa công việc")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle("Chỉnh sửa công việc")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy") { dismiss() }
                }
            }
        }
    }
    
    private func updateTask() {
        task.title = title
        task.description = description
        task.dueDate = dueDate
        task.priority = priority
        taskVM.updateTask(task: task)
        dismiss()
    }
    
    private func deleteTask() {
        taskVM.deleteTask(id: task.id!)
        dismiss()
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM)
    
    TaskDetailView(task: TaskModel(
        id: 1,
        userId: nil,
        title: "Sample",
        description: "Sample description",
        categoryId: 2,
        dueDate: nil,
        isCompleted: false,
        createdAt: nil,
        priority: "Medium"  
    ))
    .environmentObject(taskVM)}
