//
//  EditGroupView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 1/5/25.
//

import SwiftUI

struct EditGroupView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var groupsVM: GroupsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    
    let group: GroupModel
    @State private var groupName: String
    @State private var addMemberQuery = ""
    @State private var selectedColor: String
    @State private var selectedIcon: String
    @State private var selectedMember: UserModel?
    @State private var selectedMemberIds: Set<Int> = []
    
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
    let icons1 = ["person.3.fill", "star.fill", "heart.fill", "bell.fill", "bookmark.fill"]
    let icons2 = ["folder.circle.fill", "paperplane.fill", "gift.fill", "graduationcap.fill", "book.fill"]
    let icons3 = ["cup.and.saucer.fill", "list.bullet.clipboard.fill", "camera.fill", "cloud.fill", "sparkles"]
    let icons4 = ["cart.fill", "envelope.fill", "pencil.circle.fill", "house.fill", "airplane"]
    
    init(group: GroupModel) {
        self.group = group
        _groupName = State(initialValue: group.name)
        _selectedColor = State(initialValue: group.color ?? "blue")
        _selectedIcon = State(initialValue: group.icon ?? "person.3.fill")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Group Name (˶˃⤙˂˶)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))) {
                    TextField("Group Name", text: $groupName)
                        .font(.system(size: 16, design: .rounded))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(UIColor.systemBackground).opacity(0.95),
                                    themeColor.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(themeColor.opacity(0.3), lineWidth: 2)
                        )
                }
                
                ColorPickerView(selectedColor: $selectedColor, colors: colors)
                
                IconPickerView(
                    selectedIcon: $selectedIcon,
                    selectedIconColor: selectedIconColor,
                    icons1: icons1,
                    icons2: icons2,
                    icons3: icons3,
                    icons4: icons4
                )
                
                MemberPickerView(
                    selectedMemberIds: $selectedMemberIds,
                    addMemberQuery: $addMemberQuery,
                    authVM: authVM,
                    groupsVM: groupsVM,
                    group: group,
                    themeColor: themeColor
                )
                
                MembersView(
                    members: groupsVM.groupMembers[group.id] ?? [],
                    currentUserId: authVM.currentUser?.id,
                    group: group,
                    groupsVM: groupsVM,
                    authVM: authVM
                )
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
            .scrollContentBackground(.hidden)
            .navigationTitle("Edit Group ⟢")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel ⟡") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save ✦") {
                        saveGroup()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    .disabled(groupName.isEmpty)
                    .scaleEffect(groupName.isEmpty ? 0.95 : 1.0)
                    .animation(.spring(), value: groupName.isEmpty)
                }
            }
            .onAppear {
                groupsVM.fetchGroupMembers(groupId: group.id)
                if let adminId = authVM.currentUser?.id {
                    authVM.fetchAllUsers(adminId: adminId)
                }
            }
        }
    }
    
    private var selectedIconColor: Color {
        if let color = colors.first(where: { $0.name == selectedColor }) {
            return color.color.opacity(0.7)
        }
        return .gray
    }
    
    private func saveGroup() {
        groupsVM.updateGroup(groupId: group.id, name: groupName, color: selectedColor, icon: selectedIcon)
    }
}

// View cho Section Color
struct ColorPickerView: View {
    @Binding var selectedColor: String
    let colors: [(name: String, color: Color)]
    
    var body: some View {
        Section(header: Text("Color (*ᴗ͈ˬᴗ͈)ꕤ*.ﾟ")
            .font(.system(size: 16, weight: .semibold, design: .rounded))) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(colors, id: \.name) { color in
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [color.color, color.color.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 35, height: 44)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == color.name ? 3 : 0)
                                        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                                )
                                .onTapGesture {
                                    selectedColor = color.name
                                }
                            
                            if color.name == "blue" {
                                Image(systemName: "moon.stars")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                        }
                        .scaleEffect(selectedColor == color.name ? 1.1 : 1.0)
                        .animation(.spring(), value: selectedColor)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// View cho Section Icon
struct IconPickerView: View {
    @Binding var selectedIcon: String
    let selectedIconColor: Color
    let icons1: [String]
    let icons2: [String]
    let icons3: [String]
    let icons4: [String]
    
    var body: some View {
        Section(header: Text("Icon ❤︎")
            .font(.system(size: 16, weight: .semibold, design: .rounded))) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        ForEach(icons1, id: \.self) { icon in
                            iconView(icon: icon)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        ForEach(icons2, id: \.self) { icon in
                            iconView(icon: icon)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        ForEach(icons3, id: \.self) { icon in
                            iconView(icon: icon)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        ForEach(icons4, id: \.self) { icon in
                            iconView(icon: icon)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 200)
        }
    }
    
    private func iconView(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 20))
            .foregroundColor(selectedIcon == icon ? selectedIconColor : .gray)
            .frame(width: 44, height: 44)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.systemBackground).opacity(0.95),
                        selectedIcon == icon ? selectedIconColor.opacity(0.2) : Color.gray.opacity(0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(25)
            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
            .onTapGesture {
                selectedIcon = icon
            }
            .scaleEffect(selectedIcon == icon ? 1.1 : 1.0)
            .animation(.spring(), value: selectedIcon)
    }
}

// View cho Section Add Member
struct MemberPickerView: View {
    @Binding var selectedMemberIds: Set<Int>
    @Binding var addMemberQuery: String
    let authVM: AuthViewModel
    let groupsVM: GroupsViewModel
    let group: GroupModel
    let themeColor: Color
    
    private var filteredUsers: [UserModel] {
        let query = addMemberQuery.lowercased()
        let groupMembers = groupsVM.groupMembers[group.id] ?? []
        return authVM.allUsers.filter { user in
            let matchesQuery = query.isEmpty || user.name.lowercased().contains(query) || user.email.lowercased().contains(query)
            let notInGroup = !groupMembers.contains { $0.id == user.id }
            return matchesQuery && notInGroup
        }
    }
    
    var body: some View {
        Section(header: Text("Add Member ❀")
            .font(.system(size: 16, weight: .semibold, design: .rounded))) {
            TextField("Search by name or email ⌯⌲", text: $addMemberQuery)
                .font(.system(size: 16, design: .rounded))
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(UIColor.systemBackground).opacity(0.95),
                            themeColor.opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(25)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(themeColor.opacity(0.3), lineWidth: 2)
                )
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(filteredUsers) { user in
                        HStack {
                            Text("\(user.name) (\(user.email))")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: selectedMemberIds.contains(user.id) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundColor(selectedMemberIds.contains(user.id) ? themeColor : .gray)
                                .onTapGesture {
                                    if selectedMemberIds.contains(user.id) {
                                        selectedMemberIds.remove(user.id)
                                    } else {
                                        selectedMemberIds.insert(user.id)
                                    }
                                }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(UIColor.systemBackground).opacity(0.95),
                                    themeColor.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 200)
            
            Button("Add ✦") {
                if let currentUserId = authVM.currentUser?.id {
                    for userId in selectedMemberIds {
                        groupsVM.addGroupMember(groupId: group.id, userId: userId, addedBy: currentUserId)
                    }
                    selectedMemberIds.removeAll()
                    addMemberQuery = ""
                }
            }
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
            .disabled(selectedMemberIds.isEmpty)
            .scaleEffect(selectedMemberIds.isEmpty ? 0.95 : 1.0)
            .animation(.spring(), value: selectedMemberIds.isEmpty)
        }
    }
}

// View cho Section Members
struct MembersView: View {
    let members: [GroupMember]
    let currentUserId: Int?
    let group: GroupModel
    let groupsVM: GroupsViewModel
    let authVM: AuthViewModel
    
    @Environment(\.themeColor) var themeColor
    
    var body: some View {
        if !members.isEmpty {
            Section(header: Text("Members •ᴗ•")
                .font(.system(size: 16, weight: .semibold, design: .rounded))) {
                ForEach(members) { member in
                    HStack {
                        Text(member.name)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if let currentUserId = currentUserId, member.id != currentUserId,
                           (authVM.currentUser?.role == "super_admin" || (authVM.currentUser?.role == "admin" && group.createdBy == currentUserId)) {
                            Button(action: {
                                groupsVM.removeGroupMember(groupId: group.id, userId: member.id, requestingUserId: currentUserId)
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.red, .red.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(Circle())
                                    .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                themeColor.opacity(0.1),
                                Color(UIColor.systemBackground).opacity(0.95)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                }
            }
        }
    }
}

#Preview {
    struct EditGroupViewPreview: View {
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

            let testGroup = GroupModel(
                id: 1,
                name: "Test Group",
                createdBy: 1,
                createdAt: Date(),
                color: "blue",
                icon: "person.3.fill"
            )

            return EditGroupView(group: testGroup)
                .environmentObject(authVM)
                .environmentObject(groupsVM)
                .environment(\.themeColor, .cyan)
        }
    }

    return EditGroupViewPreview()
}
