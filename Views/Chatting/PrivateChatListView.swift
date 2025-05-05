//
//  PrivateChatListView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 4/5/25.
//

import SwiftUI

struct PrivateChatListView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var friendVM: FriendsViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var friends: [Friend] = []
    
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
                
                FriendListContent(
                    friends: $friends,
                    themeColor: themeColor
                )
                .background(Color(UIColor.systemBackground).opacity(0.95))
            }
            .navigationTitle("Friends ⋆˙⟡")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let userId = authVM.currentUser?.id {
                    FriendService.fetchFriends(userId: userId) { success, friends, message in
                        if success, let friends = friends {
                            self.friends = friends
                        }
                    }
                }
            }
        }
    }
}

struct FriendListContent: View {
    @Binding var friends: [Friend]
    let themeColor: Color
    
    var body: some View {
        List {
            ForEach(friends) { friend in
                NavigationLink(
                    destination: PrivateChatView(friend: friend)
                ) {
                    FriendRowView(friend: friend, themeColor: themeColor)
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

struct FriendRowView: View {
    let friend: Friend
    let themeColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: friend.avatarURL ?? "")) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.gray)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(themeColor.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(friend.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(friend.status ?? "Offline")
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
    struct PrivateChatListViewPreview: View {
        var body: some View {
            let authVM = AuthViewModel()
            let friendVM = FriendsViewModel()
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
            
            return PrivateChatListView()
                .environmentObject(authVM)
                .environmentObject(friendVM)
                .environment(\.themeColor, .cyan)
        }
    }
    
    return PrivateChatListViewPreview()
}
