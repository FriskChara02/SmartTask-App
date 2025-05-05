import Foundation

class FriendsViewModel: ObservableObject {
    @Published var onlineFriends: [Friend] = []
    @Published var offlineFriends: [Friend] = []
    @Published var friendRequests: [FriendRequest] = []
    @Published var suggestions: [Friend] = []
    @Published var birthdayFriends: [Friend] = []
    @Published var blockedUsers: [Friend] = []
    @Published var userStatus: String = "online"
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    private var searchWorkItem: DispatchWorkItem?

    init() {
        // Không dùng dữ liệu mẫu, dựa hoàn toàn vào API
    }

    func fetchData(userId: Int) {
        isLoading = true
        let group = DispatchGroup()

        // Lấy bạn bè
        group.enter()
        FriendService.fetchFriends(userId: userId) { success, friends, message in
            DispatchQueue.main.async {
                if success, let friends = friends {
                    self.onlineFriends = friends.filter { $0.status == "online" }
                    self.offlineFriends = friends.filter { $0.status != "online" }
                } else {
                    self.showAlert = true
                    self.alertTitle = "Error"
                    self.alertMessage = message
                }
                group.leave()
            }
        }

        // Lấy yêu cầu kết bạn
        group.enter()
        FriendService.fetchFriendRequests(userId: userId) { success, requests, message in
            DispatchQueue.main.async {
                if success, let requests = requests {
                    self.friendRequests = requests
                } else {
                    self.showAlert = true
                    self.alertTitle = "Error"
                    self.alertMessage = message
                }
                group.leave()
            }
        }

        // Lấy gợi ý
        group.enter()
        FriendService.fetchFriendSuggestions(userId: userId) { success, suggestions, message in
            DispatchQueue.main.async {
                if success, let suggestions = suggestions {
                    self.suggestions = suggestions
                } else {
                    self.suggestions = []
                    print("❌ Lỗi fetchFriendSuggestions: \(message)")
                }
                group.leave()
            }
        }

        // Lấy sinh nhật
        group.enter()
        FriendService.fetchBirthdayFriends(userId: userId) { success, friends, message in
            DispatchQueue.main.async {
                if success, let friends = friends {
                    self.birthdayFriends = friends
                } else {
                    self.showAlert = true
                    self.alertTitle = "Error"
                    self.alertMessage = message
                }
                group.leave()
            }
        }

        // Lấy danh sách người bị chặn
        group.enter()
        FriendService.fetchBlockedUsers(userId: userId) { success, users, message in
            DispatchQueue.main.async {
                if success, let users = users {
                    self.blockedUsers = users
                } else {
                    self.showAlert = true
                    self.alertTitle = "Error"
                    self.alertMessage = message
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.isLoading = false
        }
    }

    func searchUsers(userId: Int, query: String) {
        // Hủy công việc tìm kiếm trước đó nếu có
        searchWorkItem?.cancel()

        guard !query.isEmpty else {
            fetchData(userId: userId)
            return
        }

        // Tạo công việc tìm kiếm mới với debounce 0.5 giây
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.isLoading = true
            FriendService.searchUsers(userId: userId, query: query) { success, users, message in
                DispatchQueue.main.async {
                    if success, let users = users {
                        // ^^ Separate friends and non-friends
                        self.onlineFriends = users.filter { $0.isFriend == true && $0.status == "online" }
                        self.offlineFriends = users.filter { $0.isFriend == true && $0.status != "online" }
                        self.suggestions = users.filter { $0.isFriend == false }
                        self.birthdayFriends = []
                    } else {
                        self.showAlert = true
                        self.alertTitle = "Error"
                        self.alertMessage = message
                    }
                    self.isLoading = false
                }
            }
        }

        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    func sendFriendRequest(senderId: Int, receiverId: Int) {
        FriendService.sendFriendRequest(senderId: senderId, receiverId: receiverId) { success, message in
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertTitle = success ? "Success" : "Error"
                self.alertMessage = message
                if success {
                    // Loại bỏ người dùng khỏi danh sách gợi ý
                    self.suggestions.removeAll { $0.id == receiverId }
                }
            }
        }
    }

    func respondToFriendRequest(requestId: Int, action: String) {
        // Kiểm tra action hợp lệ
        guard ["accept", "reject"].contains(action) else {
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertTitle = "Error"
                self.alertMessage = "Hành động không hợp lệ"
            }
            return
        }

        FriendService.respondToFriendRequest(requestId: requestId, action: action) { success, friend, message in
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertTitle = success ? "Success" : "Error"
                self.alertMessage = message
                if success {
                    self.friendRequests.removeAll { $0.id == requestId }
                    if action == "accept", let newFriend = friend {
                        if newFriend.status == "online" {
                            self.onlineFriends.append(newFriend)
                        } else {
                            self.offlineFriends.append(newFriend)
                        }
                    }
                }
            }
        }
    }

    func removeFriend(userId: Int, friendId: Int, action: String) {
        // Kiểm tra action hợp lệ
        guard ["unfriend", "block"].contains(action) else {
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertTitle = "Error"
                self.alertMessage = "Hành động không hợp lệ"
            }
            return
        }

        FriendService.removeFriendOrBlock(userId: userId, friendId: friendId, action: action) { success, message in
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertTitle = success ? "Success" : "Error"
                self.alertMessage = message
                if success {
                    self.onlineFriends.removeAll { $0.id == friendId }
                    self.offlineFriends.removeAll { $0.id == friendId }
                    if action == "block" {
                        // Cập nhật lại danh sách người bị chặn
                        FriendService.fetchBlockedUsers(userId: userId) { success, users, message in
                            DispatchQueue.main.async {
                                if success, let users = users {
                                    self.blockedUsers = users
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func updateUserStatus(userId: Int, status: String) {
        // Kiểm tra trạng thái hợp lệ
        guard ["online", "offline", "idle", "dnd", "invisible"].contains(status) else {
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertTitle = "Error"
                self.alertMessage = "Trạng thái không hợp lệ"
            }
            return
        }

        FriendService.updateUserStatus(userId: userId, status: status) { success, message in
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertTitle = success ? "Success" : "Error"
                self.alertMessage = message
                if success {
                    self.userStatus = status
                }
            }
        }
    }

    func fetchBlockedUsers(userId: Int) {
        isLoading = true
        FriendService.fetchBlockedUsers(userId: userId) { success, users, message in
            DispatchQueue.main.async {
                if success, let users = users {
                    self.blockedUsers = users
                } else {
                    self.showAlert = true
                    self.alertTitle = "Error"
                    self.alertMessage = message
                }
                self.isLoading = false
            }
        }
    }

    func unblockUser(userId: Int, blockedUserId: Int) {
        FriendService.unblockUser(userId: userId, blockedUserId: blockedUserId) { success, message in
            DispatchQueue.main.async {
                self.showAlert = true
                self.alertTitle = success ? "Success" : "Error"
                self.alertMessage = message
                if success {
                    self.blockedUsers.removeAll { $0.id == blockedUserId }
                    // Cập nhật lại gợi ý để người dùng có thể xuất hiện lại
                    FriendService.fetchFriendSuggestions(userId: userId) { success, suggestions, message in
                        DispatchQueue.main.async {
                            if success, let suggestions = suggestions {
                                self.suggestions = suggestions
                            }
                        }
                    }
                }
            }
        }
    }
}
