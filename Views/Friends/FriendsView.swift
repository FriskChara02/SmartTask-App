import SwiftUI

struct FriendsView: View {
    // MARK: - Properties
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var friendVM: FriendsViewModel
    @EnvironmentObject var groupVM: GroupsViewModel
    @EnvironmentObject var chatVM: ChattingViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    
    @State private var searchText = ""
    @State private var sortOption: SortOption = .default
    @State private var isShowingStatusPicker = false
    @State private var searchWorkItem: DispatchWorkItem?

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // MARK: - Search Bar
                    searchBarView
                    
                    // MARK: - User Status
                    friendsListsView
                    
                    // MARK: - Friend Requests
                    suggestionsView
                    
                    // MARK: - Friends Lists
                    friendRequestsView
                    
                    // MARK: - Suggestions
                    userStatusView
                    
                    // MARK: - More Options
                    moreOptionsView
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
            .navigationTitle("Friends ✦")
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
            .onAppear {
                if let userId = authVM.currentUser?.id {
                    friendVM.fetchData(userId: userId)
                }
            }
        }
    }

    // MARK: - Search Bar View
    private var searchBarView: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                
                TextField("Search by name or email 🔍", text: $searchText)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .textFieldStyle(PlainTextFieldStyle())
                    .onChange(of: searchText) { oldValue, newValue in
                        searchWorkItem?.cancel()

                        let workItem = DispatchWorkItem {
                            friendVM.searchUsers(userId: authVM.currentUser?.id ?? 0, query: newValue)
                        }
                        searchWorkItem = workItem
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(UIColor.systemFill), Color(UIColor.systemBackground)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(25)
            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            
            if searchText.count > 1 && friendVM.onlineFriends.isEmpty && friendVM.offlineFriends.isEmpty && friendVM.suggestions.isEmpty && !friendVM.isLoading {
                Text("No results found ⚠︎")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .cornerRadius(25)
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - User Status View
    private var userStatusView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Status ᯽")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(themeColor)
                .padding(.bottom, 8)
            
            HStack {
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                
                Text("Status: \(friendVM.userStatus.capitalized)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: { isShowingStatusPicker.toggle() }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(themeColor)
                        .padding(8)
                        .background(Color(UIColor.systemBackground).opacity(0.95))
                        .clipShape(Circle())
                        .shadow(color: .gray.opacity(0.2), radius: 2)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(UIColor.systemBackground).opacity(0.95))
            .cornerRadius(15)
            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
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
        .sheet(isPresented: $isShowingStatusPicker) {
            StatusPickerView(
                userId: authVM.currentUser?.id ?? 0,
                selectedStatus: $friendVM.userStatus
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Friend Requests View
    private var friendRequestsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Friend Requests ⋆˚࿔ (\(friendVM.friendRequests.count))")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(themeColor)
                .padding(.bottom, 8)
            
            if friendVM.friendRequests.isEmpty && !friendVM.isLoading {
                Text("No friend requests .ᐟ.ᐟ")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .cornerRadius(25)
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            } else {
                ForEach(friendVM.friendRequests) { request in
                    FriendRequestRow(
                        request: request,
                        onAccept: {
                            friendVM.respondToFriendRequest(requestId: request.id, action: "accept")
                        },
                        onReject: {
                            friendVM.respondToFriendRequest(requestId: request.id, action: "reject")
                        }
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

    // MARK: - Friends Lists View
    private var friendsListsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Friends Lists ❀")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(themeColor)
                .padding(.bottom, 8)
            
            // Online Friends
            NavigationLink(destination: OnlineFriendsView()) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 16))
                        .foregroundColor(themeColor)
                    
                    Text("Online Friends ❆ (\(friendVM.onlineFriends.count))")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(UIColor.systemBackground), Color(UIColor.systemBackground).opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(25)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Offline Friends
            NavigationLink(destination: OfflineFriendsView()) {
                HStack {
                    Image(systemName: "person.3")
                        .font(.system(size: 16))
                        .foregroundColor(themeColor)
                    
                    Text("Offline Friends ❄︎ (\(friendVM.offlineFriends.count))")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(UIColor.systemBackground), Color(UIColor.systemBackground).opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(25)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
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

    // MARK: - Suggestions View
    private var suggestionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggestions ༄")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(themeColor)
                .padding(.bottom, 8)
            
            if friendVM.suggestions.isEmpty && !friendVM.isLoading {
                Text("No suggestions available .ᐟ.ᐟ")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .cornerRadius(25)
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            } else {
                ForEach(friendVM.suggestions) { suggestion in
                    SuggestionRow(
                        suggestion: suggestion,
                        action: {
                            friendVM.sendFriendRequest(senderId: authVM.currentUser?.id ?? 0, receiverId: suggestion.id)
                        }
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

    // MARK: - More Options View
    private var moreOptionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("More")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(themeColor)
                .padding(.bottom, 8)
            
            // Birthdays
            NavigationLink(destination: BirthdaysView()) {
                HStack {
                    Image(systemName: "app.gift.fill")
                        .font(.system(size: 16))
                        .foregroundColor(themeColor)
                    
                    Text("Birthdays 𓆩♡𓆪 (\(friendVM.birthdayFriends.count))")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.forward.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(UIColor.systemBackground), Color(UIColor.systemBackground).opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(25)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Blocked Users
            NavigationLink(destination: BlockedUsersView()) {
                HStack {
                    Image(systemName: "nosign")
                        .font(.system(size: 16))
                        .foregroundColor(themeColor)
                    
                    Text("Blocked Users ⊘ (\(friendVM.blockedUsers.count))")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.forward.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(UIColor.systemBackground), Color(UIColor.systemBackground).opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(25)
                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(PlainButtonStyle())
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

// MARK: - Friend Request Row Component
struct FriendRequestRow: View {
    let request: FriendRequest
    let onAccept: () -> Void
    let onReject: () -> Void
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var isAcceptPressed: Bool = false
    @State private var isRejectPressed: Bool = false

    var body: some View {
        HStack {
            // Avatar
            if let avatarURL = request.avatarURL, let url = URL(string: avatarURL) {
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
                Text(request.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Sent: \(request.createdAt, formatter: dateTimeFormatter)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Accept Button
            Button(action: onAccept) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
                    .padding(8)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .clipShape(Circle())
                    .shadow(color: .gray.opacity(0.2), radius: 2)
            }
            .scaleEffect(isAcceptPressed ? 0.95 : 1.0)
            .animation(.spring(), value: isAcceptPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isAcceptPressed = true }
                    .onEnded { _ in isAcceptPressed = false }
            )

            // Reject Button
            Button(action: onReject) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .clipShape(Circle())
                    .shadow(color: .gray.opacity(0.2), radius: 2)
            }
            .scaleEffect(isRejectPressed ? 0.95 : 1.0)
            .animation(.spring(), value: isRejectPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isRejectPressed = true }
                    .onEnded { _ in isRejectPressed = false }
            )
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Friend Row Component
struct FriendRow: View {
    let friend: Friend
    let onChat: () -> Void
    let onUnfriend: () -> Void
    let onBlock: () -> Void
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed: Bool = false

    var body: some View {
        HStack {
            // Avatar
            if let avatarURL = friend.avatarURL, let url = URL(string: avatarURL) {
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
                Text(friend.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(friend.mutualFriends != nil && friend.mutualFriends! > 0 ? "\(friend.mutualFriends!) mutual friends" : "No mutual friends")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status Indicator
            Circle()
                .fill(friend.status == "online" ? .green : .gray)
                .frame(width: 12, height: 12)

            // Chat Button
            NavigationLink(destination: ChattingView()) {
                Image(systemName: "ellipsis.message.fill")
                    .font(.system(size: 16))
                    .foregroundColor(themeColor)
                    .padding(8)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .clipShape(Circle())
                    .shadow(color: .gray.opacity(0.2), radius: 2)
            }

            // Menu
            Menu {
                Button(action: onUnfriend) {
                    Label("Unfriend", systemImage: "person.crop.circle.badge.xmark")
                }
                Button(action: onBlock) {
                    Label("Block", systemImage: "nosign")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .padding(8)
                    .background(Color(UIColor.systemBackground).opacity(0.95))
                    .clipShape(Circle())
                    .shadow(color: .gray.opacity(0.2), radius: 2)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Suggestion Row Component
struct SuggestionRow: View {
    let suggestion: Friend
    let action: () -> Void
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var friendVM: FriendsViewModel
    @State private var isPending = false
    @State private var isPressed: Bool = false

    var body: some View {
        HStack {
            // Avatar
            if let avatarURL = suggestion.avatarURL, let url = URL(string: avatarURL) {
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
                Text(suggestion.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text(suggestion.mutualFriends != nil && suggestion.mutualFriends! > 0 ? "\(suggestion.mutualFriends!) mutual friends" : "No mutual friends")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Add Friend or Pending Button
            if isPending {
                Text("Pending ᯓ➤")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(15)
                    .shadow(color: .gray.opacity(0.2), radius: 2)
            } else {
                Button(action: {
                    isPending = true
                    action()
                }) {
                    Text("Add Friend ⟢")
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
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Status Picker View
struct StatusPickerView: View {
    let userId: Int
    @Binding var selectedStatus: String
    @EnvironmentObject var friendVM: FriendsViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State private var isPressed: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Status")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Picker("Status", selection: $selectedStatus) {
                Text("Online ✦").tag("online")
                Text("Offline ✧").tag("offline")
                Text("Idle ⟢").tag("idle")
                Text("Do Not Disturb ⋆˚࿔").tag("dnd")
                Text("Invisible ⏾").tag("invisible")
            }
            .pickerStyle(.wheel)
            
            Button(action: {
                friendVM.updateUserStatus(userId: userId, status: selectedStatus)
                dismiss()
            }) {
                Text("Save ❀")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
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
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
        }
        .padding()
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Sort Option Enum
enum SortOption: String, CaseIterable {
    case `default`, newest, oldest
}

// MARK: - Date Formatters
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
    return formatter
}()

private let dateTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
    return formatter
}()

// MARK: - Preview
#Preview {
    struct FriendsViewPreview: View {
        var body: some View {
            let authVM = AuthViewModel()
            let friendVM = FriendsViewModel()
            let groupVM = GroupsViewModel(authVM: authVM)
            let chatVM = ChattingViewModel()

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

            return FriendsView()
                .environmentObject(authVM)
                .environmentObject(friendVM)
                .environmentObject(groupVM)
                .environmentObject(chatVM)
                .environment(\.themeColor, .cyan)
        }
    }

    return FriendsViewPreview()
}
