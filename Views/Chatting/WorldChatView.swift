//
//  WorldChatView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 4/5/25.
//

import SwiftUI

struct WorldChatView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var chatVM: ChattingViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var messageText: String = ""
    @State private var showEmojiPicker: Bool = false
    @State private var isSearchFieldVisible = false
    
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
                    //TextField tìm kiếm
                    if isSearchFieldVisible {
                        TextField("Tìm kiếm tin nhắn ⟢", text: Binding(
                            get: { chatVM.searchText ?? "" },
                            set: { chatVM.searchText = $0 }
                        ))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(UIColor.systemFill),
                                        Color(UIColor.systemBackground)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(themeColor.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                    }
                    
                    MessageListView(
                        viewModel: chatVM,
                        selectedTab: .world,
                        userId: authVM.currentUser?.id,
                        friendId: nil,
                        groupId: nil
                    )
                    MessageInputView(
                        messageText: $messageText,
                        showEmojiPicker: $showEmojiPicker,
                        sendAction: sendMessage
                    )
                }
            }
            .navigationTitle("General ✦")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
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
                        
                        //Nút kính lúp
                        Button(action: {
                            withAnimation(.spring()) {
                                isSearchFieldVisible.toggle()
                            }
                        }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 12, weight: .medium))
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
                                .shadow(color: themeColor.opacity(0.3), radius: 2, x: 0, y: 1)
                        }
                        .scaleEffect(isSearchFieldVisible ? 1.1 : 1.0)
                        .animation(.spring(), value: isSearchFieldVisible)
                    }
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
                print("DEBUG: WorldChatView onAppear - userId: \(authVM.currentUser?.id ?? -1)")
                if let userId = authVM.currentUser?.id {
                    chatVM.fetchWorldMessages(userId: userId)
                } else {
                    chatVM.alertMessage = "Vui lòng đăng nhập để xem tin nhắn chung"
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
        
        chatVM.sendWorldMessage(userId: userId, content: messageText)
        messageText = ""
    }
    
    private func refreshMessages() {
        guard let userId = authVM.currentUser?.id else {
            chatVM.alertMessage = "Vui lòng đăng nhập để làm mới tin nhắn"
            chatVM.showAlert = true
            return
        }
        chatVM.fetchWorldMessages(userId: userId)
    }
}

#Preview {
    struct WorldChatViewPreview: View {
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
            
            chatVM.worldMessages = [
                ChatMessage(
                    id: 1,
                    messageId: 1,
                    userId: 1,
                    name: "Test User",
                    avatarURL: nil,
                    content: "Xin chào thế giới!",
                    timestamp: dateFormatter.date(from: "2025-05-04 10:00:00")!,
                    isEdited: false,
                    isDeleted: false
                )
            ]
            
            return WorldChatView()
                .environmentObject(authVM)
                .environmentObject(chatVM)
                .environment(\.themeColor, .cyan)
        }
    }
    
    return WorldChatViewPreview()
}
