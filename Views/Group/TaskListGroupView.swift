//
//  TaskListGroupView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 29/4/25.
//

import SwiftUI

struct TaskListGroupView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var groupVM: GroupsViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var isGroupExpanded = false
    @State private var showingCreateProject = false
    private let groupId: Int
    @State private var taskViewModels: [Int: TaskListViewModel] = [:]
    
    init(groupId: Int) {
        self.groupId = groupId
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    if groupVM.isLoading {
                        ProgressView()
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        themeColor.opacity(0.2),
                                        Color(UIColor.systemBackground).opacity(0.95)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                    } else {
                        // Group Information Section
                        groupInfoSection
                        
                        // Task Groups Section
                        taskGroupsSection
                        
                        // Button Add Tasks Group
                        if authVM.currentUser?.role != "user" { // Chỉ admin hoặc super_admin được tạo dự án
                            ButtonAddTasksGroupView(action: { showingCreateProject = true })
                                .padding(.horizontal)
                                .padding(.vertical, 8)
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
            .navigationTitle("Task Groups ✦")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateProject) {
                CreateProjectView(viewModel: groupVM, groupId: groupId)
                    .environment(\.themeColor, themeColor)
            }
            .onAppear {
                if let _ = authVM.currentUser?.id, let _ = authVM.currentUser?.role {
                    groupVM.fetchGroupProjects(groupId: groupId)
                    groupVM.fetchGroupMembers(groupId: groupId)
                    if let projects = groupVM.groupProjects[groupId] {
                        for project in projects {
                            if taskViewModels[project.id] == nil {
                                let taskVM = TaskListViewModel(projectId: project.id, authVM: authVM)
                                taskViewModels[project.id] = taskVM
                                taskVM.fetchTasks()
                            }
                        }
                    }
                }
            }
            .onChange(of: groupVM.groupProjects[groupId]) { oldProjects, newProjects in
                if let projects = newProjects {
                    for project in projects {
                        if taskViewModels[project.id] == nil {
                            let taskVM = TaskListViewModel(projectId: project.id, authVM: authVM)
                            taskViewModels[project.id] = taskVM
                            taskVM.fetchTasks()
                        }
                    }
                }
            }
        }
    }
    
    private var groupInfoSection: some View {
        DisclosureGroup(
            isExpanded: $isGroupExpanded,
            content: {
                VStack(alignment: .leading, spacing: 12) {
                    // Projects
                    if let projects = groupVM.groupProjects[groupId], !projects.isEmpty {
                        Section(header: Text("Projects ⟡")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray)) {
                            ForEach(projects) { project in
                                NavigationLink(destination: GroupTaskDetailView(projectId: project.id, authVM: authVM)) {
                                    ProjectRow(
                                        project: project,
                                        progress: taskViewModels[project.id]?.completionPercentage ?? 0.0
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    } else {
                        Text("No projects available .ᐟ")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    
                    // Members
                    if let members = groupVM.groupMembers[groupId], !members.isEmpty {
                        Section(header: Text("Members ˚₊‧꒰ა ☆ ໒꒱ ‧₊˚")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray)) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(members) { member in
                                        MemberRow(member: member)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    } else {
                        Text("No members available .ᐟ")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            },
            label: {
                HStack {
                    Image(systemName: "person.3")
                        .font(.system(size: 20))
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
                    
                    let groupName = groupVM.groups.first(where: { $0.id == groupId })?.name ?? "Group"
                    let projectCount = groupVM.groupProjects[groupId]?.count ?? 0
                    Text("\(groupName) (\(projectCount) Projects)")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
        )
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    themeColor.opacity(0.1),
                    Color(UIColor.systemBackground).opacity(0.95)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.5), value: isGroupExpanded)
    }
    
    private var taskGroupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Task Groups ⟢")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(themeColor.opacity(0.2))
                        .frame(width: 30, height: 30)
                    Text("\(groupVM.groupProjects[groupId]?.count ?? 0)")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(themeColor)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            if let projects = groupVM.groupProjects[groupId], !projects.isEmpty {
                ForEach(projects) { project in
                    NavigationLink {
                        GroupTaskDetailView(projectId: project.id, authVM: authVM)
                    } label: {
                        TaskGroupRow(
                            project: project,
                            progress: taskViewModels[project.id]?.completionPercentage ?? 0.0
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            } else {
                Text("No task groups available ⋆.˚")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
        }
    }
}

struct TaskGroupRow: View {
    let project: GroupProject
    let progress: Double
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "folder")
                .font(.system(size: 20))
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                Text("\(project.taskCount) tasks ✦")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            ProgressCircle(progress: progress)
                .frame(width: 40, height: 40)
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
    }
}

struct ProjectRow: View {
    let project: GroupProject
    let progress: Double
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Image(systemName: "list.bullet")
                .font(.system(size: 20))
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
            
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                Text("\(Int(progress * 100))% Complete ⟢")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundColor(.gray)
            }
            
            Spacer()
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
    }
}

struct MemberRow: View {
    let member: GroupMember
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: member.avatarURL ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(themeColor.opacity(0.3), lineWidth: 2)
                    )
            } placeholder: {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.gray.opacity(0.3),
                                themeColor.opacity(0.2)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    )
            }
            
            Text(member.name)
                .font(.system(size: 12, design: .rounded))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(UIColor.systemBackground).opacity(0.95),
                    themeColor.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(25)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

struct ProgressCircle: View {
    let progress: Double
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 6)
                .opacity(0.3)
                .foregroundColor(.gray)
            
            Circle()
                .trim(from: 0.0, to: min(progress, 1.0))
                .stroke(
                    style: StrokeStyle(
                        lineWidth: 6,
                        lineCap: .round
                    )
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeInOut, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(themeColor)
        }
    }
}


struct TaskListGroupView_Previews: PreviewProvider {
    static var previews: some View {
        let authVM = AuthViewModel()
        let groupVM = GroupsViewModel(authVM: authVM)
        TaskListGroupView(groupId: 1)
            .environmentObject(authVM)
            .environmentObject(groupVM)
            .environment(\.themeColor, .cyan)
    }
}
