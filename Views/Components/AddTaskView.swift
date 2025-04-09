import SwiftUI

struct AddTaskView: View {
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategoryId: Int? = nil
    @State private var dueDate: Date? = nil
    @State private var priority: String = "Medium"
    
    var body: some View {
        NavigationView {
            Form {
                taskInfoSection
                prioritySection
                saveButtonSection
            }
            .navigationTitle("Thêm công việc ❅")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Hủy ₊⊹") { dismiss() }
                }
            }
            .onAppear {
                categoryVM.fetchCategories() // Dùng categoryVM thay vì taskVM
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("Categories loaded: \(categoryVM.categories)")
                    selectedCategoryId = categoryVM.categories.filter { $0.name != "All" }.first?.id
                }
            }
        }
    }
    
    // Sub-view cho phần "Thông tin công việc"
    private var taskInfoSection: some View {
        Section(header: Text("Thông tin công việc ❄︎")) {
            TextField("Tiêu đề", text: $title)
            TextField("Mô tả", text: $description)
            
            Picker("Danh mục", selection: $selectedCategoryId) {
                Text("Chọn danh mục").tag(nil as Int?)
                ForEach(categoryVM.categories.filter { $0.name != "All" }) { category in
                    Text(category.name).tag(category.id as Int?)
                }
            }
            
            DatePicker("Hạn chót", selection: Binding(
                get: { dueDate ?? Date() },
                set: { dueDate = $0 }
            ), displayedComponents: [.date, .hourAndMinute])
        }
    }
    
    // Sub-view cho phần "Mức độ ưu tiên"
    private var prioritySection: some View {
        Section(header: Text("Mức độ ưu tiên ⋆꙳•̩̩͙❅*̩̩͙‧͙ ‧͙*̩̩͙❆ ͙͛ ˚₊⋆")) {
            Picker("Mức độ ưu tiên", selection: $priority) {
                Text("Thấp").tag("Low")
                Text("Trung bình").tag("Medium")
                Text("Cao").tag("High")
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // Sub-view cho nút "Lưu công việc"
    private var saveButtonSection: some View {
        Section {
            Button(action: addTask) {
                Text("Lưu công việc ᯓ✦")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(LinearGradient(gradient: Gradient(colors: [.green, .teal]), startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(12)
                    .shadow(color: .primary.opacity(0.2), radius: 5, x: 0, y: 3)
            }
            .disabled(title.isEmpty || selectedCategoryId == nil)
        }
    }
    
    // Hàm thêm task
    private func addTask() {
        guard let userId = taskVM.userId else {
            print("❌ Error: userId is nil. Please log in first.")
            return
        }
        guard let categoryId = selectedCategoryId else { // Unwrap optional
            print("❌ Error: Category ID is nil.")
            return
        }
        print("✅ Adding task with title: \(title), categoryId: \(categoryId), userId: \(userId)")
        taskVM.addTask(
            title: title,
            description: description,
            categoryId: categoryId, // Đã unwrap
            dueDate: dueDate,
            priority: priority
        )
        dismiss()
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM)
    AddTaskView()
        .environmentObject(taskVM)
        .environmentObject(CategoryViewModel())
}
