//
//  GroupsView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 29/4/25.
//

import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var groupVM: GroupsViewModel
    @EnvironmentObject var friendVM: FriendsViewModel
    @EnvironmentObject var chatVM: ChattingViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var isShowingManageGroups = false
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    if let errorMessage = groupVM.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.red)
                            .padding()
                    }
                    if groupVM.isLoading {
                        ProgressView()
                            .padding()
                    } else if groupVM.groups.isEmpty {
                        Text("「 ✦ No groups available ✦ 」")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(groupVM.groups) { group in
                            NavigationLink(destination: TaskListGroupView(groupId: group.id)) {
                                HStack {
                                    Image(systemName: group.icon ?? "person.3")
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
                                    
                                    Text(group.name)
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.up.chevron.right.chevron.down.chevron.left")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
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
                                .scaleEffect(1.0)
                                .animation(.spring(), value: groupVM.groups)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
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
            .navigationTitle("Groups ✦")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingManageGroups = true }) {
                        Image(systemName: "person.2.badge.gearshape")
                            .font(.system(size: 14, weight: .semibold))
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
                    .scaleEffect(isShowingManageGroups ? 0.95 : 1.0)
                    .animation(.spring(), value: isShowingManageGroups)
                }
            }
            .sheet(isPresented: $isShowingManageGroups) {
                ManageGroupsView()
                    .environmentObject(authVM)
            }
            .onAppear {
                print("DEBUG: GroupsView onAppear - authVM.currentUser = \(String(describing: authVM.currentUser))")
                if let userId = authVM.currentUser?.id, let role = authVM.currentUser?.role {
                    print("DEBUG: Fetching groups for userId=\(userId), role=\(role)")
                    groupVM.fetchGroups(userId: userId, role: role)
                } else {
                    print("DEBUG: No userId or role available for fetching groups")
                    groupVM.errorMessage = "Vui lòng đăng nhập để xem danh sách nhóm ᝰ.ᐟ"
                }
            }
        }
    }
}

#Preview {
    PreviewContainer()
}

private struct PreviewContainer: View {
    var body: some View {
        let authVM = AuthViewModel()
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
            bio: nil
        )
        
        let groupVM = GroupsViewModel(authVM: authVM)
        let friendVM = FriendsViewModel()
        let chatVM = ChattingViewModel()

        return GroupsView()
            .environmentObject(authVM)
            .environmentObject(groupVM)
            .environmentObject(friendVM)
            .environmentObject(chatVM)
            .environment(\.themeColor, .cyan)
    }
}
