//
//  BarChartsView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 12/4/25.
//

import SwiftUI
import Charts

struct BarChartsView: View {
    // MARK: - Properties
    @ObservedObject var taskVM: TaskViewModel
    @ObservedObject var eventVM: EventViewModel
    @Environment(\.themeColor) var themeColor: Color
    @State private var chartMode: ChartMode = .week // Trạng thái chọn Week/Day
    @State private var showTooltip: Bool = false
    
    // MARK: - Chart Mode Enum
    private enum ChartMode: String, CaseIterable {
        case week = "Week ✦"
        case day = "Day ⟡"
    }
    
    // MARK: - Theme Color Mapping
    private var gradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [themeColor.opacity(0.8), themeColor]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // MARK: - Helper Views
    private func modeButton(mode: ChartMode) -> some View {
        Button(action: {
            chartMode = mode
        }) {
            Text(mode.rawValue)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(chartMode == mode ? .white : themeColor)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    chartMode == mode
                    ? AnyView(gradient)
                    : AnyView(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                )
                .cornerRadius(8)
                .shadow(color: .primary.opacity(chartMode == mode ? 0.2 : 0), radius: 3, x: 0, y: 2)
        }
    }

    private func chartModeButtons() -> some View {
        HStack(spacing: 10) {
            ForEach(ChartMode.allCases, id: \.rawValue) { mode in
                modeButton(mode: mode)
            }
        }
    }

    private func chartContent() -> some View {
        Group {
            if chartMode == .week {
                weekChartView
            } else {
                dayChartView
            }
        }
    }
    
    private func chartBody() -> some View {
        VStack(spacing: 15) {
            // Tiêu đề
            ZStack(alignment: .top) {
                HStack {
                    Spacer()
                    Text("Biểu đồ Tasks và Events ✦")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                    Spacer()
                    Button(action: {
                        withAnimation(.easeInOut) {
                            showTooltip.toggle()
                        }
                    }) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 16))
                            .foregroundColor(themeColor)
                    }
                }
                if showTooltip {
                    Text("Hiển thị số lượng Tasks và Events đang tiến hành. Ví dụ: 1 Task + 3 Events = mức 4")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(themeColor)
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                        .offset(y: 16)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            
            // Buttons chọn Week/Day
            chartModeButtons()
            
            // Nội dung biểu đồ
            chartContent()
        }
    }
    
    // MARK: - Body
    var body: some View {
        chartBody()
    }
    
    // MARK: - Week Chart View
    private var weekChartView: some View {
        let calendar = Calendar.current
        let today = Date()
        guard let weekRange = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return AnyView(Text("Không thể tải dữ liệu tuần").font(.system(size: 14, design: .rounded)))
        }
        guard let lastWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: today),
              let lastWeekRange = calendar.dateInterval(of: .weekOfYear, for: lastWeekDate) else {
            return AnyView(Text("Không thể tải dữ liệu tuần trước").font(.system(size: 14, design: .rounded)))
        }
        
        // Tính dữ liệu cho tuần hiện tại
        var weekData: [(day: String, tasks: Int, events: Int)] = []
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var totalTasks = 0
        var totalEvents = 0
        var currentDate = weekRange.start
        
        for i in 0..<7 {
            let tasks = taskVM.tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: currentDate) && !task.isCompleted
            }.count
            let events = eventVM.events.filter { event in
                return calendar.isDate(event.startDate, inSameDayAs: currentDate)
            }.count
            weekData.append((day: days[i], tasks: tasks, events: events))
            totalTasks += tasks
            totalEvents += events
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                return AnyView(Text("Lỗi tính ngày").font(.system(size: 14, design: .rounded)))
            }
            currentDate = nextDate
        }
        
        // Tính trung bình hàng ngày
        let dailyAverage = Double(totalTasks + totalEvents) / 7.0
        
        // Tính dữ liệu tuần trước để so sánh
        var lastWeekTotal = 0
        currentDate = lastWeekRange.start
        for _ in 0..<7 {
            let tasks = taskVM.tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: currentDate) && !task.isCompleted
            }.count
            let events = eventVM.events.filter { event in
                return calendar.isDate(event.startDate, inSameDayAs: currentDate)
            }.count
            lastWeekTotal += tasks + events
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                return AnyView(Text("Lỗi tính ngày").font(.system(size: 14, design: .rounded)))
            }
            currentDate = nextDate
        }
        
        // Tính % thay đổi
        let currentTotal = totalTasks + totalEvents
        let percentageChange = lastWeekTotal == 0 ? 0.0 : Double(currentTotal - lastWeekTotal) / Double(lastWeekTotal) * 100
        let isIncreasing = percentageChange > 0
        
        // Tách Chart để giảm độ phức tạp
        @ViewBuilder
        func weekChartContent() -> some View {
            Chart {
                ForEach(weekData, id: \.day) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Tasks", data.tasks),
                        stacking: .standard
                    )
                    .foregroundStyle(.blue)
                    
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Events", data.events),
                        stacking: .standard
                    )
                    .foregroundStyle(.cyan)
                }
                
                // Đường ngang Daily Average
                RuleMark(y: .value("Average", dailyAverage))
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("avg")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.green)
                    }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: days) { _ in
                    AxisValueLabel()
                        .font(.system(size: 12, design: .rounded))
                }
            }
            .chartYAxis {
                AxisMarks(values: .stride(by: 2)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.system(size: 12, design: .rounded))
                }
            }
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .shadow(color: themeColor.opacity(0.2), radius: 3, x: 0, y: 2)
            )
        }
        
        return AnyView(
            VStack(spacing: 10) {
                // Header
                VStack(alignment: .leading, spacing: 5) {
                    Text("Total Tasks & Events")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                    HStack {
                        Text("\(currentTotal) ✦")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Spacer()
                        Text("\(String(format: "%.1f", abs(percentageChange)))% \(isIncreasing ? "↑" : "↓")")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(isIncreasing ? .green : .red)
                    }
                }
                .padding(.horizontal)
                
                // Biểu đồ cột
                weekChartContent()
                
                // Phân loại Tasks và Events
                HStack(spacing: 20) {
                    HStack {
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.blue)
                        Text("Tasks: \(totalTasks)")
                            .font(.system(size: 14, design: .rounded))
                    }
                    HStack {
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.cyan)
                        Text("Events: \(totalEvents)")
                            .font(.system(size: 14, design: .rounded))
                    }
                }
                .padding(.horizontal)
                
                // Tổng số Tasks và Events
                Text("Total Tasks & Events: \(currentTotal)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .padding(.horizontal)
            }
        )
    }
    
    // MARK: - Day Chart View
    private var dayChartView: some View {
        let calendar = Calendar.current
        let today = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        let todayString = formatter.string(from: today)
        
        // Lấy 7 ngày trong tuần hiện tại
        var weekData: [(day: String, tasks: Int, events: Int, isToday: Bool)] = []
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        guard let weekRange = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return AnyView(Text("Không thể tải dữ liệu tuần").font(.system(size: 14, design: .rounded)))
        }
        var totalTasks = 0
        var totalEvents = 0
        var todayTasks = 0
        var todayEvents = 0
        var currentDate = weekRange.start
        
        for i in 0..<7 {
            let isToday = calendar.isDate(currentDate, inSameDayAs: today)
            let tasks = taskVM.tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: currentDate) && !task.isCompleted
            }.count
            let events = eventVM.events.filter { event in
                return calendar.isDate(event.startDate, inSameDayAs: currentDate)
            }.count
            weekData.append((day: days[i], tasks: tasks, events: events, isToday: isToday))
            totalTasks += tasks
            totalEvents += events
            if isToday {
                todayTasks = tasks
                todayEvents = events
            }
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                return AnyView(Text("Lỗi tính ngày").font(.system(size: 14, design: .rounded)))
            }
            currentDate = nextDate
        }
        
        // Tổng hôm nay
        let todayTotal = todayTasks + todayEvents
        
        // Tách Chart để giảm độ phức tạp
        @ViewBuilder
        func dayChartContent() -> some View {
            Chart {
                ForEach(weekData, id: \.day) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Tasks", data.tasks),
                        stacking: .standard
                    )
                    .foregroundStyle(data.isToday ? .blue : .gray.opacity(0.5))
                    
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Events", data.events),
                        stacking: .standard
                    )
                    .foregroundStyle(data.isToday ? .cyan : .gray.opacity(0.5))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: days) { _ in
                    AxisValueLabel()
                        .font(.system(size: 12, design: .rounded))
                }
            }
            .chartYAxis {
                AxisMarks(values: .stride(by: 2)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                        .font(.system(size: 12, design: .rounded))
                }
            }
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemBackground))
                    .shadow(color: themeColor.opacity(0.2), radius: 3, x: 0, y: 2)
            )
        }
        
        return AnyView(
            VStack(spacing: 10) {
                // Header
                VStack(alignment: .leading, spacing: 5) {
                    Text("Today, \(todayString)")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("\(todayTotal) ✦")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                // Biểu đồ cột
                dayChartContent()
                
                // Phân loại Tasks và Events
                HStack(spacing: 20) {
                    HStack {
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.blue)
                        Text("Tasks: \(todayTasks)")
                            .font(.system(size: 14, design: .rounded))
                    }
                    HStack {
                        Circle()
                            .frame(width: 10, height: 10)
                            .foregroundColor(.cyan)
                        Text("Events: \(todayEvents)")
                            .font(.system(size: 14, design: .rounded))
                    }
                }
                .padding(.horizontal)
            }
        )
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
    let googleAuthVM = GoogleAuthViewModel()
    let eventVM = EventViewModel(googleAuthVM: googleAuthVM)
    return BarChartsView(taskVM: taskVM, eventVM: eventVM)
        .environmentObject(eventVM)
        .environmentObject(googleAuthVM)
        .environment(\.themeColor, .blue)
}
