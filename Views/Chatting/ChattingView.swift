//
//  ChattingView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 29/4/25.
//

import SwiftUI
import UIKit
import EmojiKit

struct ChattingView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var chatVM: ChattingViewModel
    @EnvironmentObject var friendVM: FriendsViewModel
    @EnvironmentObject var groupVM: GroupsViewModel
    
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    
    enum ChatTab: String, CaseIterable {
        case world = "General ✦"
        case privateChat = "Chats ❀"
        case group = "Groups ⟢"
        case smarttaskchat = "✦SmartTask✦"
        
        var icon: String {
            switch self {
            case .world: return "globe"
            case .privateChat: return "person.2"
            case .group: return "person.3"
            case .smarttaskchat: return "sparkles"
            }
        }
    }
    
    var body: some View {
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
            
            TabView {
                WorldChatView()
                    .tabItem {
                        Label(ChatTab.world.rawValue, systemImage: ChatTab.world.icon)
                    }
                    .tag(ChatTab.world)
                
                PrivateChatListView()
                    .tabItem {
                        Label(ChatTab.privateChat.rawValue, systemImage: ChatTab.privateChat.icon)
                    }
                    .tag(ChatTab.privateChat)
                
                GroupChatListView()
                    .tabItem {
                        Label(ChatTab.group.rawValue, systemImage: ChatTab.group.icon)
                    }
                    .tag(ChatTab.group)
                
                SmartTaskChatView()
                    .tabItem {
                        Label(ChatTab.smarttaskchat.rawValue, systemImage: ChatTab.smarttaskchat.icon)
                    }
                    .tag(ChatTab.smarttaskchat)
            }
            .accentColor(themeColor)
            .environmentObject(authVM)
            .environmentObject(chatVM)
            .environmentObject(friendVM)
            .environmentObject(groupVM)
            .background(
                Color(UIColor.systemBackground).opacity(0.95)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            )
            .padding(.bottom, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(themeColor.opacity(0.2), lineWidth: 1)
            )
        }
        .onAppear {
            print("DEBUG: ChattingView onAppear - currentUser: \(authVM.currentUser != nil), userId: \(authVM.currentUser?.id ?? -1)")
            if authVM.currentUser == nil {
                chatVM.alertMessage = "Vui lòng đăng nhập để sử dụng chức năng chat .ᐟ"
                chatVM.showAlert = true
            }
        }
    }
}

struct MessageListView: View {
    @ObservedObject var viewModel: ChattingViewModel
    let selectedTab: ChattingView.ChatTab
    let userId: Int?
    let friendId: Int?
    let groupId: Int?
    
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    
    var messages: [ChatMessage] {
        let allMessages: [ChatMessage]
        switch selectedTab {
        case .world:
            allMessages = viewModel.worldMessages
        case .privateChat:
            allMessages = viewModel.privateMessages
        case .group:
            allMessages = viewModel.groupMessages
        case .smarttaskchat:
            allMessages = viewModel.smartTaskMessages
        }
        
        if let searchText = viewModel.searchText, !searchText.isEmpty {
            return allMessages.filter { $0.content?.lowercased().contains(searchText.lowercased()) ?? false }
        }
        return allMessages
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(messages, id: \.id) { message in
                        MessageRow(
                            message: message,
                            isCurrentUser: message.userId == userId,
                            viewModel: viewModel,
                            selectedTab: selectedTab
                        )
                        .id(message.id)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .onAppear {
                    if let lastMessage = messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: viewModel.worldMessages) { _, _ in
                scrollToBottom(proxy: proxy, messages: viewModel.worldMessages, tab: .world)
            }
            .onChange(of: viewModel.privateMessages) { _, _ in
                scrollToBottom(proxy: proxy, messages: viewModel.privateMessages, tab: .privateChat)
            }
            .onChange(of: viewModel.groupMessages) { _, _ in
                scrollToBottom(proxy: proxy, messages: viewModel.groupMessages, tab: .group)
            }
            .onChange(of: viewModel.smartTaskMessages) { _, _ in
                scrollToBottom(proxy: proxy, messages: viewModel.smartTaskMessages, tab: .smarttaskchat)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeColor.opacity(0.05),
                        Color(UIColor.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy, messages: [ChatMessage], tab: ChattingView.ChatTab) {
        if selectedTab == tab, let lastMessage = messages.last {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

struct MessageInputView: View {
    @Binding var messageText: String
    @Binding var showEmojiPicker: Bool
    let sendAction: () -> Void
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            if showEmojiPicker {
                EmojiPicker(messageText: $messageText, showEmojiPicker: $showEmojiPicker)
                    .frame(height: 250)
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
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    .transition(.scale)
            }
            
            HStack(alignment: .center, spacing: 12) {
                Button(action: { withAnimation(.spring()) { showEmojiPicker.toggle() } }) {
                    Image(systemName: "face.smiling.fill")
                        .font(.system(size: 24, weight: .medium))
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
                        .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .scaleEffect(showEmojiPicker ? 1.1 : 1.0)
                
                TextField("Nhập tin nhắn ⟢", text: $messageText)
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
                
                Button(action: sendAction) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    messageText.isEmpty ? .gray : themeColor,
                                    messageText.isEmpty ? .gray.opacity(0.8) : themeColor.opacity(0.8)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(messageText.isEmpty)
                .scaleEffect(messageText.isEmpty ? 1.0 : 1.1)
                .animation(.spring(), value: messageText.isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.systemBackground),
                        themeColor.opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 25))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
        }
    }
}

struct MessageRow: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    @ObservedObject var viewModel: ChattingViewModel
    let selectedTab: ChattingView.ChatTab
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var showEditAlert: Bool = false
    @State private var editedContent: String = ""
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        return formatter
    }()
    
    // Map ChatTab to valid API type
    private var apiType: String {
        switch selectedTab {
        case .world:
            return "world"
        case .privateChat:
            return "private"
        case .group:
            return "group"
        case .smarttaskchat:
            return "smarttask"
        }
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if isCurrentUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 6) {
                    if message.isDeleted {
                        Text("Tin nhắn đã được thu hồi ⋆˚࿔")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .italic()
                            .foregroundColor(.gray)
                            .padding(12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [themeColor.opacity(0.5), themeColor.opacity(0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(ChatBubbleShape(isCurrentUser: true))
                            .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    } else {
                        Text(message.content ?? "Không có nội dung")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .padding(12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(ChatBubbleShape(isCurrentUser: true))
                            .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    Text(Self.timeFormatter.string(from: message.timestamp))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 8)
            } else {
                AsyncImage(url: URL(string: message.avatarURL ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: selectedTab == .smarttaskchat ? "sparkles" : "person.circle.fill")
                        .foregroundColor(.gray)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(themeColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(message.name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    if message.isDeleted {
                        Text("Tin nhắn đã được thu hồi ⋆˚࿔")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .italic()
                            .foregroundColor(.gray)
                            .padding(12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(UIColor.systemFill).opacity(0.5),
                                        Color(UIColor.systemBackground).opacity(0.5)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(ChatBubbleShape(isCurrentUser: false))
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                    } else {
                        Text(message.content ?? "Không có nội dung")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .padding(12)
                            .background(
                                LinearGradient( // Chỗ thay đổi màu cho message
                                    gradient: Gradient(colors: [
                                        Color(UIColor.systemFill),
                                        Color(UIColor.systemFill)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(ChatBubbleShape(isCurrentUser: false))
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    Text(Self.timeFormatter.string(from: message.timestamp))
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .padding(.vertical, 6)
        .contextMenu {
            if isCurrentUser {
                Button(action: {
                    guard let userId = authVM.currentUser?.id else {
                        print("❌ No userId in MessageRow")
                        viewModel.alertMessage = "Vui lòng đăng nhập để xóa tin nhắn .ᐟ"
                        viewModel.showAlert = true
                        return
                    }
                    print("DEBUG: Deleting message - userId: \(userId), messageId: \(message.messageId), type: \(apiType)")
                    ChatService.manageMessage(userId: userId, messageId: message.messageId, type: apiType, action: "delete") { success, message in
                        DispatchQueue.main.async {
                            print("DEBUG: Delete message response - Success: \(success), Message: \(message)")
                            if success {
                                viewModel.refreshMessages(for: selectedTab, userId: userId)
                            } else {
                                viewModel.alertMessage = message
                                viewModel.showAlert = true
                            }
                        }
                    }
                }) {
                    Label("Thu hồi ♺", systemImage: "trash")
                }
                Button(action: {
                    editedContent = message.content ?? "Không có nội dung"
                    showEditAlert = true
                }) {
                    Label("Chỉnh sửa ᝰ.ᐟ", systemImage: "pencil")
                }
            }
        }
        .alert("Chỉnh sửa tin nhắn ✎ᝰ", isPresented: $showEditAlert) {
            TextField("Nội dung mới ᝰ", text: $editedContent)
            Button("Hủy ⋆˚࿔", role: .cancel) { }
            Button("Lưu (*ᴗ͈ˬᴗ͈)ꕤ*.ﾟ") {
                guard let userId = authVM.currentUser?.id else {
                    print("❌ No userId in MessageRow for edit")
                    viewModel.alertMessage = "Vui lòng đăng nhập để chỉnh sửa tin nhắn .ᐟ"
                    viewModel.showAlert = true
                    return
                }
                print("DEBUG: Editing message - userId: \(userId), messageId: \(message.messageId), type: \(apiType), content: \(editedContent)")
                ChatService.manageMessage(userId: userId, messageId: message.messageId, type: apiType, action: "edit", content: editedContent) { success, message in
                    DispatchQueue.main.async {
                        print("DEBUG: Edit message response - Success: \(success), Message: \(message)")
                        if success {
                            viewModel.refreshMessages(for: selectedTab, userId: userId)
                        } else {
                            viewModel.alertMessage = message
                            viewModel.showAlert = true
                        }
                    }
                }
            }
        } message: {
            Text("Nhập nội dung mới cho tin nhắn ✧")
        }
    }
}

struct ChatBubbleShape: Shape {
    let isCurrentUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = 20
        var path = Path()
        
        if isCurrentUser {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius))
            path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.minX + cornerRadius, y: rect.minY), radius: cornerRadius)
            path.addLine(to: CGPoint(x: rect.maxX - 20, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + 20), control: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
            path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY), radius: cornerRadius)
            path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
            path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius), radius: cornerRadius)
        } else {
            path.move(to: CGPoint(x: rect.minX + 20, y: rect.minY))
            path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY + 20), control: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius))
            path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY), radius: cornerRadius)
            path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY))
            path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius), radius: cornerRadius)
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius))
            path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY), radius: cornerRadius)
        }
        path.closeSubpath()
        return path
    }
}

struct EmojiPicker: UIViewControllerRepresentable {
    @Binding var messageText: String
    @Binding var showEmojiPicker: Bool
    @Environment(\.themeColor) var themeColor
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 50, height: 50)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "EmojiCell")
        collectionView.backgroundColor = UIColor(Color(UIColor.systemBackground))
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = context.coordinator
        collectionView.delegate = context.coordinator
        
        let searchBar = UISearchBar()
        searchBar.placeholder = "Tìm emoji (ví dụ: 😊, smile)"
        searchBar.delegate = context.coordinator
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✖️", for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 20)
        closeButton.addTarget(context.coordinator, action: #selector(Coordinator.closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [searchBar, closeButton, collectionView])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor, constant: -10),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: viewController.view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            searchBar.heightAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            collectionView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        viewController.view.backgroundColor = UIColor(Color(UIColor.systemBackground))
        context.coordinator.collectionView = collectionView
        collectionView.reloadData()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.parent = self
        context.coordinator.collectionView?.reloadData()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {
        var parent: EmojiPicker
        var collectionView: UICollectionView?
        var filteredEmojis: [Emoji]
        
        init(_ parent: EmojiPicker) {
            self.parent = parent
            self.filteredEmojis = Emoji.all
            super.init()
        }

        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return filteredEmojis.count
        }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiCell
            let emoji = filteredEmojis[indexPath.item]
            cell.emojiLabel.text = emoji.char
            return cell
        }

        func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
            let emoji = filteredEmojis[indexPath.item].char
            parent.messageText += emoji
            print("✅ Selected emoji: \(emoji)")
            
            // Animation khi chọn
            if let cell = collectionView.cellForItem(at: indexPath) {
                cell.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                UIView.animate(withDuration: 0.2) {
                    cell.transform = .identity
                }
            }
        }

        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            if searchText.isEmpty {
                filteredEmojis = Emoji.all
            } else {
                let lowercasedSearch = searchText.lowercased()
                filteredEmojis = Emoji.all.filter { emoji in
                    emoji.char.lowercased().contains(lowercasedSearch) ||
                    simpleKeywordMapping[emoji.char]?.contains { keyword in
                        keyword.lowercased().contains(lowercasedSearch)
                    } ?? false
                }
            }
            print("✅ Search text: \(searchText), filtered: \(filteredEmojis.count)")
            collectionView?.reloadData()
        }
        
        let simpleKeywordMapping: [String: [String]] = [
            "😊": ["smile", "happy"], "😂": ["laugh", "funny"], "😍": ["heart", "love"], "😎": ["cool", "sunglasses"],
            "😢": ["cry", "sad"], "😡": ["angry", "mad"], "🥰": ["blush", "love"], "😴": ["sleep", "tired"],
            "🤩": ["starstruck", "excited"], "🙈": ["see no evil", "monkey"], "🙉": ["hear no evil", "monkey"],
            "🙊": ["speak no evil", "monkey"], "😺": ["cat", "smile"], "😸": ["cat", "grin"], "😻": ["cat", "love"],
            "👋": ["wave", "hello"], "👍": ["thumbs up", "good"], "👎": ["thumbs down", "bad"], "🙌": ["raised hands", "celebrate"],
            "👏": ["clap", "applause"], "💪": ["muscle", "strong"], "🤝": ["handshake", "deal"], "👊": ["fist bump", "punch"],
            "✌️": ["peace", "victory"], "🤞": ["crossed fingers", "luck"], "🙏": ["pray", "thanks"], "🤳": ["selfie", "photo"],
            "💃": ["dance", "woman"], "🕺": ["dance", "man"], "👶": ["baby", "child"], "🐶": ["dog", "puppy"],
            "🐱": ["cat", "kitten"], "🐭": ["mouse", "rodent"], "🐰": ["rabbit", "bunny"], "🦁": ["lion", "king"],
            "🐘": ["elephant", "big"], "🦒": ["giraffe", "tall"], "🦊": ["fox", "sly"], "🐻": ["bear", "teddy"],
            "🐼": ["panda", "cute"], "🌸": ["cherry blossom", "flower"], "🌹": ["rose", "flower"], "🌻": ["sunflower", "sun"],
            "🌴": ["palm tree", "tropical"], "🌈": ["rainbow", "color"], "🍎": ["apple", "fruit"], "🍐": ["pear", "fruit"],
            "🍊": ["orange", "fruit"], "🍋": ["lemon", "sour"], "🍉": ["watermelon", "fruit"], "🍕": ["pizza", "food"],
            "🍔": ["burger", "hamburger"], "🍟": ["fries", "chips"], "🍣": ["sushi", "japanese"], "🍜": ["ramen", "noodles"],
            "🍦": ["ice cream", "dessert"], "🍰": ["cake", "dessert"], "🍫": ["chocolate", "sweet"], "☕": ["coffee", "drink"],
            "🍵": ["tea", "drink"], "⚽": ["soccer", "football"], "🏀": ["basketball", "sport"], "🏈": ["football", "american"],
            "🎾": ["tennis", "sport"], "🏐": ["volleyball", "sport"], "🎳": ["bowling", "game"], "🎮": ["video game", "gaming"],
            "🎲": ["dice", "game"], "🎸": ["guitar", "music"], "🎤": ["microphone", "sing"], "🎨": ["art", "paint"],
            "📚": ["book", "read"], "✈️": ["airplane", "travel"], "🚗": ["car", "drive"], "�userId": ["bicycle", "bike"],
            "💡": ["light bulb", "idea"], "📱": ["phone", "smartphone"], "💻": ["laptop", "computer"], "⌚": ["watch", "time"],
            "📷": ["camera", "photo"], "🎁": ["gift", "present"], "🔔": ["bell", "alert"], "🔑": ["key", "lock"],
            "💸": ["money", "cash"], "📬": ["mailbox", "mail"], "🔍": ["magnifying glass", "search"], "✂️": ["scissors", "cut"],
            "🔨": ["hammer", "tool"], "🛠️": ["tools", "repair"], "⚙️": ["gear", "settings"], "❤️": ["heart", "love"],
            "💔": ["broken heart", "sad"], "⭐": ["star", "shine"], "✨": ["sparkles", "magic"], "⚡": ["lightning", "electric"],
            "🔥": ["fire", "hot"], "💥": ["explosion", "boom"], "☮️": ["peace", "symbol"], "✅": ["check", "done"],
            "❌": ["cross", "wrong"], "♻️": ["recycle", "green"], "➡️": ["right arrow", "forward"], "⬅️": ["left arrow", "back"],
            "⬆️": ["up arrow", "up"], "⬇️": ["down arrow", "down"]
        ]
        
        @objc func closeTapped() {
            parent.showEmojiPicker = false
        }
    }
}

class EmojiCell: UICollectionViewCell {
    let emojiLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        emojiLabel.font = .systemFont(ofSize: 30)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(emojiLabel)
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 50),
            emojiLabel.heightAnchor.constraint(equalToConstant: 50)
        ])
        contentView.layer.borderColor = UIColor.red.cgColor
        contentView.layer.borderWidth = 1
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#Preview {
    struct ChattingViewPreview: View {
        var body: some View {
            let authVM = AuthViewModel()
            let chatVM = ChattingViewModel()
            let friendVM = FriendsViewModel()
            let groupVM = GroupsViewModel(authVM: authVM)

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
                ),
                ChatMessage(
                    id: 2,
                    messageId: 2,
                    userId: 2,
                    name: "Friend",
                    avatarURL: nil,
                    content: "Chào bạn!",
                    timestamp: dateFormatter.date(from: "2025-05-04 10:01:00")!,
                    isEdited: false,
                    isDeleted: false
                )
            ]

            return ChattingView()
                .environmentObject(authVM)
                .environmentObject(chatVM)
                .environmentObject(friendVM)
                .environmentObject(groupVM)
                .environment(\.themeColor, .cyan)
        }
    }

    return ChattingViewPreview()
}
