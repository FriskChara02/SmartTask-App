//
//  OfflineFriendsView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 4/5/25.
//

import SwiftUI

struct OfflineFriendsView: View {
    // MARK: - Properties
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var friendVM: FriendsViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var sortOption: SortOption = .default

    // MARK: - Body
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // MARK: - Offline Friends List
                offlineFriendsListView
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
        .navigationTitle("Offline Friends ᶻ 𝗓 𐰁")
        .toolbar {
            // MARK: - Sort Toolbar
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Sort", selection: $sortOption) {
                        Text("Default").tag(SortOption.default)
                        Text("Newest").tag(SortOption.newest)
                        Text("Oldest").tag(SortOption.oldest)
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(themeColor)
                }
            }
        }
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

    // MARK: - Offline Friends List View
    private var offlineFriendsListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text("Offline Friends ❄︎ (\(friendVM.offlineFriends.count))")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(themeColor)
                .padding(.bottom, 8)

            // Content
            if friendVM.offlineFriends.isEmpty && !friendVM.isLoading {
                Text("No offline friends .ᐟ")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .cornerRadius(25)
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            } else {
                ForEach(sortedFriends(friendVM.offlineFriends)) { friend in
                    FriendRow(
                        friend: friend,
                        onChat: { /* Chuyển sang ChattingView */ },
                        onUnfriend: { friendVM.removeFriend(userId: authVM.currentUser?.id ?? 0, friendId: friend.id, action: "unfriend") },
                        onBlock: { friendVM.removeFriend(userId: authVM.currentUser?.id ?? 0, friendId: friend.id, action: "block") }
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

    // MARK: - Sort Friends
    private func sortedFriends(_ friends: [Friend]) -> [Friend] {
        switch sortOption {
        case .default:
            return friends.sorted { $0.name < $1.name }
        case .newest:
            return friends.sorted { ($0.createdAt ?? Date()) > ($1.createdAt ?? Date()) }
        case .oldest:
            return friends.sorted { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }
        }
    }
}

// MARK: - Preview
#Preview {
    struct OfflineFriendsViewPreview: View {
        var body: some View {
            let authVM = AuthViewModel()
            let friendVM = FriendsViewModel()
            authVM.currentUser = UserModel(id: 1, name: "Test User", email: "test@example.com", password: "password123")
            return NavigationStack {
                OfflineFriendsView()
                    .environmentObject(authVM)
                    .environmentObject(friendVM)
                    .environment(\.themeColor, .cyan)
            }
        }
    }
    return OfflineFriendsViewPreview()
}
