//
//  HamburgerMenuView.swift
//  SmartTask
//

import SwiftUI

struct HamburgerMenuView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var weatherVM: WeatherViewModel
    @EnvironmentObject var friendVM: FriendsViewModel
    @EnvironmentObject var groupVM: GroupsViewModel
    @EnvironmentObject var chatVM: ChattingViewModel
    @Environment(\.themeColor) var themeColor
    
    @Binding var showMenu: Bool
    @Binding var selectedTab: String
    
    @State private var isShowingManageScreen = false
    @State private var isCategoryExpanded = false
    @State private var isSocialExpanded = false
    
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
                MenuContentView(
                    showMenu: $showMenu,
                    selectedTab: $selectedTab,
                    isShowingManageScreen: $isShowingManageScreen,
                    isCategoryExpanded: $isCategoryExpanded,
                    isSocialExpanded: $isSocialExpanded,
                    geometry: geometry
                )
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

// Tách nội dung menu thành view con để giảm độ phức tạp
struct MenuContentView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var categoryVM: CategoryViewModel
    @EnvironmentObject var taskVM: TaskViewModel
    @EnvironmentObject var friendVM: FriendsViewModel
    @EnvironmentObject var groupVM: GroupsViewModel
    @EnvironmentObject var chatVM: ChattingViewModel
    @Environment(\.themeColor) var themeColor
    
    @Binding var showMenu: Bool
    @Binding var selectedTab: String
    @Binding var isShowingManageScreen: Bool
    @Binding var isCategoryExpanded: Bool
    @Binding var isSocialExpanded: Bool
    
    let geometry: GeometryProxy
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("SmartTask")
                .font(.title.bold())
                .foregroundColor(.cyan)
                .padding(.top, 50)
                .padding(.leading, 20)
            
            // Icon Friend và nút Chatting
            HStack(spacing: 15) {
                // Icon Friend
                NavigationLink {
                    FriendsView()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.green)
                            .frame(width: 30)
                        Text("Friends")
                            .foregroundColor(.green)
                            .font(.headline)
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            
            Divider()
                .padding(.horizontal)
            
            NavigationView {
                List {
                    // Section Social
                    Section(header: Text("Social ❀").font(.headline).foregroundColor(themeColor)) {
                        // Friends
                        MenuItem(icon: "person.2.fill", title: "Friends", destination: FriendsView(), color: .blue)
                        
                        // Chat
                        MenuItem(icon: "ellipsis.message.fill", title: "Chat", destination: GroupChatListView(), color: .blue)
                        
                        // Groups với menu con
                        HStack(spacing: 12) {
                            Image(systemName: "person.3.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("Groups")
                                .foregroundColor(.blue)
                                .font(.headline)
                            Spacer()
                            Image(systemName: isSocialExpanded ? "chevron.down" : "chevron.right")
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 5)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isSocialExpanded.toggle()
                            }
                        }
                        
                        // Menu con Groups
                        if isSocialExpanded {
                            if groupVM.groups.isEmpty {
                                Text("No groups available")
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 5)
                            } else {
                                ForEach(groupVM.groups, id: \.id) { group in
                                    MenuItem(icon: "person.3.fill", title: group.name, destination: GroupsView(), color: .blue)
                                }
                            }
                            
                            // Create Group
                            MenuItem(icon: "plus", title: "Create Group", destination: ManageGroupsView(), color: .green)
                        }
                    }
                    
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
                                            .foregroundColor(themeColor)
                                            .frame(width: 30)
                                        Text(category.name)
                                            .foregroundColor(themeColor)
                                            .font(.body)
                                        Spacer()
                                    }
                                    .padding(.vertical, 5)
                                    .contentShape(Rectangle())
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
                                    .foregroundColor(themeColor)
                                    .frame(width: 30)
                                Text("Create New")
                                    .foregroundColor(themeColor)
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
            .onAppear {
                if let userId = authVM.currentUser?.id, let role = authVM.currentUser?.role {
                    groupVM.fetchGroups(userId: userId, role: role)
                }
            }
            
            Spacer()
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
        NavigationLink {
            destination
        } label: {
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

        var body: some View {
            let authVM = AuthViewModel()
            let notificationsVM = NotificationsViewModel()
            let taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
            let categoryVM = CategoryViewModel()
            let friendVM = FriendsViewModel()
            let groupVM = GroupsViewModel(authVM: authVM)
            let chatVM = ChattingViewModel()

            categoryVM.categories = [
                Category(id: 1, name: "Work", isHidden: false, color: "blue", icon: "star"),
                Category(id: 2, name: "Birthday", isHidden: false, color: "pink", icon: "gift.fill")
            ]
            
            groupVM.groups = [
                GroupModel(id: 1, name: "Project A", createdBy: 7, createdAt: Date(), color: "blue", icon: "folder"),
                GroupModel(id: 2, name: "Study Group", createdBy: 7, createdAt: Date(), color: "green", icon: "book")
            ]

            return HamburgerMenuView(showMenu: $showMenu, selectedTab: $selectedTab)
                .environmentObject(authVM)
                .environmentObject(categoryVM)
                .environmentObject(taskVM)
                .environmentObject(notificationsVM)
                .environmentObject(friendVM)
                .environmentObject(groupVM)
                .environmentObject(chatVM)
                .environmentObject(WeatherViewModel())
        }
    }

    return HamburgerMenuPreview()
}
