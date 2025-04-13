//
//  HamburgerMenuView.swift
//  SmartTask
//

import SwiftUI

struct HamburgerMenuView: View {
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @Environment(\.themeColor) var themeColor
    
    @Binding var showMenu: Bool
    @Binding var selectedTab: String
    
    @State private var isShowingManageScreen = false
    @State private var isCategoryExpanded = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Nền mờ khi menu mở
                if showMenu {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showMenu = false
                            }
                        }
                }
                
                // Menu trượt từ trái
                VStack(alignment: .leading) {
                    Text("SmartTask")
                        .font(.title.bold())  // Thêm bold
                        .foregroundColor(.cyan)
                        .padding(.top, 50)
                        .padding(.leading, 20)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    NavigationView { // Thêm NavigationView bao quanh List
                        List {
                            // Section 1: Tasks
                            Section(header: Text("Tasks ❀").font(.headline).foregroundColor(themeColor)) {
                                MenuItem(icon: "star.fill", title: "Favorite Tasks", destination: EmptyViewWithText(text: "Favorite Tasks - Chưa triển khai"), color: .yellow)
                                MenuItem(icon: "target", title: "Habits", destination: EmptyViewWithText(text: "Habits - Chưa triển khai"), color: .green)
                                
                                // Category với Section ẩn
                                HStack(spacing: 12) {
                                    Image(systemName: "square.grid.2x2.fill")
                                        .foregroundColor(.blue)
                                        .frame(width: 30)
                                    Text("Category")
                                        .foregroundColor(.blue)
                                        .font(.headline)
                                    Spacer()
                                    Image(systemName: isCategoryExpanded ? "chevron.down" : "chevron.right")
                                        .foregroundColor(.green)
                                }
                                .padding(.vertical, 5)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isCategoryExpanded.toggle()
                                    }
                                }
                            }
                            
                            // Section ẩn: Categories
                            if isCategoryExpanded {
                                Section(header: Text("Categories ✦").font(.headline).foregroundColor(themeColor)) {
                                    
                                    // Danh sách categories
                                    if categoryVM.categories.isEmpty {
                                        Text("No categories available")
                                            .foregroundColor(.gray)
                                    } else {
                                        ForEach(categoryVM.categories) { category in
                                            HStack(spacing: 12) {
                                                Image(systemName: category.icon ?? "folder")
                                                    .foregroundColor(themeColor) // Đổi từ .blue sang themeColor
                                                    .frame(width: 30)
                                                Text(category.name)
                                                    .foregroundColor(themeColor) // Đổi từ .primary sang themeColor
                                                    .font(.body)
                                                Spacer()
                                            }
                                            .padding(.vertical, 5)
                                            .contentShape(Rectangle()) // Fill toàn bộ khung
                                            .onTapGesture {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    selectedTab = category.name
                                                    showMenu = false
                                                }
                                            }
                                        }
                                    }
                                    
                                    // Create New
                                    HStack(spacing: 12) {
                                        Image(systemName: "plus")
                                            .foregroundColor(themeColor) // Đổi từ .blue sang themeColor
                                            .frame(width: 30)
                                        Text("Create New")
                                            .foregroundColor(themeColor) // Đổi từ .primary sang themeColor
                                            .font(.body)
                                        Spacer()
                                    }
                                    .padding(.vertical, 5)
                                    .contentShape(Rectangle()) // Fill toàn bộ khung
                                    .onTapGesture {
                                        isShowingManageScreen = true
                                    }
                                }
                            }
                            
                            // Section 2: Options
                            Section(header: Text("Options ✿").font(.headline).foregroundColor(themeColor)) {
                                MenuItem(icon: "paintpalette.fill", title: "Theme", destination: ThemeView(), color: .purple)
                                MenuItem(icon: "rectangle.3.offgrid.fill", title: "Widget", destination: EmptyViewWithText(text: "Widget - Chưa triển khai"), color: .orange)
                                MenuItem(icon: "square.and.arrow.up.fill", title: "Share App", destination: ShareAppView(), color: .pink)
                                MenuItem(icon: "envelope.badge", title: "Feedback", destination: SendFeedbackView(), color: .red)
                                MenuItem(icon: "questionmark.circle", title: "FAQ", destination: FAQView(), color: .teal)
                                MenuItem(icon: "gear", title: "Settings", destination: SettingsView(), color: .gray)
                            }
                        }
                        .listStyle(InsetGroupedListStyle())
                    }
                    
                    Spacer()
                }
                .frame(width: geometry.size.width * 0.8)
                .background(Color(.systemBackground))
                .offset(x: showMenu ? 0 : -geometry.size.width * 0.8)
                .animation(.easeInOut(duration: 0.3), value: showMenu)
                .shadow(radius: 0.1)
            }
        }
        .sheet(isPresented: $isShowingManageScreen) {
            ManageCategoriesView()
                .environmentObject(taskVM)
                .environmentObject(categoryVM)
        }
    }
}

// Component cho từng mục menu
struct MenuItem<Destination: View>: View {
    var icon: String
    var title: String
    var destination: Destination
    var color: Color
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 30)
                Text(title)
                    .foregroundColor(.primary)
                    .font(.headline)
                Spacer()
            }
            .padding(.vertical, 5)
        }
    }
}

// View trắng với dòng chữ
struct EmptyViewWithText: View {
    let text: String
    
    var body: some View {
        VStack {
            Spacer()
            Text(text)
                .font(.headline)
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// Preview
#Preview {
    struct HamburgerMenuPreview: View {
        @State private var showMenu = true
        @State private var selectedTab = "All"
        let notificationsVM = NotificationsViewModel()
        let taskVM: TaskViewModel
        let categoryVM = CategoryViewModel()
        
        init() {
            taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
            categoryVM.categories = [
                Category(id: 1, name: "Work", isHidden: false, color: "blue", icon: "star"),
                Category(id: 2, name: "Birthday", isHidden: false, color: "pink", icon: "gift.fill")
            ]
        }
        
        var body: some View {
            HamburgerMenuView(showMenu: $showMenu, selectedTab: $selectedTab)
                .environmentObject(categoryVM)
                .environmentObject(taskVM)
                .environmentObject(notificationsVM)
        }
    }
    
    return HamburgerMenuPreview()
}
