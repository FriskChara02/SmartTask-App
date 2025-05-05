//
//  ChattingViewModel.swift
//  SmartTask
//
//  Created by Loi Nguyen on 1/5/25.
//

import Foundation

class ChattingViewModel: ObservableObject {
    @Published var worldMessages: [ChatMessage] = []
    @Published var privateMessages: [ChatMessage] = []
    @Published var groupMessages: [ChatMessage] = []
    @Published var selectedFriendId: Int?
    @Published var selectedGroupId: Int?
    @Published var showFriendPicker: Bool = false
    @Published var showGroupPicker: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var isLoading: Bool = false
    
    weak var authVM: AuthViewModel?

    init(authVM: AuthViewModel? = nil) {
        self.authVM = authVM
    }

    func fetchWorldMessages(userId: Int) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        ChatService.fetchWorldMessages(userId: userId) { success, messages, message in
            DispatchQueue.main.async {
                self.isLoading = false
                if success, let messages = messages {
                    self.worldMessages = messages.sorted(by: { $0.timestamp < $1.timestamp })
                } else {
                    self.alertMessage = message
                    self.showAlert = true
                }
            }
        }
    }

    func fetchPrivateMessages(userId: Int, friendId: Int) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        ChatService.fetchPrivateMessages(userId: userId, friendId: friendId) { success, messages, message in
            DispatchQueue.main.async {
                self.isLoading = false
                if success, let messages = messages {
                    self.privateMessages = messages.sorted(by: { $0.timestamp < $1.timestamp })
                } else {
                    self.alertMessage = message
                    self.showAlert = true
                }
            }
        }
    }

    func fetchGroupMessages(userId: Int, groupId: Int) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        ChatService.fetchGroupMessages(userId: userId, groupId: groupId) { success, messages, message in
            DispatchQueue.main.async {
                self.isLoading = false
                if success, let messages = messages {
                    self.groupMessages = messages.sorted(by: { $0.timestamp < $1.timestamp })
                } else {
                    self.alertMessage = message
                    self.showAlert = true
                }
            }
        }
    }

    func sendWorldMessage(userId: Int, content: String) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        ChatService.sendMessage(userId: userId, type: "world", content: content) { success, message in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.fetchWorldMessages(userId: userId)
                } else {
                    self.alertMessage = message
                    self.showAlert = true
                }
            }
        }
    }

    func sendPrivateMessage(userId: Int, friendId: Int, content: String) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        ChatService.checkMessageLimit(userId: userId, receiverId: friendId) { success, count, message in
            if success, count < 3 {
                ChatService.sendMessage(userId: userId, type: "private", content: content, receiverId: friendId) { success, message in
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if success {
                            self.fetchPrivateMessages(userId: userId, friendId: friendId)
                        } else {
                            self.alertMessage = message
                            self.showAlert = true
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.alertMessage = "Đã đạt giới hạn tin nhắn với người lạ!"
                    self.showAlert = true
                }
            }
        }
    }

    func sendGroupMessage(userId: Int, groupId: Int, content: String) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        ChatService.sendMessage(userId: userId, type: "group", content: content, groupId: groupId) { success, message in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    self.fetchGroupMessages(userId: userId, groupId: groupId)
                } else {
                    self.alertMessage = message
                    self.showAlert = true
                }
            }
        }
    }
    
    func refreshMessages(for tab: ChattingView.ChatTab, userId: Int) {
        DispatchQueue.main.async {
            self.isLoading = true
        }
        switch tab {
        case .world:
            fetchWorldMessages(userId: userId)
        case .privateChat:
            if let friendId = selectedFriendId {
                fetchPrivateMessages(userId: userId, friendId: friendId)
            }
        case .group:
            if let groupId = selectedGroupId {
                fetchGroupMessages(userId: userId, groupId: groupId)
            }
        case .ai:
            DispatchQueue.main.async {
                self.isLoading = false
                self.alertMessage = "Chức năng Chat với AI chưa được triển khai!"
                self.showAlert = true
            }
        }
    }
}
