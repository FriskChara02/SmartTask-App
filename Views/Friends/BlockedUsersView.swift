//
//  BlockedUsersView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 4/5/25.
//

import SwiftUI

struct BlockedUsersView: View {
    // MARK: - Properties
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var friendVM: FriendsViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Body
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // MARK: - Blocked Users List
                blockedUsersListView
            }
            .padding()
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark
                    ? [Color(UIColor.systemBackground).opacity(0.1), themeColor.opacity(0.1)]
                    : [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .ignoresSafeArea(.all, edges: .horizontal)
        .navigationTitle("Blocked Users ⊘")
        .overlay {
            // MARK: - Loading Overlay
            if friendVM.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: themeColor))
                    .scaleEffect(1.2)
            }
        }
        .alert(isPresented: $friendVM.showAlert) {
            // MARK: - Alert
            Alert(
                title: Text(friendVM.alertTitle)
                    .font(.system(size: 16, weight: .bold, design: .rounded)),
                message: Text(friendVM.alertMessage)
                    .font(.system(size: 14, design: .rounded)),
                dismissButton: .default(Text("OK (✿ᴗ͈ˬᴗ͈)⁾⁾"))
            )
        }
        .animation(.easeInOut(duration: 0.3), value: friendVM.isLoading)
    }

    // MARK: - Blocked Users List View
    private var blockedUsersListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text("Blocked Users (\(friendVM.blockedUsers.count)) ⚠️")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(themeColor)
                .padding(.bottom, 8)

            // Content
            if friendVM.blockedUsers.isEmpty && !friendVM.isLoading {
                Text("No blocked users .ᐟ.ᐟ")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .cornerRadius(25)
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            } else {
                ForEach(friendVM.blockedUsers) { user in
                    BlockedUserRow(
                        user: user,
                        onUnblock: { friendVM.unblockUser(userId: authVM.currentUser?.id ?? 0, blockedUserId: user.id) }
                    )
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [themeColor.opacity(0.1), Color(UIColor.systemBackground)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Blocked User Row Component
struct BlockedUserRow: View {
    let user: Friend
    let onUnblock: () -> Void
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed: Bool = false

    var body: some View {
        HStack {
            // Avatar
            if let avatarURL = user.avatarURL, let url = URL(string: avatarURL) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.gray)
                    }
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.gray)
            }

            // Information
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(user.mutualFriends != nil && user.mutualFriends! > 0 ? "\(user.mutualFriends!) mutual friends" : "No mutual friends")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Unblock Button
            Button(action: {
                onUnblock()
            }) {
                Text("Unblock ⟢")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
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
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    struct BlockedUsersViewPreview: View {
        var body: some View {
            let authVM = AuthViewModel()
            let friendVM = FriendsViewModel()
            authVM.currentUser = UserModel(id: 1, name: "Test User", email: "test@example.com", password: "password123")
            return NavigationStack {
                BlockedUsersView()
                    .environmentObject(authVM)
                    .environmentObject(friendVM)
                    .environment(\.themeColor, .cyan)
            }
        }
    }
    return BlockedUsersViewPreview()
}
