//
//  CreateGroupView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 1/5/25.
//

import SwiftUI

struct CreateGroupView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var groupsVM: GroupsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var groupName = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Group Details ᝰ.ᐟ")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))) {
                    TextField("Group Name ✧˚ ⋆｡˚", text: $groupName)
                        .font(.system(size: 16, design: .rounded))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(UIColor.systemBackground).opacity(0.95),
                                    themeColor.opacity(0.05)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(themeColor.opacity(0.3), lineWidth: 2)
                        )
                }

                if let errorMessage = groupsVM.errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.red)
                    }
                }
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
            .scrollContentBackground(.hidden)
            .navigationTitle("Create Group ⟢")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel ⟡") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create ✦") {
                        createGroup()
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.vertical, 6)
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
                    .disabled(groupName.isEmpty || isLoading)
                    .scaleEffect(groupName.isEmpty || isLoading ? 0.95 : 1.0)
                    .animation(.spring(), value: groupName.isEmpty || isLoading)
                }
            }
            .overlay(
                isLoading ?
                    ZStack {
                        Color.black.opacity(0.3)
                        ProgressView()
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(UIColor.systemBackground).opacity(0.95),
                                        themeColor.opacity(0.2)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    : nil
            )
        }
    }

    private func createGroup() {
        guard let userId = authVM.currentUser?.id else {
            groupsVM.errorMessage = "User not logged in"
            return
        }
        isLoading = true
        groupsVM.createGroup(userId: userId, name: groupName, color: "blue", icon: "person.3") { success, message, groupId in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    print("Created group with ID: \(groupId ?? -1)")
                    self.dismiss()
                } else {
                    print("Failed to create group: \(message)")
                }
            }
        }
    }
}

#Preview {
    struct CreateGroupViewPreview: View {
        var body: some View {
            let authVM = AuthViewModel()
            let groupsVM = GroupsViewModel(authVM: authVM)

            authVM.currentUser = UserModel(
                id: 1,
                name: "Test User",
                email: "test@example.com",
                password: "password123",
                role: "admin"
            )

            return CreateGroupView()
                .environmentObject(authVM)
                .environmentObject(groupsVM)
                .environment(\.themeColor, .cyan)
        }
    }

    return CreateGroupViewPreview()
}
