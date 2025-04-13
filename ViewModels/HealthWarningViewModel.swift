//
//  HealthWarningViewModel.swift
//  SmartTask
//
//  Created by Loi Nguyen on 10/4/25.
//

import Foundation
import SwiftUI

class HealthWarningViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var weight: String = ""
    @Published var height: String = ""
    @Published var dayStatus: String = "Đang tính toán..."
    @Published var dayColor: Color = .gray
    @Published var weekStatus: String = "Đang tính toán..."
    @Published var weekColor: Color = .gray
    @Published var monthStatus: String = "Đang tính toán..."
    @Published var monthColor: Color = .gray
    @Published var yearStatus: String = "Đang tính toán..."
    @Published var yearColor: Color = .gray
    @Published var overallStatus: String = "Đang tính toán..."
    @Published var overallColor: Color = .gray
    @Published var bmi: Float? = nil // Lưu giá trị BMI
    @Published var bmiCategory: String = "" // Phân loại BMI
    @Published var dayMode: WorkMode = .balanced // Chế độ làm việc theo ngày
    @Published var weekMode: WorkMode = .balanced // Chế độ làm việc theo tuần
    @Published var monthMode: WorkMode = .balanced // Chế độ làm việc theo tháng
    @Published var yearMode: WorkMode = .balanced // Chế độ làm việc theo năm
    
    // MARK: - Private Properties
    private let taskVM: TaskViewModel
    private let eventVM: EventViewModel
    private let userId: Int?
    private let baseURL = "http://localhost/SmartTask_API/" // Đồng bộ với EventViewModel
    private let dayModeKey = "dayWorkMode"
    private let weekModeKey = "weekWorkMode"
    private let monthModeKey = "monthWorkMode"
    private let yearModeKey = "yearWorkMode"
    
    // MARK: - Codable Structs
    struct UserHealthResponse: Codable {
        let weight: Float?
        let height: Float?
    }
    
    struct UserHealthPayload: Codable {
        let userId: Int
        let weight: Float
        let height: Float
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case weight
            case height
        }
    }
    
    // MARK: - Initialization
    init(taskVM: TaskViewModel, eventVM: EventViewModel, userId: Int?) {
        self.taskVM = taskVM
        self.eventVM = eventVM
        self.userId = userId
        // Khôi phục chế độ làm việc từ UserDefaults
        if let savedDayModeRaw = UserDefaults.standard.string(forKey: dayModeKey),
           let savedDayMode = WorkMode(rawValue: savedDayModeRaw) {
            self.dayMode = savedDayMode
        }
        if let savedWeekModeRaw = UserDefaults.standard.string(forKey: weekModeKey),
           let savedWeekMode = WorkMode(rawValue: savedWeekModeRaw) {
            self.weekMode = savedWeekMode
        }
        if let savedMonthModeRaw = UserDefaults.standard.string(forKey: monthModeKey),
           let savedMonthMode = WorkMode(rawValue: savedMonthModeRaw) {
            self.monthMode = savedMonthMode
        }
        if let savedYearModeRaw = UserDefaults.standard.string(forKey: yearModeKey),
           let savedYearMode = WorkMode(rawValue: savedYearModeRaw) {
            self.yearMode = savedYearMode
        }
    }
    
    // MARK: - API Methods
    func saveUserMeasurements() {
        guard let userId = userId,
              let weightValue = Float(weight),
              let heightValue = Float(height) else {
            print("❌ Vui lòng nhập số hợp lệ cho cân nặng, chiều cao và đảm bảo userId hợp lệ")
            return
        }
        
        let url = URL(string: "\(baseURL)user_health.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload = UserHealthPayload(userId: userId, weight: weightValue, height: heightValue)
        do {
            request.httpBody = try JSONEncoder().encode(payload)
            print("📤 Gửi payload: \(String(data: request.httpBody!, encoding: .utf8) ?? "Không encode được")")
            
            URLSession.shared.dataTask(with: request) { data, response, _ in
                guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                    print("❌ Không nhận được dữ liệu từ server")
                    return
                }
                print("📥 Response: \(responseString)")
                
                if responseString.contains("Measurements updated successfully") {
                    DispatchQueue.main.async {
                        self.bmi = self.calculateBMI(weight: weightValue, height: heightValue)
                        self.bmiCategory = self.categorizeBMI(bmi: self.bmi!)
                        print("✅ Đã lưu: Cân nặng = \(weightValue) kg, Chiều cao = \(heightValue) cm, BMI = \(String(format: "%.1f", self.bmi!))")
                        self.analyzeWorkload()
                    }
                }
            }.resume()
        } catch {
            print("❌ Lỗi encode payload: \(error)")
        }
    }
    
    func fetchUserHealth(completion: @escaping () -> Void = {}) {
        guard let userId = userId,
              let url = URL(string: "\(baseURL)get_user_health.php?user_id=\(userId)") else {
            print("❌ Error: userId or URL is nil")
            return
        }
        
        // Tải tasks và events
        taskVM.fetchTasks()
        eventVM.fetchEvents(forUserId: userId)
        
        // Tải health data
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data,
                  let responseString = String(data: data, encoding: .utf8) else {
                print("❌ Không nhận được dữ liệu từ server")
                return
            }
            print("📥 Response: \(responseString)")
            
            do {
                let healthData = try JSONDecoder().decode(UserHealthResponse.self, from: data)
                DispatchQueue.main.async {
                    if let weight = healthData.weight {
                        self.weight = String(weight)
                    }
                    if let height = healthData.height {
                        self.height = String(height)
                    }
                    if let w = Float(self.weight), let h = Float(self.height) {
                        self.bmi = self.calculateBMI(weight: w, height: h)
                        self.bmiCategory = self.categorizeBMI(bmi: self.bmi!)
                    }
                    print("✅ Đã tải: Cân nặng = \(self.weight), Chiều cao = \(self.height)")
                    self.analyzeWorkload()
                    completion()
                }
            } catch {
                print("❌ Lỗi decode JSON: \(error)")
            }
        }.resume()
    }
    
    // MARK: - BMI Calculations
    func calculateBMI(weight: Float, height: Float) -> Float {
        let heightInMeters = height / 100 // Chuyển cm sang m
        return weight / (heightInMeters * heightInMeters)
    }
    
    func categorizeBMI(bmi: Float) -> String {
        switch bmi {
        case ..<18.5:
            return "Thiếu cân"
        case 18.5..<25:
            return "Bình thường"
        case 25..<30:
            return "Thừa cân"
        case 30...:
            return "Béo phì"
        default:
            return "Không xác định"
        }
    }
    
    func bmiColor(for bmi: Float) -> Color {
        switch bmi {
        case ..<18.5:
            return .yellow // Thiếu cân
        case 18.5..<25:
            return .green  // Bình thường
        case 25..<30:
            return .orange // Thừa cân
        case 30...:
            return .red    // Béo phì
        default:
            return .gray
        }
    }
    
    // MARK: - Workload Analysis
    func analyzeWorkload() {
        let today = Date()
        let calendar = Calendar.current
        
        // Phân tích theo ngày
        let dayTasks = taskVM.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: today) && !task.isCompleted
        }
        let dayEvents = eventVM.events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: today)
        }
        let dayCount = dayTasks.count + dayEvents.count
        let dayResult = analyzePeriod(count: dayCount, mode: dayMode)
        dayStatus = dayResult.status
        dayColor = dayResult.color
        
        // Phân tích theo tuần
        let weekRange = calendar.dateInterval(of: .weekOfYear, for: today)!
        var weekDays: [(date: Date, status: String)] = []
        var currentDate = weekRange.start
        while currentDate < weekRange.end {
            let tasks = taskVM.tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: currentDate) && !task.isCompleted
            }
            let events = eventVM.events.filter { event in
                calendar.isDate(event.startDate, inSameDayAs: currentDate)
            }
            let count = tasks.count + events.count
            let result = analyzePeriod(count: count, mode: weekMode)
            weekDays.append((date: currentDate, status: result.status))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        let weekResult = analyzePeriodStatus(days: weekDays)
        weekStatus = weekResult.status
        weekColor = weekResult.color
        
        // Phân tích theo tháng
        let monthRange = calendar.dateInterval(of: .month, for: today)!
        var monthDays: [(date: Date, status: String)] = []
        currentDate = monthRange.start
        while currentDate < monthRange.end {
            let tasks = taskVM.tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: currentDate) && !task.isCompleted
            }
            let events = eventVM.events.filter { event in
                calendar.isDate(event.startDate, inSameDayAs: currentDate)
            }
            let count = tasks.count + events.count
            let result = analyzePeriod(count: count, mode: monthMode)
            monthDays.append((date: currentDate, status: result.status))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        let monthResult = analyzePeriodStatus(days: monthDays)
        monthStatus = monthResult.status
        monthColor = monthResult.color
        
        // Phân tích theo năm
        let yearRange = calendar.dateInterval(of: .year, for: today)!
        var yearDays: [(date: Date, status: String)] = []
        currentDate = yearRange.start
        while currentDate < yearRange.end {
            let tasks = taskVM.tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return calendar.isDate(dueDate, inSameDayAs: currentDate) && !task.isCompleted
            }
            let events = eventVM.events.filter { event in
                calendar.isDate(event.startDate, inSameDayAs: currentDate)
            }
            let count = tasks.count + events.count
            let result = analyzePeriod(count: count, mode: yearMode)
            yearDays.append((date: currentDate, status: result.status))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        let yearResult = analyzePeriodStatus(days: yearDays)
        yearStatus = yearResult.status
        yearColor = yearResult.color
        
        // Phân tích tổng hợp
        let overallResult = analyzeOverall()
        overallStatus = overallResult.status
        overallColor = overallResult.color
        
        // Lưu chế độ làm việc
        UserDefaults.standard.set(dayMode.rawValue, forKey: dayModeKey)
        UserDefaults.standard.set(weekMode.rawValue, forKey: weekModeKey)
        UserDefaults.standard.set(monthMode.rawValue, forKey: monthModeKey)
        UserDefaults.standard.set(yearMode.rawValue, forKey: yearModeKey)
        
        print("📊 Phân tích: Ngày (\(dayTasks.count) công việc, \(dayEvents.count) sự kiện) -> \(dayStatus) | Tuần (\(weekDays.count) ngày, trạng thái: \(weekStatus)) | Tháng (\(monthDays.count) ngày, trạng thái: \(monthStatus)) | Năm (\(yearDays.count) ngày, trạng thái: \(yearStatus)) | Tổng hợp -> \(overallStatus)")
    }
    
    // MARK: - Helper Methods
    private func analyzePeriod(count: Int, mode: WorkMode) -> (status: String, color: Color) {
        var baseThreshold: (low: Int, high: Int)
        
        // Điều chỉnh ngưỡng dựa trên chế độ
        switch mode {
        case .relaxed:
            baseThreshold = (2, 4)
        case .balanced:
            baseThreshold = (3, 6)
        case .tryhard:
            baseThreshold = (5, 8)
        }
        
        // Điều chỉnh thêm dựa trên BMI
        if let bmi = bmi {
            switch bmi {
            case ..<18.5: // Thiếu cân
                baseThreshold.low -= 1
                baseThreshold.high -= 1
            case 25...:   // Thừa cân/Béo phì
                baseThreshold.low -= 1
                baseThreshold.high -= 1
            default:      // Bình thường
                break
            }
        }
        
        // Đảm bảo ngưỡng không âm
        baseThreshold.low = max(0, baseThreshold.low)
        baseThreshold.high = max(0, baseThreshold.high)
        
        // Xác định trạng thái
        switch count {
        case 0...baseThreshold.low:
            return ("Ổn áp", .green)
        case (baseThreshold.low + 1)...baseThreshold.high:
            return ("Vừa đủ", .orange)
        default:
            return ("Quá mức", .red)
        }
    }
    
    private func analyzePeriodStatus(days: [(date: Date, status: String)]) -> (status: String, color: Color) {
        // Đếm số ngày cho từng trạng thái
        let stableDays = days.filter { $0.status == "Ổn áp" }.count
        let justRightDays = days.filter { $0.status == "Vừa đủ" }.count
        let overDays = days.filter { $0.status == "Quá mức" }.count
        let totalDays = days.count
        
        // Nếu không có dữ liệu, trả về trạng thái mặc định
        guard totalDays > 0 else {
            return ("Ổn áp", .green)
        }
        
        // Điều chỉnh trọng số dựa trên BMI
        var overWeightFactor: Double = 1.0
        if let bmi = bmi {
            if bmi >= 30 { // Béo phì
                overWeightFactor = 1.5 // Tăng cảnh báo "Quá mức"
            } else if bmi >= 25 { // Thừa cân
                overWeightFactor = 1.2
            } else if bmi < 18.5 { // Thiếu cân
                overWeightFactor = 0.8 // Giảm cảnh báo "Quá mức"
            }
        }
        
        // Tính số ngày "Quá mức" có trọng số
        let weightedOverDays = Double(overDays) * overWeightFactor
        let stableRatio = Double(stableDays) / Double(totalDays)
        let justRightRatio = Double(justRightDays) / Double(totalDays)
        let weightedOverRatio = weightedOverDays / Double(totalDays)
        
        // Kiểm tra chuỗi liên tục "Quá mức" trong 3 ngày gần nhất
        let recentDays = days.suffix(3)
        let recentOverCount = recentDays.filter { $0.status == "Quá mức" }.count
        if recentOverCount >= 3 {
            return ("Quá mức", .red)
        }
        
        // Trường hợp "Quá mức" chiếm ưu thế (tỷ lệ có trọng số >= 50%)
        if weightedOverRatio >= 0.5 {
            return ("Quá mức", .red)
        }
        
        // Trường hợp "Vừa đủ" chiếm ưu thế
        if justRightRatio >= stableRatio && justRightRatio > weightedOverRatio {
            return ("Vừa đủ", .orange)
        }
        
        // Trường hợp "Ổn áp" chiếm ưu thế hoặc cân bằng
        if stableRatio >= justRightRatio && stableRatio >= weightedOverRatio {
            return ("Ổn áp", .green)
        }
        
        // Mặc định ưu tiên "Vừa đủ" nếu có
        if justRightDays > 0 {
            return ("Vừa đủ", .orange)
        }
        
        // Cuối cùng, trả về "Ổn áp"
        return ("Ổn áp", .green)
    }
    
    private func analyzeOverall() -> (status: String, color: Color) {
        let statuses = [yearStatus, monthStatus, weekStatus, dayStatus]
        let overCount = statuses.filter { $0 == "Quá mức" }.count
        let justRightCount = statuses.filter { $0 == "Vừa đủ" }.count
        let stableCount = statuses.filter { $0 == "Ổn áp" }.count
        
        // Ưu tiên Năm và Tháng, sau đó đến Tuần
        if yearStatus == "Ổn áp" || monthStatus == "Ổn áp" {
            return ("Ổn áp", .green)
        }
        if yearStatus == "Vừa đủ" || monthStatus == "Vừa đủ" {
            return ("Vừa đủ", .orange)
        }
        if weekStatus == "Ổn áp" && dayStatus != "Quá mức" {
            return ("Ổn áp", .green)
        }
        if weekStatus == "Vừa đủ" && dayStatus != "Quá mức" {
            return ("Vừa đủ", .orange)
        }
        
        // Nếu có nhiều "Quá mức", đặc biệt ở Tuần hoặc Ngày
        if overCount >= 2 && (weekStatus == "Quá mức" || dayStatus == "Quá mức") {
            return ("Quá mức", .red)
        }
        
        // Mặc định dựa trên số lượng
        if justRightCount >= stableCount {
            return ("Vừa đủ", .orange)
        }
        return ("Ổn áp", .green)
    }
}
