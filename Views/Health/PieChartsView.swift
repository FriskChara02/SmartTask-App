//
//  PieChartsView.swift
//  SmartTask
//
//  Created by Loi Nguyen on 12/4/25.
//

import SwiftUI
import Charts

struct PieChartsView: View {
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
                weekPieChartView
            } else {
                dayPieChartView
            }
        }
    }
    
    private func chartBody() -> some View {
        VStack(spacing: 15) {
            // Tiêu đề
            ZStack(alignment: .top) {
                HStack {
                    Spacer()
                    Text("Tỷ lệ Tasks và Events ✦")
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
                    Text("Tỷ lệ % chỉ hiển thị Tasks và Events đang tiến hành")
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
            
            // Biểu đồ tròn
            chartContent()
        }
    }
    
    // MARK: - Body
    var body: some View {
        chartBody()
    }
    
    // MARK: - Week Pie Chart View
    private var weekPieChartView: some View {
        let calendar = Calendar.current
        let today = Date()
        guard let weekRange = calendar.dateInterval(of: .weekOfYear, for: today) else {
            return AnyView(Text("Không thể tải dữ liệu tuần").font(.system(size: 14, design: .rounded)))
        }
        
        // Tính tổng Tasks và Events cho tuần hiện tại
        var totalTasks = 0
        var totalEvents = 0
        var currentDate = weekRange.start
        
        for _ in 0..<7 {
            let tasks = taskVM.tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: currentDate) && !task.isCompleted
            }.count
            let events = eventVM.events.filter { event in
                return calendar.isDate(event.startDate, inSameDayAs: currentDate)
            }.count
            totalTasks += tasks
            totalEvents += events
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                return AnyView(Text("Lỗi tính ngày").font(.system(size: 14, design: .rounded)))
            }
            currentDate = nextDate
        }
        
        // Dữ liệu cho biểu đồ tròn
        let pieData = [
            (label: "Tasks", value: Double(totalTasks), color: Color.blue),
            (label: "Events", value: Double(totalEvents), color: Color.cyan)
        ].filter { $0.value > 0 } // Lọc để tránh giá trị 0
        
        return AnyView(
            VStack(spacing: 10) {
                // Biểu đồ tròn
                if !pieData.isEmpty {
                    Chart {
                        ForEach(pieData, id: \.label) { data in
                            SectorMark(
                                angle: .value("Count", data.value),
                                innerRadius: .ratio(0.4),
                                angularInset: 2
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [data.color.opacity(0.8), data.color]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .annotation(position: .overlay) {
                                let total = pieData.reduce(0) { $0 + $1.value }
                                let percentage = (data.value / total) * 100
                                Text("\(String(format: "%.1f", percentage))%")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 150)
                    .chartLegend(position: .bottom) {
                        HStack(spacing: 20) {
                            ForEach(pieData, id: \.label) { data in
                                HStack {
                                    Circle()
                                        .frame(width: 10, height: 10)
                                        .foregroundColor(data.color)
                                    Text(data.label)
                                        .font(.system(size: 14, design: .rounded))
                                }
                            }
                        }
                    }
                    .shadow(color: themeColor.opacity(0.3), radius: 5, x: 0, y: 3)
                    .padding(.horizontal)
                } else {
                    Text("Không có dữ liệu để hiển thị")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                }
            }
        )
    }
    
    // MARK: - Day Pie Chart View
    private var dayPieChartView: some View {
        let calendar = Calendar.current
        let today = Date()
        
        // Tính tổng Tasks và Events cho ngày hiện tại
        let todayTasks = taskVM.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: today) && !task.isCompleted
        }.count
        let todayEvents = eventVM.events.filter { event in
            return calendar.isDate(event.startDate, inSameDayAs: today)
        }.count
        
        // Dữ liệu cho biểu đồ tròn
        let pieData = [
            (label: "Tasks", value: Double(todayTasks), color: Color.blue),
            (label: "Events", value: Double(todayEvents), color: Color.cyan)
        ].filter { $0.value > 0 } // Lọc để tránh giá trị 0
        
        return AnyView(
            VStack(spacing: 10) {
                // Biểu đồ tròn
                if !pieData.isEmpty {
                    Chart {
                        ForEach(pieData, id: \.label) { data in
                            SectorMark(
                                angle: .value("Count", data.value),
                                innerRadius: .ratio(0.4),
                                angularInset: 2
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [data.color.opacity(0.8), data.color]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .annotation(position: .overlay) {
                                let total = pieData.reduce(0) { $0 + $1.value }
                                let percentage = (data.value / total) * 100
                                Text("\(String(format: "%.1f", percentage))%")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .frame(height: 150)
                    .chartLegend(position: .bottom) {
                        HStack(spacing: 20) {
                            ForEach(pieData, id: \.label) { data in
                                HStack {
                                    Circle()
                                        .frame(width: 10, height: 10)
                                        .foregroundColor(data.color)
                                    Text(data.label)
                                        .font(.system(size: 14, design: .rounded))
                                }
                            }
                        }
                    }
                    .shadow(color: themeColor.opacity(0.3), radius: 5, x: 0, y: 3)
                    .padding(.horizontal)
                } else {
                    Text("Không có dữ liệu để hiển thị")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 20)
                }
            }
        )
    }
}

#Preview {
    let notificationsVM = NotificationsViewModel()
    let taskVM = TaskViewModel(notificationsVM: notificationsVM, userId: 7)
    let googleAuthVM = GoogleAuthViewModel()
    let eventVM = EventViewModel(googleAuthVM: googleAuthVM)
    return PieChartsView(taskVM: taskVM, eventVM: eventVM)
        .environmentObject(eventVM)
        .environmentObject(googleAuthVM)
        .environment(\.themeColor, .blue)
}
