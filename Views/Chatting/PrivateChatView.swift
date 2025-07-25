//
//  PrivateChatView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 4/5/25.
//

import SwiftUI

struct PrivateChatView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var chatVM: ChattingViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    let friend: Friend
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
                        selectedTab: .privateChat,
                        userId: authVM.currentUser?.id,
                        friendId: friend.id,
                        groupId: nil
                    )
                    MessageInputView(
                        messageText: $messageText,
                        showEmojiPicker: $showEmojiPicker,
                        sendAction: sendMessage
                    )
                }
            }
            .navigationTitle(friend.name)
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
                print("DEBUG: PrivateChatView onAppear - userId: \(authVM.currentUser?.id ?? -1)")
                if let userId = authVM.currentUser?.id {
                    chatVM.fetchPrivateMessages(userId: userId, friendId: friend.id)
                    chatVM.selectedFriendId = friend.id
                } else {
                    chatVM.alertMessage = "Vui lòng đăng nhập để xem tin nhắn riêng"
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
        
        chatVM.sendPrivateMessage(userId: userId, friendId: friend.id, content: messageText)
        messageText = ""
    }
    
    private func refreshMessages() {
        guard let userId = authVM.currentUser?.id else {
            chatVM.alertMessage = "Vui lòng đăng nhập để làm mới tin nhắn"
            chatVM.showAlert = true
            return
        }
        chatVM.fetchPrivateMessages(userId: userId, friendId: friend.id)
    }
}

#Preview {
    EmptyView()
}
