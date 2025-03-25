import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: String
    let selectedCategory: Category? // Thêm tham số từ HamburgerMenuView
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    
    @State private var isShowingManageScreen = false

    var body: some View {
        HStack {
            // Thanh kéo các categories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Nút "All" cố định
                    Button(action: {
                        selectedTab = "All"
                    }) {
                        Text("All")
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(selectedTab == "All" ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(10)
                            .foregroundColor(selectedTab == "All" ? .blue : .gray)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(selectedTab == "All" ? Color.blue : Color.clear, lineWidth: 1)
                            )
                    }
                    
                    // Các danh mục động từ server, lọc bỏ "All" nếu có
                    ForEach(categoryVM.categories.filter { $0.name != "All" && $0.isHidden != true }) { category in
                        Button(action: {
                            selectedTab = category.name
                        }) {
                            Text(category.name)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(selectedTab == category.name ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(10)
                                .foregroundColor(selectedTab == category.name ? .blue : .gray)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedTab == category.name ? Color.blue : Color.clear, lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Nút "Manage Categories"
            Button(action: {
                isShowingManageScreen = true
            }) {
                Image(systemName: "fireworks")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.green)
                    .padding(.trailing, 16)
            }
            .sheet(isPresented: $isShowingManageScreen) {
                ManageCategoriesView()
                    .environmentObject(taskVM)
                    .environmentObject(categoryVM)
            }
        }
        .padding(.top)
        .onAppear {
            categoryVM.fetchCategories()
            // Đặt "All" làm mặc định nếu danh mục tải xong, hoặc chọn category từ HamburgerMenuView
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if let selectedCategory = selectedCategory {
                    selectedTab = selectedCategory.name // Ưu tiên category từ HamburgerMenuView
                } else if !categoryVM.categories.isEmpty && selectedTab.isEmpty {
                    selectedTab = "All"
                }
            }
        }
    }
}

// Struct riêng cho Preview
private struct TabBarPreview: View {
    @State private var selectedTab = "All"
    let notificationsVM = NotificationsViewModel()
    let taskVM: TaskViewModel
    let categoryVM = CategoryViewModel()
    
    init() {
        taskVM = TaskViewModel(notificationsVM: notificationsVM)
        categoryVM.categories = [
            Category(id: 1, name: "Work", isHidden: false, color: "blue", icon: "star"),
            Category(id: 2, name: "Birthday", isHidden: false, color: "pink", icon: "gift.fill")
        ]
    }
    
    var body: some View {
        TabBarView(selectedTab: $selectedTab, selectedCategory: categoryVM.categories[0])
            .environmentObject(taskVM)
            .environmentObject(categoryVM)
    }
}

#Preview {
    TabBarPreview()
}
