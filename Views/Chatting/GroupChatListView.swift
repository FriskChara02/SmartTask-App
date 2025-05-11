//
//  GroupChatListView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 4/5/25.
//

import SwiftUI

struct GroupChatListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var groupVM: GroupsViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var groups: [GroupModel] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeColor.opacity(0.1),
                        Color(UIColor.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                GroupListContent(
                    groups: $groups,
                    themeColor: themeColor
                )
                .background(Color(UIColor.systemBackground).opacity(0.95))
            }
            .navigationTitle("Groups ⟢")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let userId = authVM.currentUser?.id, let role = authVM.currentUser?.role {
                    GroupService.fetchGroups(userId: userId, role: role) { success, groups, message in
                        if success, let groups = groups {
                            self.groups = groups
                        } else {
                            print("❌ Failed to fetch groups: \(message)")
                        }
                    }
                }
            }
        }
    }
}

struct GroupListContent: View {
    @Binding var groups: [GroupModel]
    let themeColor: Color
    
    var body: some View {
        List {
            ForEach(groups) { group in
                NavigationLink(
                    destination: GroupChatView(group: group)
                ) {
                    GroupRowView(group: group, themeColor: themeColor)
                        .padding(.vertical, 6)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(UIColor.systemFill),
                                    Color(UIColor.systemBackground)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 4)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .listStyle(.plain)
    }
}

struct GroupRowView: View {
    let group: GroupModel
    let themeColor: Color
    @EnvironmentObject var groupVM: GroupsViewModel
    @Environment(\.colorScheme) var colorScheme
    
    private let colors: [(name: String, color: Color)] = [
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
            Image(systemName: group.icon ?? "person.3")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(.white)
                .padding(10)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            (group.color != nil ? colors.first(where: { $0.name == group.color })?.color : themeColor) ?? themeColor,
                            ((group.color != nil ? colors.first(where: { $0.name == group.color })?.color : themeColor) ?? themeColor).opacity(0.8)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Total members: \(groupVM.groupMembers[group.id]?.count ?? 0) ⟢")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

#Preview {
    struct GroupChatListViewPreview: View {
        var body: some View {
            let authVM = AuthViewModel()
            let groupVM = GroupsViewModel(authVM: authVM)
            authVM.currentUser = UserModel(
                id: 1,
                name: "Test User",
                email: "test@example.com",
                password: "password123",
                avatarURL: nil,
                description: nil,
                dateOfBirth: nil,
                location: nil,
                joinedDate: nil,
                gender: nil,
                hobbies: nil,
                bio: nil,
                role: "user"
            )
            
            return GroupChatListView()
                .environmentObject(authVM)
                .environmentObject(groupVM)
                .environment(\.themeColor, .cyan)
        }
    }
    
    return GroupChatListViewPreview()
}
