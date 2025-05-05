//
//  BirthdaysView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 4/5/25.
//

import SwiftUI

struct BirthdaysView: View {
    // MARK: - Properties
    @EnvironmentObject var friendVM: FriendsViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme

    // MARK: - Body
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // MARK: - Birthdays List
                birthdaysListView
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
        .navigationTitle(".⋅˚₊‧Birthdays ≐ ‧₊˚ ⋅")
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

    // MARK: - Birthdays List View
    private var birthdaysListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text("Birthdays 𓆩❤︎𓆪 (\(friendVM.birthdayFriends.count)) ⋆˙⟡")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(themeColor)
                .padding(.bottom, 8)

            // Content
            if friendVM.birthdayFriends.isEmpty && !friendVM.isLoading {
                Text("No birthdays available ⭑.ᐟ")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color(UIColor.systemBackground)).opacity(0.95)
                    .cornerRadius(25)
                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
            } else {
                ForEach(friendVM.birthdayFriends) { friend in
                    BirthdayRow(friend: friend)
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

// MARK: - Birthday Row Component
struct BirthdayRow: View {
    let friend: Friend
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
                Text(friend.dateOfBirth != nil ? "Birthday: \(friend.dateOfBirth!, formatter: dateFormatter)" : "No birthday")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Chat Button
            NavigationLink(destination: ChattingView ()) {
                Image(systemName: "ellipsis.message.fill")
                    .font(.system(size: 16))
                    .foregroundColor(themeColor)
                    .padding(8)
                    .background(Color(UIColor.systemBackground)).opacity(0.95)
                    .clipShape(Circle())
                    .shadow(color: .gray.opacity(0.2), radius: 2)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(UIColor.systemBackground)).opacity(0.95)
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

// MARK: - Date Formatter
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
    return formatter
}()

// MARK: - Preview
#Preview {
    struct BirthdaysViewPreview: View {
        var body: some View {
            let friendVM = FriendsViewModel()
            return NavigationStack {
                BirthdaysView()
                    .environmentObject(friendVM)
                    .environment(\.themeColor, .cyan)
            }
        }
    }
    return BirthdaysViewPreview()
}
