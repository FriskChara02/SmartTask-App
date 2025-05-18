//
//  GroupsView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 29/4/25.
//

import SwiftUI

struct GroupsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var groupVM: GroupsViewModel
    @EnvironmentObject var friendVM: FriendsViewModel
    @EnvironmentObject var chatVM: ChattingViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isShowingManageGroups = false
    @State private var searchText = ""
    @State private var isSearchFieldVisible = false
    
    @AppStorage("themeColor") private var themeColorStorage: String = ""
    @AppStorage("themeTexture") private var themeTexture: String = ""
    @AppStorage("themeScenery") private var themeScenery: String = ""
    @AppStorage("customPhotoData") private var customPhotoData: Data?
    
    private let colors: [(name: String, color: Color)] = [
        ("Default", .gray), ("Blue", .blue), ("Green", .green), ("Pink", .pink),
        ("Purple", .purple), ("Red", .red), ("Black", .black), ("Yellow", .yellow),
        ("Orange", .orange), ("Mint", .mint), ("Teal", .teal), ("Cyan", .cyan),
        ("Indigo", .indigo), ("Brown", .brown), ("White", .white)
    ]
    
    private let textures: [(name: String, gradient: Gradient?)] = [
        ("Default", nil),
        ("Sunset Gradient", Gradient(colors: [.orange, .pink, .purple])),
        ("Ocean Gradient", Gradient(colors: [.blue, .cyan, .teal])),
        ("Forest Gradient", Gradient(colors: [.green, .mint, .brown])),
        ("Twilight Glow", Gradient(colors: [.purple, .indigo, .blue])),
        ("Desert Heat", Gradient(colors: [.red, .orange, .yellow])),
        ("Aurora", Gradient(colors: [.cyan, .green, .blue])),
        ("Candy Pop", Gradient(colors: [.pink, .cyan, .yellow])),
        ("Midnight", Gradient(colors: [.black, .indigo, .gray])),
        ("Spring Bloom", Gradient(colors: [.mint, .pink, .white])),
        ("Golden Hour", Gradient(colors: [.yellow, .orange, .red])),
        ("Frost", Gradient(colors: [.white, .cyan, .blue]))
    ]

    private let sceneries: [(name: String, imageName: String?)] = [
        ("Default", nil),
        ("Tekapo Lake", "Tekapo Lake"),
        ("Meadow", "meadow-with-trees-wooden-fence"),
        ("Wet Vietnam", "wet-vietnam-mountain-flow-stream-rural"),
        (" Cascade", "cascade-boat-clean-china-natural-rural"),
        ("Fuji", "fuji-mountain-kawaguchiko-lake-sunset-autumn-seasons-fuji-mountain-yamanachi-japan")
    ]
    
    private var filteredGroups: [GroupModel] {
            if searchText.isEmpty {
                return groupVM.groups
            } else {
                return groupVM.groups.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            }
        }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    if isSearchFieldVisible {
                            TextField("Tìm kiếm nhóm ⟢", text: $searchText)
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
                    
                    if let errorMessage = groupVM.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.red)
                            .padding()
                    }
                    if groupVM.isLoading {
                        ProgressView()
                            .padding()
                    } else if filteredGroups.isEmpty {
                        Text("「 ✦ Không tìm thấy nhóm ✦ 」")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ForEach(filteredGroups) { group in
                            NavigationLink(destination: TaskListGroupView(groupId: group.id)) {
                                HStack {
                                    Image(systemName: group.icon ?? "person.3")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    (group.color != nil ? colors.first(where: { $0.name == group.color })?.color : themeColor) ?? themeColor,
                                                    ((group.color != nil ? colors.first(where: { $0.name == group.color })?.color : themeColor) ?? themeColor).opacity(0.8)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .clipShape(Circle())
                                    
                                    Text(group.name)
                                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.up.chevron.right.chevron.down.chevron.left")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            themeColor.opacity(0.2),
                                            Color(UIColor.systemBackground).opacity(0.95)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )

                                )
                                .cornerRadius(25)
                                .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                                .scaleEffect(1.0)
                                .animation(.spring(), value: groupVM.groups)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeColor.opacity(0.1),
                        Color(UIColor.systemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Groups ✦")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Button(action: { isShowingManageGroups = true }) {
                            Image(systemName: "person.2.badge.gearshape")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(8)
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
                        .scaleEffect(isShowingManageGroups ? 0.95 : 1.0)
                        .animation(.spring(), value: isShowingManageGroups)
                        
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
            .sheet(isPresented: $isShowingManageGroups) {
                ManageGroupsView()
                    .environmentObject(authVM)
            }
            .background(backgroundView().opacity(0.9).ignoresSafeArea())
            .onAppear {
                print("DEBUG: GroupsView onAppear - authVM.currentUser = \(String(describing: authVM.currentUser))")
                if let userId = authVM.currentUser?.id, let role = authVM.currentUser?.role {
                    print("DEBUG: Fetching groups for userId=\(userId), role=\(role)")
                    groupVM.fetchGroups(userId: userId, role: role)
                } else {
                    print("DEBUG: No userId or role available for fetching groups")
                    groupVM.errorMessage = "Vui lòng đăng nhập để xem danh sách nhóm ᝰ.ᐟ"
                }
            }
        }
    }
    
    // MARK: - Background View
    private func backgroundView() -> some View {
        if !themeTexture.isEmpty && themeTexture != "Default" {
            if let selectedGradient = textures.first(where: { $0.name == themeTexture })?.gradient {
                return AnyView(LinearGradient(
                    gradient: selectedGradient,
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
        } else if !themeScenery.isEmpty && themeScenery != "Default" {
            if themeScenery == "Your Photos", let photoData = UserDefaults.standard.data(forKey: "customPhotoData"), let uiImage = UIImage(data: photoData) {
                return AnyView(Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipped())
            } else if let selectedImage = sceneries.first(where: { $0.name == themeScenery })?.imageName {
                return AnyView(Image(selectedImage)
                    .resizable()
                    .scaledToFill()
                    .clipped())
            }
        }
        return AnyView(LinearGradient(
            gradient: Gradient(colors: [
                (colors.first(where: { $0.name == themeColorStorage })?.color ?? .gray).opacity(0.1),
                Color(UIColor.systemBackground)
            ]),
            startPoint: .top,
            endPoint: .bottom
        ))
    }
}

#Preview {
    PreviewContainer()
}

private struct PreviewContainer: View {
    var body: some View {
        let authVM = AuthViewModel()
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
        
        let groupVM = GroupsViewModel(authVM: authVM)
        let friendVM = FriendsViewModel()
        let chatVM = ChattingViewModel()

        return GroupsView()
            .environmentObject(authVM)
            .environmentObject(groupVM)
            .environmentObject(friendVM)
            .environmentObject(chatVM)
            .environment(\.themeColor, .cyan)
    }
}
