//
//  GroupChatView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 4/5/25.
//

import SwiftUI

struct GroupChatView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var chatVM: ChattingViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    let group: GroupModel
    @State private var messageText: String = ""
    @State private var showEmojiPicker: Bool = false
    
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
                
                VStack(spacing: 0) {
                    MessageListView(
                        viewModel: chatVM,
                        selectedTab: .group,
                        userId: authVM.currentUser?.id,
                        friendId: nil,
                        groupId: group.id
                    )
                    MessageInputView(
                        messageText: $messageText,
                        showEmojiPicker: $showEmojiPicker,
                        sendAction: sendMessage
                    )
                }
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: refreshMessages) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(6)
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
                    .scaleEffect(chatVM.isLoading ? 0.9 : 1.0)
                    .animation(.spring(), value: chatVM.isLoading)
                }
            }
            .alert(isPresented: $chatVM.showAlert) {
                Alert(
                    title: Text("Thông báooo ⟢"),
                    message: Text(chatVM.alertMessage),
                    dismissButton: .default(Text("OK (✿ᴗ͈ˬᴗ͈)⁾⁾")) {
                        chatVM.showAlert = false
                    }
                )
            }
            .onAppear {
                print("DEBUG: GroupChatView onAppear - userId: \(authVM.currentUser?.id ?? -1)")
                if let userId = authVM.currentUser?.id {
                    chatVM.fetchGroupMessages(userId: userId, groupId: group.id)
                    chatVM.selectedGroupId = group.id
                } else {
                    chatVM.alertMessage = "Vui lòng đăng nhập để xem tin nhắn nhóm"
                    chatVM.showAlert = true
                }
            }
        }
    }
    
    private func sendMessage() {
        guard let userId = authVM.currentUser?.id else {
            chatVM.alertMessage = "Vui lòng đăng nhập để gửi tin nhắn"
            chatVM.showAlert = true
            return
        }
        guard !messageText.isEmpty else { return }
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        chatVM.sendGroupMessage(userId: userId, groupId: group.id, content: messageText)
        messageText = ""
    }
    
    private func refreshMessages() {
        guard let userId = authVM.currentUser?.id else {
            chatVM.alertMessage = "Vui lòng đăng nhập để làm mới tin nhắn"
            chatVM.showAlert = true
            return
        }
        chatVM.fetchGroupMessages(userId: userId, groupId: group.id)
    }
}

#Preview {
    struct GroupChatViewPreview: View {
        var body: some View {
            let authVM = AuthViewModel()
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
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
            
            let group = GroupModel(
                id: 1,
                name: "Test Group",
                createdBy: 1,
                createdAt: dateFormatter.date(from: "2025-05-04 09:00:00")!,
                color: "#00FFFF",
                icon: "person.3"
            )
            
            chatVM.groupMessages = [
                ChatMessage(
                    id: 1,
                    messageId: 1,
                    userId: 1,
                    name: "Test User",
                    avatarURL: nil,
                    content: "Chào nhóm!",
                    timestamp: dateFormatter.date(from: "2025-05-04 10:00:00")!,
                    isEdited: false,
                    isDeleted: false
                )
            ]
            
            return GroupChatView(group: group)
                .environmentObject(authVM)
                .environmentObject(chatVM)
                .environment(\.themeColor, .cyan)
        }
    }
    
    return GroupChatViewPreview()
}
