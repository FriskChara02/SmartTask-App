import SwiftUI

struct CalendarView: View {
    @StateObject private var taskVM: TaskViewModel
    @StateObject private var categoryVM = CategoryViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var isCollapsed = false
    @State private var doubleTappedDate: Date?
    @State private var showAddTaskView = false
    
    private let calendar = Calendar.current
    private let dateHelper = DateHelper.shared
    
    init() {
        let notificationsVM = NotificationsViewModel()
        _taskVM = StateObject(wrappedValue: TaskViewModel(notificationsVM: notificationsVM, userId: nil))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient Background
                LinearGradient(gradient: Gradient(colors: [.blue.opacity(0.1), .green.opacity(0.1)]), startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                
                // Nội dung chính với ScrollView
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Hàng 1: Điều hướng tháng (đưa lên đầu)
                        monthNavigation
                        
                        // Hàng 2: Ngày trong tuần
                        weekDays
                            .frame(maxWidth: .infinity)
                        
                        // Hàng 3: Lưới ngày
                        Group {
                            if isCollapsed {
                                collapsedCalendar
                            } else {
                                fullCalendar
                            }
                        }
                        .transition(.opacity)
                        .frame(maxWidth: .infinity)
                        
                        // Thanh ngang giữa hàng 3 và 4
                        LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)
                            .frame(height: 2)
                            .cornerRadius(1)
                        
                        // Hàng 4: Danh sách category trong tháng
                        categoryList
                        
                        // Thanh ngang giữa hàng 4 và 5
                        LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .leading, endPoint: .trailing)
                            .frame(height: 2)
                            .cornerRadius(1)
                        
                        // Hàng 5: Danh sách task của ngày được chọn
                        taskList
                        
                        // Spacer để đẩy nội dung lên nếu cần
                        Spacer()
                    }
                    .padding()
                }
                
                // Button Add Task cố định dưới cùng, nhạt 75%
                VStack {
                    Spacer()
                    ButtonAddTasksView(action: {
                        withAnimation(.easeInOut) {
                            showAddTaskView = true
                        }
                    })
                    .opacity(0.60) // Nhạt
                    .padding(.bottom, 20)
                }
            }
            .sheet(isPresented: $showAddTaskView) {
                AddTaskView()
                    .environmentObject(taskVM)
                    .environmentObject(categoryVM)
            }
            .onAppear {
                taskVM.userId = authVM.currentUser?.id
                taskVM.fetchTasks()
                categoryVM.fetchCategories()
            }
        }
        .environmentObject(taskVM)
        .environmentObject(categoryVM)
    }
    
    // MARK: - Hàng 1: Điều hướng tháng
    private var monthNavigation: some View {
        HStack(spacing: 15) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            
            Spacer()
            
            Text(" \(dateHelper.formatDate(currentMonth, format: "MMM, yyyy")) ")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color.white.opacity(0.9))
                .cornerRadius(12)
                .shadow(radius: 3)
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .padding(8)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
            
            Button(action: {
                withAnimation(.spring()) {
                    isCollapsed.toggle()
                }
            }) {
                Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.title2)
                    .foregroundColor(.purple)
                    .padding(8)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Circle())
                    .shadow(radius: 2)
            }
        }
        .padding(.horizontal, 10)
    }
    
    // MARK: - Hàng 2: Ngày trong tuần
    private var weekDays: some View {
        HStack(spacing: 0) {
            ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                Text(day)
                    .font(.system(size: 14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundColor(.green) // Màu xanh lá
                    .background(Color.white.opacity(0.9))
            }
        }
        .cornerRadius(8)
        .shadow(radius: 2)
    }
    
    // MARK: - Hàng 3: Lịch đầy đủ
    private var fullCalendar: some View {
        let days = generateDaysInMonth(for: currentMonth)
        return VStack(spacing: 8) {
            ForEach(0..<6) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7) { column in
                        let index = row * 7 + column
                        if index < days.count {
                            dayCell(date: days[index])
                        } else {
                            Color.clear.frame(width: 45, height: 45)
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.95))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    // MARK: - Lịch thu gọn
    private var collapsedCalendar: some View {
        let days = generateDaysInMonth(for: currentMonth)
        let today = Date()
        let currentWeek = days.filter { calendar.isDate($0, equalTo: today, toGranularity: .weekOfYear) }
        
        return HStack(spacing: 0) {
            ForEach(currentWeek, id: \.self) { date in
                dayCell(date: date)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.95))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    // MARK: - Ô ngày
    private func dayCell(date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = dateHelper.isToday(date)
        let isDoubleTapped = doubleTappedDate != nil && calendar.isDate(date, inSameDayAs: doubleTappedDate!)
        let tasksForDay = taskVM.tasks.filter { calendar.isDate($0.dueDate ?? Date.distantFuture, inSameDayAs: date) }
        
        return Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDate = date
            }
        }) {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : (isToday ? .blue : .black))
                    .frame(width: 45, height: 45)
                    .background(
                        Group {
                            if isSelected {
                                Circle().fill(categoryColor(for: tasksForDay.first?.categoryId))
                                    .shadow(radius: 3)
                            } else if isToday {
                                Circle().stroke(Color.blue, lineWidth: 2)
                            } else {
                                Circle().fill(Color.gray.opacity(0.1))
                            }
                        }
                    )
                
                if !tasksForDay.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(tasksForDay.prefix(3), id: \.id) { task in
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundColor(categoryColor(for: task.categoryId))
                                .shadow(radius: 1)
                        }
                    }
                }
                
                if isDoubleTapped {
                    VStack(spacing: 2) {
                        ForEach(tasksForDay, id: \.id) { task in
                            if let categoryName = categoryName(for: task.categoryId) {
                                Text(categoryName)
                                    .font(.system(size: 12))
                                    .foregroundColor(categoryColor(for: task.categoryId).opacity(0.8)) // Màu category, nhạt 20%
                                    .lineLimit(1)
                                    .padding(.horizontal, 4)
                                    .background(Color.white.opacity(0.8))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                withAnimation(.spring()) {
                    doubleTappedDate = (doubleTappedDate == date) ? nil : date
                }
            }
        )
    }
    
    // MARK: - Hàng 4: Danh sách category trong tháng
    private var categoryList: some View {
        let tasksInMonth = taskVM.tasks.filter {
            calendar.isDate($0.dueDate ?? Date.distantFuture, equalTo: currentMonth, toGranularity: .month)
        }
        let uniqueCategoryIds = Set(tasksInMonth.map { $0.categoryId })
        
        return VStack(alignment: .leading, spacing: 8) {
            if uniqueCategoryIds.isEmpty {
                Text("Your monthly categories ⸜(｡˃ ᵕ ˂ )⸝♡ (˶˃ ᵕ ˂˶)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(uniqueCategoryIds.sorted(), id: \.self) { categoryId in
                        if let categoryName = categoryName(for: categoryId) {
                            HStack(spacing: 6) {
                                Circle()
                                    .frame(width: 12, height: 12)
                                    .foregroundColor(categoryColor(for: categoryId))
                                    .shadow(radius: 1)
                                Text(categoryName)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.white.opacity(0.95))
                            .cornerRadius(10)
                            .shadow(radius: 3)
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
        }
    }
    
    // MARK: - Hàng 5: Danh sách task
    private var taskList: some View {
        let tasksForSelectedDay = taskVM.tasks.filter {
            calendar.isDate($0.dueDate ?? Date.distantFuture, inSameDayAs: selectedDate)
        }
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Task ngày \(dateHelper.formatDate(selectedDate, format: "dd/MM/yyyy"))")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal)
                .padding(.top, 5)
            
            if tasksForSelectedDay.isEmpty {
                Text("Không có task nào hôm nay")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
            } else {
                ForEach(tasksForSelectedDay) { task in
                    TaskRowView(task: task, toggleAction: {
                        withAnimation(.easeInOut) {
                            taskVM.toggleTaskCompletion(task: task)
                        }
                    })
                    .padding(.horizontal)
                    .background(Color.white.opacity(0.95))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .shadow(radius: 5)
    }
    
    // MARK: - Helper Functions
    private func generateDaysInMonth(for date: Date) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) else {
            return []
        }
        
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth) - 1
        var days: [Date] = []
        
        if firstWeekday > 0 {
            if let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDayOfMonth) {
                let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count
                for day in (daysInPreviousMonth - firstWeekday + 1)...daysInPreviousMonth {
                    if let date = calendar.date(from: calendar.dateComponents([.year, .month], from: previousMonth)) {
                        days.append(calendar.date(byAdding: .day, value: day - 1, to: date)!)
                    }
                }
            }
        }
        
        for day in 0..<range.count {
            if let newDate = calendar.date(byAdding: .day, value: day, to: firstDayOfMonth) {
                days.append(newDate)
            }
        }
        
        return days
    }
    
    private func categoryName(for categoryId: Int?) -> String? {
        categoryVM.categories.first { $0.id == categoryId }?.name
    }
    
    private func categoryColor(for categoryId: Int?) -> Color {
        if let category = categoryVM.categories.first(where: { $0.id == categoryId }),
           let colorName = category.color {
            switch colorName.lowercased() {
            case "blue": return .blue
            case "purple": return .purple
            case "red": return .red
            case "orange": return .orange
            case "yellow": return .yellow
            case "green": return .green
            default: return .gray
            }
        }
        return .gray
    }
}

#Preview {
    CalendarView()
        .environmentObject(AuthViewModel())
        .environmentObject(TaskViewModel(notificationsVM: NotificationsViewModel(), userId: 1))
        .environmentObject(CategoryViewModel())
}
