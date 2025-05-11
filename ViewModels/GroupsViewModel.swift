//
//  GroupsViewModel.swift
//  SmartTask
//
//  Created by Loi Nguyen on 30/4/25.
//

import Foundation

class GroupsViewModel: ObservableObject {
    @Published var groups: [GroupModel] = []
    @Published var groupProjects: [Int: [GroupProject]] = [:]
    @Published var groupMembers: [Int: [GroupMember]] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    private var authVM: AuthViewModel

    init(authVM: AuthViewModel) {
        self.authVM = authVM
    }
    func fetchGroups(userId: Int, role: String) {
        isLoading = true
        GroupService.fetchGroups(userId: userId, role: role) { [weak self] success, groups, message in
            DispatchQueue.main.async {
                self?.isLoading = false
                if success, let groups = groups {
                    self?.groups = groups
                    for group in groups {
                        self?.fetchGroupProjects(groupId: group.id)
                        self?.fetchGroupMembers(groupId: group.id)
                    }
                } else {
                    self?.errorMessage = message
                    print("❌ Failed to fetch groups: \(message)")
                }
            }
        }
    }

    func fetchGroupProjects(groupId: Int) {
        GroupService.fetchGroupProjects(groupId: groupId) { [weak self] success, projects, message in
            DispatchQueue.main.async {
                if success, let projects = projects {
                    self?.groupProjects[groupId] = projects
                } else {
                    self?.errorMessage = message
                    print("❌ Failed to fetch projects for group \(groupId): \(message)")
                }
            }
        }
    }

    func fetchGroupMembers(groupId: Int) {
        GroupService.fetchGroupMembers(groupId: groupId) { [weak self] success, members, message in
            DispatchQueue.main.async {
                if success, let members = members {
                    self?.groupMembers[groupId] = members
                    print("DEBUG: Group id \(groupId), members: \(members.map { $0.name })")
                } else {
                    self?.errorMessage = message
                    print("❌ Failed to fetch members for group \(groupId): \(message)")
                }
            }
        }
    }

    func createGroup(userId: Int, name: String, color: String, icon: String, completion: @escaping (Bool, String, Int?) -> Void) {
        GroupService.createGroup(userId: userId, name: name, color: color, icon: icon) { [weak self] success, message, groupId in
            DispatchQueue.main.async {
                if success {
                    if let groupId = groupId {
                        let newGroup = GroupModel(
                            id: groupId,
                            name: name,
                            createdBy: userId,
                            createdAt: Date(),
                            color: color,
                            icon: icon
                        )
                        self?.groups.append(newGroup)
                        self?.fetchGroupProjects(groupId: groupId)
                        self?.fetchGroupMembers(groupId: groupId)
                    } else {
                        self?.fetchGroups(userId: userId, role: "admin")
                    }
                } else {
                    self?.errorMessage = message
                    print("❌ Failed to create group: \(message)")
                }
                completion(success, message, groupId)
            }
        }
    }

    func updateGroup(groupId: Int, name: String, color: String, icon: String) {
        GroupService.updateGroup(groupId: groupId, name: name, color: color, icon: icon) { [weak self] success, message in
            DispatchQueue.main.async {
                if success, let userId = self?.groups.first?.createdBy {
                    self?.fetchGroups(userId: userId, role: "admin")
                } else {
                    self?.errorMessage = message
                    print("❌ Failed to update group: \(message)")
                }
            }
        }
    }

    func deleteGroup(groupId: Int, userId: Int) {
        GroupService.deleteGroup(groupId: groupId, userId: userId) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    self?.groups.removeAll { $0.id == groupId }
                    // Optional: gọi fetchGroups để đảm bảo nhất quán
                    // self?.fetchGroups(userId: userId, role: "admin")
                } else {
                    self?.errorMessage = message
                    print("❌ Failed to delete group: \(message)")
                }
            }
        }
    }

    func addGroupMember(groupId: Int, userId: Int, addedBy: Int) {
        GroupService.addGroupMember(groupId: groupId, userId: userId, addedBy: addedBy) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    self?.fetchGroupMembers(groupId: groupId)
                } else {
                    self?.errorMessage = message
                    print("❌ Failed to add member: \(message)")
                }
            }
        }
    }

    func removeGroupMember(groupId: Int, userId: Int, requestingUserId: Int) {
        GroupService.removeGroupMember(groupId: groupId, userId: userId, requestingUserId: requestingUserId) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    self?.fetchGroupMembers(groupId: groupId)
                } else {
                    self?.errorMessage = message
                    print("❌ Failed to remove member: \(message)")
                }
            }
        }
    }

    private func updateUserRole(userId: Int, role: String) {
        AdminService.updateUserRole(adminId: userId, userId: userId, newRole: role) { success, message in
            if !success {
                DispatchQueue.main.async {
                    self.errorMessage = message
                    print("❌ Failed to update user role: \(message)")
                }
            }
        }
    }
    
    func createProject(groupId: Int, name: String) {
            guard let createdBy = authVM.currentUser?.id else {
                self.errorMessage = "Không tìm thấy người dùng hiện tại"
                print("❌ Failed to create project: No current user")
                return
            }
            GroupService.createGroupProject(groupId: groupId, name: name, createdBy: createdBy) { [weak self] success, message in
                DispatchQueue.main.async {
                    if success {
                        self?.fetchGroupProjects(groupId: groupId)
                        print("✅ Created project for group \(groupId)")
                    } else {
                        self?.errorMessage = message
                        print("❌ Failed to create project: \(message)")
                    }
                }
            }
        }
}
