//
//  ManageGroupsView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 29/4/25.
//

import SwiftUI

struct ManageGroupsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var groupsVM: GroupsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var showingCreateGroup = false
    @State private var selectedGroup: GroupModel?
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        backButton
                        Spacer()
                        Text("Manage Groups ❀")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    headerText
                    groupsList
                }
                .padding(.vertical)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeColor.opacity(0.1),
                        Color(UIColor.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateGroup = true }) {
                        Image(systemName: "pencil.tip.crop.circle.badge.plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .scaleEffect(showingCreateGroup ? 0.95 : 1.0)
                    .animation(.spring(), value: showingCreateGroup)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done˚｡⋆") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
                    .environmentObject(authVM)
                    .environmentObject(groupsVM)
            }
            .sheet(item: $selectedGroup) { group in
                EditGroupView(group: group)
                    .environmentObject(authVM)
                    .environmentObject(groupsVM)
            }
            .onAppear {
                if let userId = authVM.currentUser?.id {
                    groupsVM.fetchGroups(userId: userId, role: authVM.currentUser?.role ?? "user")
                }
            }
        }
    }
    
    private var headerText: some View {
        Text("Groups you manage or participate in ⟡")
            .font(.system(size: 14, design: .rounded))
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal)
    }
    
    private var groupsList: some View {
        VStack(spacing: 12) {
            if groupsVM.isLoading {
                ProgressView()
                    .padding()
            } else if groupsVM.groups.isEmpty {
                Text("No groups available ⭑.ᐟ")
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ForEach(groupsVM.groups) { group in
                    GroupRow(group: group, selectedGroup: $selectedGroup)
                        .animation(.easeInOut, value: groupsVM.groups)
                }
                createNewButton
            }
        }
    }
    
    private func GroupRow(group: GroupModel, selectedGroup: Binding<GroupModel?>) -> some View {
        let canEdit = authVM.currentUser?.role == "super_admin" ||
            (authVM.currentUser?.role == "admin" && group.createdBy == authVM.currentUser?.id)

        return HStack {
            if let colorName = group.color,
               let color = colors.first(where: { $0.name == colorName }) {
                Image(systemName: group.icon ?? "person.3")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [color.color, color.color.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.3")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(10)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Circle())
            }

            Text(group.name)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.primary)

            Spacer()

            Text("\(groupsVM.groupMembers[group.id]?.count ?? 0)")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(25)

            if canEdit {
                Menu {
                    Button(action: {
                        selectedGroup.wrappedValue = group
                    }) {
                        Label("Edit Group ✦︎", systemImage: "applepencil.and.scribble")
                    }

                    Button(role: .destructive, action: {
                        if let userId = authVM.currentUser?.id {
                            groupsVM.deleteGroup(groupId: group.id, userId: userId)
                        }
                    }) {
                        Label("Delete ⟡", systemImage: "trash.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    themeColor.opacity(0.2),
                    Color(UIColor.systemBackground).opacity(0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .onAppear {
            print("DEBUG: GroupRow for group \(group.id) - canEdit=\(canEdit), userRole=\(authVM.currentUser?.role ?? "nil"), userId=\(authVM.currentUser?.id ?? -1), createdBy=\(group.createdBy)")
        }
        .swipeActions(edge: .trailing) {
            if canEdit {
                Button(role: .destructive) {
                    if let userId = authVM.currentUser?.id {
                        groupsVM.deleteGroup(groupId: group.id, userId: userId)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    private var createNewButton: some View {
        Button(action: {
            showingCreateGroup = true
        }) {
            Text("Create New ❆")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(25)
                .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal)
        .scaleEffect(showingCreateGroup ? 0.95 : 1.0)
        .animation(.spring(), value: showingCreateGroup)
    }
    
    private var backButton: some View {
        Button(action: {
            dismiss()
        }) {
            Image(systemName: "chevron.backward.circle")
                .font(.system(size: 20))
                .foregroundColor(.white)
                .padding(5)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
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
}

#Preview {
    struct ManageGroupsViewPreview: View {
        var body: some View {
            let authVM = AuthViewModel()
            let groupsVM = GroupsViewModel(authVM: authVM)

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
                role: "admin"
            )

            return ManageGroupsView()
                .environmentObject(authVM)
                .environmentObject(groupsVM)
                .environment(\.themeColor, .cyan)
        }
    }

    return ManageGroupsViewPreview()
}
