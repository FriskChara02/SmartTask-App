import SwiftUI

struct ManageCategoriesView: View {
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var isShowingEditSheet = false
    @State private var selectedCategory: Category?
    
    // Danh sách màu để ánh xạ từ category.color
    let colors: [(name: String, color: Color)] = [
        ("blue", .blue),
        ("purple", .purple),
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green)
    ]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    backButton
                    Spacer() // Thêm Spacer bên trái
                    Text("Manage Categories ❀")
                        .font(.title)
                        .fontWeight(.bold)
                    Spacer() // Thêm Spacer bên phải
                }
                .padding(.horizontal)
                
                headerText
                categoriesList
            }
            .sheet(isPresented: $isShowingEditSheet) {
                if let category = selectedCategory {
                    EditCategoryView(category: category)
                        .environmentObject(categoryVM)
                }
            }
        }
    }
    
    private var headerText: some View {
        Text("Categories display on homepage ⟡")
            .font(.subheadline)
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal)
    }
    
    private var categoriesList: some View {
        List {
            HStack {
                Text("All")
                    .font(.body)
                Spacer()
                Text("\(taskVM.tasks.count)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .disabled(true)
            
            ForEach(categoryVM.categories.filter { $0.name != "All" }) { category in
                CategoryRow(category: category)
            }
            createNewButton
        }
    }
    
    private func CategoryRow(category: Category) -> some View {
        HStack {
            // Hiển thị icon với màu từ category.color
            if let icon = category.icon, let colorName = category.color,
               let color = colors.first(where: { $0.name == colorName }) {
                Image(systemName: icon)
                    .foregroundColor(color.color.opacity(0.7)) // Màu nhạt hơn
                    .font(.system(size: 20))
            } else {
                Image(systemName: "questionmark.circle") // Mặc định nếu thiếu icon/color
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
            }
            
            Text(category.name)
                .font(.body)
            
            Spacer()
            
            Text("\(taskVM.tasks.filter { $0.categoryId == category.id }.count)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Menu {
                Button(action: {
                    selectedCategory = category
                    isShowingEditSheet = true
                }) {
                    Label("Edit Category", systemImage: "pencil")
                }
                
                Button(action: {
                    toggleCategoryVisibility(category: category)
                }) {
                    Label(category.isHidden == true ? "Show" : "Hide", systemImage: category.isHidden == true ? "eye" : "eye.slash")
                }
                
                Button(role: .destructive, action: {
                    deleteCategory(category: category)
                }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var createNewButton: some View {
        Button(action: {
            categoryVM.createCategory(name: "New Category", isHidden: false)
        }) {
            Text("Create New")
                .font(.body)
                .foregroundColor(.blue)
        }
    }
    
    private var backButton: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.blue)
                .font(.system(size: 20))
        }
    }
    
    private func toggleCategoryVisibility(category: Category) {
        var updatedCategory = category
        updatedCategory.isHidden = !(category.isHidden ?? false)
        categoryVM.updateCategory(category: updatedCategory)
    }
    
    private func deleteCategory(category: Category) {
        categoryVM.deleteCategory(id: category.id)
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
    ManageCategoriesView()
        .environmentObject(taskVM)
        .environmentObject(CategoryViewModel())
}
