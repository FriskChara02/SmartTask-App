//
//  CreateProjectView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 2/5/25.
//

import SwiftUI

struct CreateProjectView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @ObservedObject var viewModel: GroupsViewModel
    let groupId: Int
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var name = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Project Info ᝰ.ᐟ")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))) {
                    TextField("Project Name ✧˚ ⋆｡˚", text: $name)
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
            .navigationTitle("Create Project ⟢")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("⟡ Cancel") {
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("✦ Create") {
                        if !name.isEmpty {
                            viewModel.createProject(groupId: groupId, name: name)
                            dismiss()
                        }
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
                    .disabled(name.isEmpty)
                    .scaleEffect(name.isEmpty ? 0.95 : 1.0)
                    .animation(.spring(), value: name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    let authVM = AuthViewModel()
    let groupVM = GroupsViewModel(authVM: authVM)
    return CreateProjectView(viewModel: groupVM, groupId: 1)
        .environment(\.themeColor, .cyan)
        .environmentObject(authVM)
}
