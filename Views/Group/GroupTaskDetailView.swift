//
//  GroupTaskDetailView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 02/5/25.
//

import SwiftUI

struct GroupTaskDetailView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var groupVM: GroupsViewModel
    @StateObject private var viewModel: TaskListViewModel
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var showingCreateTask = false
    @State private var selectedTask: GroupTask?
    
    init(projectId: Int, authVM: AuthViewModel) {
        self._viewModel = StateObject(wrappedValue: TaskListViewModel(projectId: projectId, authVM: authVM))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack {
                    Text("Total \(viewModel.tasks.count) Tasks ⟢")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Spacer()
                    ProgressCircle(progress: viewModel.completionPercentage)
                        .frame(width: 60, height: 60)
                        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
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
                .padding(.horizontal)
                
                if viewModel.isLoading {
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
                } else if viewModel.tasks.isEmpty {
                    Text("No tasks available .ᐟ")
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(.gray)
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
                        .padding(.horizontal)
                } else {
                    List {
                        // Chưa hoàn thành
                        Section(header: Text("Công việc chưa hoàn thành ❆")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray)) {
                            ForEach(viewModel.tasks.filter { !$0.isCompleted }) { task in
                                TaskRow(task: task, viewModel: viewModel, selectedTask: $selectedTask)
                            }
                        }
                        
                        // Đã hoàn thành
                        Section(header: Text("Đã hoàn thành ❀")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.gray)) {
                            ForEach(viewModel.tasks.filter { $0.isCompleted }) { task in
                                TaskRow(task: task, viewModel: viewModel, selectedTask: $selectedTask)
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
                }
                
                if authVM.currentUser?.role != "user" { // Chỉ admin hoặc super_admin được tạo task
                    ButtonAddGroupTasksView(action: { showingCreateTask = true })
                        .padding(.horizontal)
                        .padding(.vertical, 8)
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
            .navigationTitle("Task Details ✦")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateTask) {
                CreateTaskView(viewModel: viewModel, groupVM: groupVM)
                    .environmentObject(authVM)
                    .environment(\.themeColor, themeColor)
            }
            .sheet(item: $selectedTask) { task in
                EditTaskView(task: task, viewModel: viewModel, groupVM: groupVM)
                    .environmentObject(authVM)
                    .environment(\.themeColor, themeColor)
            }
            .onAppear {
                viewModel.fetchTasks()
            }
        }
    }
}

struct TaskRow: View {
    let task: GroupTask
    @ObservedObject var viewModel: TaskListViewModel
    @Binding var selectedTask: GroupTask?
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        HStack {
            Button(action: {
                viewModel.updateTaskCompletion(task: task)
            }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(task.isCompleted ? .green : .gray)
                    .scaleEffect(task.isCompleted ? 1.1 : 1.0)
                    .animation(.spring(), value: task.isCompleted)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                if !task.assignedToNames.isEmpty {
                    Text("Assigned to: \(task.assignedToNames.joined(separator: ", "))")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.gray)
                }
                if let dueDate = task.dueDate {
                    Text("Due: \(dueDate, formatter: dateFormatter)")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(.gray)
                }
                Text("Priority: \(task.priority) ⟢")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                priorityColor(task.priority).opacity(0.2),
                                priorityColor(task.priority).opacity(0.1)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
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
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            selectedTask = task
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func priorityColor(_ priority: String) -> Color {
        switch priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }
}

struct CreateTaskView: View {
    @ObservedObject var viewModel: TaskListViewModel
    @ObservedObject var groupVM: GroupsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var title = ""
    @State private var description = ""
    @State private var assignedToIds: [Int] = []
    @State private var groupId: Int?
    @State private var isLoadingGroupId = false
    @State private var isMembersLoaded = false
    @State private var dueDate: Date?
    @State private var priority = "Medium"
    
    let priorities = ["Low", "Medium", "High"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Info ⋆˚࿔")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))) {
                    TextField("Title ⋆˙⟡", text: $title)
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
                    
                    TextField("Description ₊˚ʚ", text: $description)
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
                    
                    // Danh sách chọn thành viên
                    if isMembersLoaded, let members = groupVM.groupMembers[groupId ?? 0], !members.isEmpty {
                        ForEach(members) { member in
                            HStack {
                                Text(member.name)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: assignedToIds.contains(member.id) ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(assignedToIds.contains(member.id) ? themeColor : .gray)
                                    .scaleEffect(assignedToIds.contains(member.id) ? 1.1 : 1.0)
                                    .animation(.spring(), value: assignedToIds.contains(member.id))
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
                            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if assignedToIds.contains(member.id) {
                                    assignedToIds.removeAll { $0 == member.id }
                                } else {
                                    assignedToIds.append(member.id)
                                }
                                print("DEBUG: CreateTaskView assignedToIds=\(assignedToIds)")
                            }
                        }
                    } else {
                        Text("Loading members... ༄")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.gray)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(UIColor.systemBackground).opacity(0.95),
                                        themeColor.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    
                    if !assignedToIds.isEmpty, let members = groupVM.groupMembers[groupId ?? 0] {
                        let names = assignedToIds.compactMap { id in
                            members.first(where: { $0.id == id })?.name
                        }
                        Text("Assigned to: \(names.joined(separator: ", ")) ⟢")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    
                    DatePicker("Due Date", selection: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                        .font(.system(size: 14, design: .rounded))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
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
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { priority in
                            Text(priority)
                                .font(.system(size: 14, design: .rounded))
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 14, design: .rounded))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
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
            .navigationTitle("Create Task ⟢")
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
                    Button("Create ❀") {
                        if !title.isEmpty, let currentUser = viewModel.currentUser {
                            let userId = currentUser.id
                            viewModel.createTask(
                                title: title,
                                description: description.isEmpty ? nil : description,
                                assignedToIds: assignedToIds,
                                dueDate: dueDate,
                                priority: priority,
                                createdBy: userId
                            )
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
                    .disabled(title.isEmpty)
                    .scaleEffect(title.isEmpty ? 0.95 : 1.0)
                    .animation(.spring(), value: title.isEmpty)
                }
            }
            .onAppear {
                fetchGroupId()
            }
        }
    }
    
    // Lấy groupId từ projectId
    private func fetchGroupId() {
        isLoadingGroupId = true
        GroupService.fetchGroupIdForProject(projectId: viewModel.projectId) { success, groupId, message in
            DispatchQueue.main.async {
                self.isLoadingGroupId = false
                if success, let groupId = groupId {
                    self.groupId = groupId
                    self.groupVM.fetchGroupMembers(groupId: groupId)
                    if !(self.groupVM.groupMembers[groupId] ?? []).isEmpty {
                        self.isMembersLoaded = true
                    }
                } else {
                    print("❌ Failed to fetch groupId: \(message)")
                }
            }
        }
    }
}

struct EditTaskView: View {
    let task: GroupTask
    @ObservedObject var viewModel: TaskListViewModel
    @ObservedObject var groupVM: GroupsViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.themeColor) var themeColor
    @Environment(\.colorScheme) var colorScheme
    @State private var title: String
    @State private var description: String
    @State private var assignedToIds: [Int]
    @State private var groupId: Int?
    @State private var isLoadingGroupId = false
    @State private var isMembersLoaded = false
    @State private var dueDate: Date?
    @State private var isCompleted: Bool
    @State private var priority: String
    @State private var taskExists = true
    
    let priorities = ["Low", "Medium", "High"]
    
    init(task: GroupTask, viewModel: TaskListViewModel, groupVM: GroupsViewModel) {
        self.task = task
        self.viewModel = viewModel
        self.groupVM = groupVM
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description ?? "")
        self._assignedToIds = State(initialValue: task.assignedToIds)
        self._dueDate = State(initialValue: task.dueDate)
        self._isCompleted = State(initialValue: task.isCompleted)
        self._priority = State(initialValue: task.priority)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Task Info .ᐟ")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))) {
                    TextField("Title ⋆˙⟡", text: $title)
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
                    
                    TextField("Description ⋆˚࿔", text: $description)
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
                    
                    // Danh sách chọn thành viên
                    if isMembersLoaded, let members = groupVM.groupMembers[groupId ?? 0], !members.isEmpty {
                        ForEach(members) { member in
                            HStack {
                                Text(member.name)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: assignedToIds.contains(member.id) ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(assignedToIds.contains(member.id) ? themeColor : .gray)
                                    .scaleEffect(assignedToIds.contains(member.id) ? 1.1 : 1.0)
                                    .animation(.spring(), value: assignedToIds.contains(member.id))
                            }
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(UIColor.systemBackground).opacity(0.95),
                                        themeColor.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if assignedToIds.contains(member.id) {
                                    assignedToIds.removeAll { $0 == member.id }
                                } else {
                                    assignedToIds.append(member.id)
                                }
                                print("DEBUG: EditTaskView assignedToIds=\(assignedToIds)")
                            }
                        }
                    } else {
                        Text("Loading members...༄")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(.gray)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(UIColor.systemBackground).opacity(0.95),
                                        themeColor.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                    }
                    
                    // Hiển thị danh sách thành viên đã chọn
                    if !assignedToIds.isEmpty, let members = groupVM.groupMembers[groupId ?? 0] {
                        let names = assignedToIds.compactMap { id in
                            members.first(where: { $0.id == id })?.name
                        }
                        Text("Assigned to: \(names.joined(separator: ", ")) ⟢")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                    
                    DatePicker("Due Date", selection: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                        .font(.system(size: 14, design: .rounded))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
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
                    
                    Picker("Priority", selection: $priority) {
                        ForEach(priorities, id: \.self) { priority in
                            Text(priority)
                                .font(.system(size: 14, design: .rounded))
                        }
                    }
                    .pickerStyle(.menu)
                    .font(.system(size: 14, design: .rounded))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
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
                    
                    Toggle("Completed", isOn: $isCompleted)
                        .font(.system(size: 14, design: .rounded))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
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
                
                // Nút Sửa và Xóa
                Section {
                    Button(action: {
                        if !title.isEmpty && taskExists {
                            viewModel.updateTask(
                                taskId: task.id,
                                title: title,
                                description: description.isEmpty ? nil : description,
                                assignedToIds: assignedToIds,
                                dueDate: dueDate,
                                isCompleted: isCompleted,
                                priority: priority
                            )
                            dismiss()
                        }
                    }) {
                        Text("Sửa ❀")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [themeColor, themeColor.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(25)
                            .shadow(color: themeColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .disabled(title.isEmpty || !taskExists)
                    .scaleEffect((title.isEmpty || !taskExists) ? 0.95 : 1.0)
                    .animation(.spring(), value: title.isEmpty || !taskExists)
                    
                    if let currentUser = viewModel.currentUser, currentUser.role != "user" {
                        Button(action: {
                            let userId = currentUser.id
                            viewModel.deleteTask(taskId: task.id, userId: userId)
                            taskExists = false
                            dismiss()
                        }) {
                            Text("Xóa ✦")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.red, .red.opacity(0.8)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                                .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
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
            .navigationTitle("Edit Task ✦")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
            }
            .onAppear {
                fetchGroupId()
            }
        }
    }
    
    // Lấy groupId từ projectId
    private func fetchGroupId() {
        isLoadingGroupId = true
        GroupService.fetchGroupIdForProject(projectId: viewModel.projectId) { success, groupId, message in
            DispatchQueue.main.async {
                self.isLoadingGroupId = false
                if success, let groupId = groupId {
                    self.groupId = groupId
                    self.groupVM.fetchGroupMembers(groupId: groupId)
                    if !(self.groupVM.groupMembers[groupId] ?? []).isEmpty {
                        self.isMembersLoaded = true
                    }
                } else {
                    print("❌ Failed to fetch groupId: \(message)")
                }
            }
        }
    }
}

class TaskListViewModel: ObservableObject {
    @Published var tasks: [GroupTask] = []
    @Published var isLoading = false
    @Published var completionPercentage: Double = 0.0
    private let authVM: AuthViewModel
    private let _projectId: Int
    
    public var projectId: Int {
        return _projectId
    }
    
    var currentUser: UserModel? {
        return authVM.currentUser
    }
    
    init(projectId: Int, authVM: AuthViewModel) {
        self._projectId = projectId
        self.authVM = authVM
    }
    
    func fetchTasks() {
        isLoading = true
        GroupService.fetchGroupTasks(projectId: projectId) { [weak self] success, tasks, message in
            DispatchQueue.main.async {
                self?.isLoading = false
                if success, let tasks = tasks {
                    self?.tasks = tasks
                    self?.updateCompletionPercentage()
                } else {
                    print("❌ Failed to fetch tasks: \(message)")
                }
            }
        }
    }
    
    func createTask(title: String, description: String?, assignedToIds: [Int], dueDate: Date?, priority: String, createdBy: Int) {
        GroupService.createGroupTask(projectId: projectId, title: title, description: description, assignedToIds: assignedToIds, dueDate: dueDate, priority: priority, createdBy: createdBy) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    self?.fetchTasks()
                } else {
                    print("❌ Failed to create task: \(message)")
                }
            }
        }
    }
    
    func updateTask(taskId: Int, title: String, description: String?, assignedToIds: [Int], dueDate: Date?, isCompleted: Bool, priority: String) {
        GroupService.updateGroupTask(taskId: taskId, title: title, description: description, assignedToIds: assignedToIds, dueDate: dueDate, isCompleted: isCompleted, priority: priority) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    self?.fetchTasks()
                } else {
                    print("❌ Failed to update task: \(message)")
                }
            }
        }
    }
    
    func updateTaskCompletion(task: GroupTask) {
        let newCompletionStatus = !task.isCompleted
        GroupService.updateGroupTask(taskId: task.id, title: task.title, description: task.description, assignedToIds: task.assignedToIds, dueDate: task.dueDate, isCompleted: newCompletionStatus, priority: task.priority) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    self?.fetchTasks()
                } else {
                    print("❌ Failed to update task completion: \(message)")
                }
            }
        }
    }
    
    func deleteTask(taskId: Int, userId: Int) {
        GroupService.deleteGroupTask(taskId: taskId, userId: userId) { [weak self] success, message in
            DispatchQueue.main.async {
                if success {
                    self?.tasks.removeAll { $0.id == taskId }
                    self?.updateCompletionPercentage()
                } else {
                    print("❌ Failed to delete task: \(message)")
                }
            }
        }
    }
    
    private func updateCompletionPercentage() {
        let totalTasks = tasks.count
        let completedTasks = tasks.filter { $0.isCompleted }.count
        completionPercentage = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
    }
}

struct GroupTaskDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let authVM = AuthViewModel()
        let groupVM = GroupsViewModel(authVM: authVM)
        GroupTaskDetailView(projectId: 1, authVM: authVM)
            .environmentObject(authVM)
            .environmentObject(groupVM)
            .environment(\.themeColor, .cyan)
    }
}
