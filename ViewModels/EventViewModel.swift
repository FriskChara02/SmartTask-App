//
//  EventViewModel.swift
//  SmartTask
//
//  Created by Loi Nguyen on 14/3/25.
//

import Foundation
import Combine
import UserNotifications

class EventViewModel: ObservableObject {
    @Published var events: [EventModel] = []
    @Published var completedEvents: [EventModel] = []
    @Published var conflictMessage: String?
    
    private let reminderManager = SmartReminderManager.shared
    private var eventHistory: [EventHistory] = []
    private let baseURL = "http://localhost/SmartTask_API/"
    
    struct EventHistory {
        let eventId: Int
        let completedAt: Date
        let duration: TimeInterval?
    }
    
    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Đã được cấp quyền thông báo")
            } else if let error = error {
                print("❌ Lỗi quyền thông báo: \(error)")
            }
        }
    }
    
    struct EventCompletionPayload: Codable {
        let eventId: Int
        let completedAt: String
        let duration: Int
        
        enum CodingKeys: String, CodingKey {
            case eventId = "event_id"
            case completedAt = "completed_at"
            case duration
        }
    }
    
    // Thêm sự kiện mới
    func addEvent(event: EventModel) {
        let (hasConflict, conflictingEventTitle) = checkForConflicts(with: event)
        if hasConflict {
            conflictMessage = "Lịch của bạn đã bị trùng bởi lịch '\(conflictingEventTitle ?? "không xác định")'."
            print("❌ Xung đột lịch: \(event.title)")
            return
        }
        
        let url = URL(string: "\(baseURL)create_event.php")!
        print("📡 Gửi POST: \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted({
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
            return formatter
        }())
        do {
            let body = try encoder.encode(event)
            request.httpBody = body
            print("📤 Payload: \(String(data: body, encoding: .utf8) ?? "Không encode được")")
        } catch {
            print("❌ Lỗi encode: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                print("❌ Không nhận được dữ liệu từ server")
                return
            }
            print("📥 Response: \(responseString)")
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                DispatchQueue.main.async {
                    if let id = json["id"] as? Int {
                        let updatedEvent = EventModel(
                            id: id,
                            userId: event.userId,
                            title: event.title,
                            description: event.description,
                            startDate: event.startDate,
                            endDate: event.endDate,
                            priority: event.priority,
                            isAllDay: event.isAllDay,
                            createdAt: event.createdAt,
                            updatedAt: Date()
                        )
                        self.events.append(updatedEvent)
                        print("✅ Thêm sự kiện mới: \(event.title) với ID: \(id)")
                        self.scheduleReminders(for: updatedEvent)
                        self.conflictMessage = nil
                        self.fetchEvents(forUserId: event.userId)
                        NotificationCenter.default.post(name: .dismissAddEvent, object: nil)
                    }
                }
            }
        }.resume()
    }
    
    // Cập nhật sự kiện
    func updateEvent(event: EventModel) {
        let url = URL(string: "\(baseURL)update_event.php")!
        print("📡 Gửi POST: \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted({
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") // Đồng bộ với server
            return formatter
        }())
        do {
            let body = try encoder.encode(event)
            request.httpBody = body
            print("📤 Payload: \(String(data: body, encoding: .utf8) ?? "Không encode được")")
        } catch {
            print("❌ Lỗi encode: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                return
            }
            print("📥 Response: \(responseString)")
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                DispatchQueue.main.async {
                    if json["message"] as? String == "Event updated" {
                        if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                            self.events[index] = event
                        }
                        print("✅ Sửa thành công: \(event.title) với ID: \(event.id)")
                        self.scheduleReminders(for: event)
                        self.fetchEvents(forUserId: event.userId)
                        NotificationCenter.default.post(name: .dismissAddEvent, object: nil)
                    }
                }
            }
        }.resume()
    }
    
    // Xóa sự kiện
    func deleteEvent(eventId: Int) {
        let url = URL(string: "\(baseURL)delete_event.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["id": eventId])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                DispatchQueue.main.async {
                    if json["error"] == nil {
                        self.events.removeAll { $0.id == eventId }
                    }
                }
            }
        }.resume()
    }
    
    // Đánh dấu sự kiện hoàn thành và lưu lịch sử
    func markEventCompleted(eventId: Int) {
        if let index = events.firstIndex(where: { $0.id == eventId }) {
            let event = events[index]
            let duration = Date().timeIntervalSince(event.startDate)
            let history = EventHistory(eventId: eventId, completedAt: Date(), duration: duration)
            eventHistory.append(history)
            completedEvents.append(event) // Lưu tạm trước khi xoá vì lúc mình ấn hoàn thành thì event đó sẽ chuyển xuống mục hoàn thành và bị xoá ở mục này
            events.remove(at: index)
            
            let url = URL(string: "\(baseURL)complete_event.php")!
            print("📡 Gửi POST: \(url.absoluteString)")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 10
            
            let payload = EventCompletionPayload(
                eventId: eventId,
                completedAt: ISO8601DateFormatter().string(from: Date()),
                duration: Int(duration)
            )
            
            do {
                request.httpBody = try JSONEncoder().encode(payload)
                print("📤 Payload: \(String(data: request.httpBody!, encoding: .utf8) ?? "Không encode được")")
            } catch {
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, _ in
                guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                    DispatchQueue.main.async {
                        self.events.insert(event, at: index)
                        self.completedEvents.removeAll { $0.id == eventId }
                    }
                    return
                }
                print("📥 Response: \(responseString)")
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    DispatchQueue.main.async {
                        if json["message"] as? String == "Event completed", let insertedId = json["inserted_history_id"] as? Int, insertedId > 0 {
                            self.deleteEvent(eventId: eventId)
                            print("✅ Hoàn thành: \(event.title)")
                            self.fetchEvents(forUserId: event.userId)
                            print("📋 Completed Events sau đồng bộ: \(self.completedEvents.map { $0.title })")
                            NotificationCenter.default.post(name: .dismissAddEvent, object: nil)
                        } else {
                            self.events.insert(event, at: index)
                            self.completedEvents.removeAll { $0.id == eventId }
                        }
                    }
                }
            }.resume()
            
            adjustRemindersBasedOnHabits()
        }
    }
    
    // Kiểm tra xung đột lịch
    private func checkForConflicts(with newEvent: EventModel) -> (Bool, String?) {
        for event in events {
            if event.id == newEvent.id { continue }
            let existingRange = event.startDate...(event.endDate ?? event.startDate)
            let newRange = newEvent.startDate...(newEvent.endDate ?? newEvent.startDate)
            if existingRange.overlaps(newRange) {
                return (true, event.title)
            }
        }
        return (false, nil)
    }
    
    // Lên lịch nhiều mốc nhắc nhở
    private func scheduleReminders(for event: EventModel) {
        let reminders = [
            (time: -1440, message: "Ngày mai có sự kiện: \(event.title)"), // 1 ngày trước
            (time: -60, message: "Sự kiện \(event.title) sẽ bắt đầu sau 1 giờ"), // 1 giờ trước
            (time: -5, message: "Sắp đến giờ: \(event.title)") // 5 phút trước
        ]
        
        reminders.forEach { reminder in
            reminderManager.scheduleReminder(for: event, minutesBefore: reminder.time, message: reminder.message)
        }
    }
    
    // Lấy danh sách sự kiện từ API
    func fetchEvents(forUserId userId: Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        
        let url = URL(string: "\(baseURL)get_events.php?user_id=\(userId)")!
        print("📡 Gửi GET: \(url.absoluteString)")
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                return
            }
            let jsonString = String(data: data, encoding: .utf8) ?? "Không decode được"
            print("📥 Response: \(jsonString)")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            do {
                let events = try decoder.decode([EventModel].self, from: data)
                DispatchQueue.main.async {
                    self.events = events
                    events.forEach { self.scheduleReminders(for: $0) }
                    print("✅ Đã tải \(events.count) events")
                }
            } catch {
                print("❌ Lỗi decode events: \(error)")
                return
            }
        }.resume()
        
        let historyUrl = URL(string: "\(baseURL)get_event_history.php?user_id=\(userId)")!
        print("📡 Gửi GET: \(historyUrl.absoluteString)")
        URLSession.shared.dataTask(with: historyUrl) { data, _, _ in
            guard let data = data else {
                return
            }
            let jsonString = String(data: data, encoding: .utf8) ?? "Không decode được"
            print("📥 Response: \(jsonString)")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            do {
                let completed = try decoder.decode([EventModel].self, from: data)
                DispatchQueue.main.async {
                    if !completed.isEmpty {
                        self.completedEvents = completed
                    }
                    print("✅ Đã tải \(completed.count) completed events")
                }
            } catch {
                print("❌ Lỗi decode completed events: \(error)")
                return
            }
        }.resume()
    }
    
    // Tìm khoảng thời gian trống trong ngày
    func suggestFreeTimeSlot(on date: Date, duration: TimeInterval = 3600) -> Date? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        // Sắp xếp sự kiện theo thời gian bắt đầu
        let sortedEvents = events.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
        
        // Nếu không có sự kiện nào, trả về thời gian hiện tại thay vì mặc định 9:00
        if sortedEvents.isEmpty {
            return date // Trả về ngày và giờ được truyền vào
        }
        
        // Kiểm tra từng khoảng trống
        var lastEndTime = startOfDay
        for event in sortedEvents {
            let eventStart = event.startDate
            if eventStart > lastEndTime {
                let gap = eventStart.timeIntervalSince(lastEndTime)
                if gap >= duration {
                    return lastEndTime // Trả về khoảng trống đầu tiên đủ lớn
                }
            }
            lastEndTime = max(lastEndTime, event.endDate ?? event.startDate)
        }
        
        // Kiểm tra khoảng trống từ cuối sự kiện đến cuối ngày
        if endOfDay.timeIntervalSince(lastEndTime) >= duration {
            return lastEndTime
        }
        
        return nil // Không tìm thấy khoảng trống
    }
    
    // Gợi ý thời gian tạo sự kiện dựa trên thói quen
    func suggestPreferredTime(on date: Date) -> Date {
        let preferredHour = mostFrequentHour() ?? 9 // Mặc định 9:00 nếu chưa có dữ liệu
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = preferredHour
        components.minute = 0
        return calendar.date(from: components) ?? date
    }
    
    // Tìm giờ thường xuyên tạo sự kiện
    private func mostFrequentHour() -> Int? {
        guard !eventHistory.isEmpty else { return nil }
        let hours = eventHistory.map { Calendar.current.component(.hour, from: $0.completedAt) }
        let frequency = Dictionary(grouping: hours, by: { $0 }).mapValues { $0.count }
        return frequency.max(by: { $0.value < $1.value })?.key
    }
    
    // Điều chỉnh nhắc nhở dựa trên thói quen
    private func adjustRemindersBasedOnHabits() {
        guard !eventHistory.isEmpty else { return }
        
        let avgDuration = eventHistory.compactMap { $0.duration }.reduce(0, +) / Double(eventHistory.count)
        let avgMinutesEarly = Int(avgDuration / 60) // Trung bình hoàn thành sớm bao nhiêu phút
        
        let reminders = [
            (time: -1440, message: "Ngày mai có sự kiện"), // 1 ngày trước
            (time: -60 - avgMinutesEarly, message: "Sự kiện sắp bắt đầu"), // Điều chỉnh theo thói quen
            (time: -5 - avgMinutesEarly / 2, message: "Sắp đến giờ") // Điều chỉnh nhẹ
        ]
        
        // Sử dụng reminders để lên lịch cho tất cả events
        for event in events {
            reminders.forEach { reminder in
                reminderManager.scheduleReminder(for: event, minutesBefore: reminder.time, message: reminder.message + ": \(event.title)")
            }
        }
    }
}

// Cuối file
extension Notification.Name {
    static let dismissAddEvent = Notification.Name("dismissAddEvent")
}
