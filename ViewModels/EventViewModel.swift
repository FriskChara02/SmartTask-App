import Foundation
import Combine
import UserNotifications
import GoogleAPIClientForREST_Calendar

class EventViewModel: ObservableObject {
    @Published var events: [EventModel] = []
    @Published var completedEvents: [EventModel] = []
    @Published var conflictMessage: String?
    @Published var errorMessage: String?
    @Published var userId: Int?
    
    private let reminderManager = SmartReminderManager.shared
    private var eventHistory: [EventHistory] = []
    private let baseURL = "http://localhost/SmartTask_API/"
    private let googleAuthVM: GoogleAuthViewModel
    
    struct EventHistory {
        let eventId: Int
        let completedAt: Date
        let duration: TimeInterval?
    }
    
    init(googleAuthVM: GoogleAuthViewModel) {
        self.googleAuthVM = googleAuthVM
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Đã được cấp quyền thông báo")
            } else if let error = error {
                print("❌ Lỗi quyền thông báo: \(error)")
            }
        }
        NotificationCenter.default.addObserver(self, selector: #selector(fetchEventsForDate(_:)), name: .fetchEventsForDate, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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

    // MARK: - Thêm sự kiện mới
        func addEvent(event: EventModel) {
            let (hasConflict, conflictingEventTitle) = checkForConflicts(with: event)
            if hasConflict {
                conflictMessage = "Lịch của bạn đã bị trùng bởi lịch '\(conflictingEventTitle ?? "không xác định")'."
                errorMessage = "Không thể thêm sự kiện: Lịch bị trùng với '\(conflictingEventTitle ?? "không xác định")'."
                print("❌ Xung đột lịch: \(event.title)")
                return
            }
            
            createLocalEvent(event)
        }
    
    // MARK: - Helper: Tạo sự kiện trên server
    private func createLocalEvent(_ event: EventModel) {
        let token = UserDefaults.standard.string(forKey: "authToken")
        print("🔍 authToken: \(token ?? "nil")") // ^^ [NEW] Log để debug token
        
        if token == nil {
            DispatchQueue.main.async {
                self.errorMessage = "Không tìm thấy token, lưu sự kiện cục bộ"
                self.events.append(event)
                self.scheduleReminders(for: event)
                print("⚠️ Thiếu authToken, lưu cục bộ sự kiện: \(event.title) với ID: \(event.id)") // ^^ [NEW] Log chi tiết
                NotificationCenter.default.post(name: .showLoginScreen, object: nil) // ^^ [NEW] Yêu cầu đăng nhập lại
            }
            return
        }
        
        let url = URL(string: "\(baseURL)create_event.php")!
        print("📡 Gửi POST: \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        print("🔍 Added Authorization header: Bearer \(token!)")
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
            DispatchQueue.main.async {
                self.errorMessage = "Lỗi encode dữ liệu sự kiện: \(error.localizedDescription)"
                self.events.append(event)
                self.scheduleReminders(for: event)
                print("⚠️ Lỗi encode, lưu cục bộ sự kiện: \(event.title) với ID: \(event.id)") // ^^ [NEW] Log chi tiết
            }
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                print("❌ Không nhận được dữ liệu từ server: \(error?.localizedDescription ?? "Không rõ")")
                DispatchQueue.main.async {
                    self.errorMessage = "Không thể lưu sự kiện vào server, đã lưu cục bộ"
                    self.events.append(event)
                    self.scheduleReminders(for: event)
                    print("⚠️ Lỗi server, lưu cục bộ sự kiện: \(event.title) với ID: \(event.id)") // ^^ [NEW] Log chi tiết
                    NotificationCenter.default.post(name: .dismissAddEvent, object: nil)
                }
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
                            updatedAt: Date(),
                            googleEventId: event.googleEventId
                        )
                        self.events.removeAll { $0.googleEventId == event.googleEventId && $0.id != id }
                        self.events.append(updatedEvent)
                        self.events.sort { $0.startDate < $1.startDate }
                        print("✅ Thêm sự kiện mới: \(event.title) với ID: \(id)")
                    } else {
                        self.errorMessage = "Lỗi server nhưng đã lưu cục bộ: \(responseString)"
                        self.events.append(event)
                        self.events.sort { $0.startDate < $1.startDate }
                        print("⚠️ Lỗi server, lưu cục bộ sự kiện: \(event.title) với ID: \(event.id)") // ^^ [NEW] Log chi tiết
                    }
                    self.scheduleReminders(for: event)
                    self.conflictMessage = nil
                    self.fetchEvents(forUserId: event.userId)
                    NotificationCenter.default.post(name: .dismissAddEvent, object: nil)
                }
            }
        }.resume()
    }
    
    // MARK: - Cập nhật sự kiện
    func updateEvent(event: EventModel) {
        let token = UserDefaults.standard.string(forKey: "authToken")
        print("🔍 authToken: \(token ?? "nil")") // ^^ [NEW] Log để debug token
        
        if token == nil {
            DispatchQueue.main.async {
                self.errorMessage = "Không tìm thấy token, cập nhật sự kiện cục bộ"
                if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                    self.events[index] = event
                    self.events.sort { $0.startDate < $1.startDate }
                    self.scheduleReminders(for: event)
                    print("⚠️ Thiếu authToken, cập nhật cục bộ sự kiện: \(event.title) với ID: \(event.id)") // ^^ [NEW] Log chi tiết
                    NotificationCenter.default.post(name: .showLoginScreen, object: nil) // ^^ [NEW] Yêu cầu đăng nhập lại
                }
            }
            return
        }
        
        let url = URL(string: "\(baseURL)update_event.php")!
        print("📡 Gửi POST: \(url.absoluteString)")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        print("🔍 Added Authorization header: Bearer \(token!)")
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
            DispatchQueue.main.async {
                self.errorMessage = "Lỗi encode dữ liệu sự kiện: \(error.localizedDescription)"
                if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                    self.events[index] = event
                    self.events.sort { $0.startDate < $1.startDate }
                    self.scheduleReminders(for: event)
                    print("⚠️ Lỗi encode, cập nhật cục bộ sự kiện: \(event.title) với ID: \(event.id)") // ^^ [NEW] Log chi tiết
                }
            }
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                print("❌ Không nhận được dữ liệu: \(error?.localizedDescription ?? "Không rõ")")
                DispatchQueue.main.async {
                    self.errorMessage = "Không thể cập nhật sự kiện trên server, đã cập nhật cục bộ"
                    if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                        self.events[index] = event
                        self.events.sort { $0.startDate < $1.startDate }
                        self.scheduleReminders(for: event)
                        print("⚠️ Lỗi server, cập nhật cục bộ sự kiện: \(event.title) với ID: \(event.id)") // ^^ [NEW] Log chi tiết
                    }
                }
                return
            }
            print("📥 Response: \(responseString)")
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               json["message"] as? String == "Event updated" {
                DispatchQueue.main.async {
                    if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                        self.events[index] = event
                        self.events.sort { $0.startDate < $1.startDate }
                        print("✅ Cập nhật UI: \(event.title) với ID: \(event.id)")
                    }
                    self.scheduleReminders(for: event)
                    
                    if let googleEventId = event.googleEventId, !googleEventId.isEmpty, googleEventId != "0" {
                        GoogleCalendarService.shared.updateEvent(
                            eventId: googleEventId,
                            title: event.title,
                            startDate: event.startDate,
                            endDate: event.endDate,
                            description: event.description
                        ) { result in
                            switch result {
                            case .success(let updatedEventId):
                                print("✅ Updated Google Calendar event: \(updatedEventId)")
                            case .failure(let error):
                                print("❌ Failed to update Google Calendar event: \(error)")
                                self.errorMessage = "Không thể cập nhật sự kiện trên Google Calendar: \(error.localizedDescription)"
                            }
                        }
                    }
                    let userId = self.userId ?? event.userId
                    self.fetchEvents(forUserId: userId)
                    NotificationCenter.default.post(name: .dismissAddEvent, object: nil)
                }
            } else {
                print("❌ Lỗi server: \(responseString)")
                DispatchQueue.main.async {
                    self.errorMessage = "Lỗi server nhưng đã cập nhật cục bộ: \(responseString)"
                    if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                        self.events[index] = event
                        self.events.sort { $0.startDate < $1.startDate }
                        self.scheduleReminders(for: event)
                        print("⚠️ Lỗi server, cập nhật cục bộ sự kiện: \(event.title) với ID: \(event.id)") // ^^ [NEW] Log chi tiết
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Xóa sự kiện
    func deleteEvent(eventId: Int) {
        let token = UserDefaults.standard.string(forKey: "authToken")
        print("🔍 authToken: \(token ?? "nil")") // ^^ [NEW] Log để debug token
        
        if token == nil {
            DispatchQueue.main.async {
                self.errorMessage = "Không tìm thấy token, xóa sự kiện cục bộ"
                self.events.removeAll { $0.id == eventId }
                self.events.sort { $0.startDate < $1.startDate }
                print("⚠️ Thiếu authToken, xóa cục bộ sự kiện ID: \(eventId)") // ^^ [NEW] Log chi tiết
                NotificationCenter.default.post(name: .showLoginScreen, object: nil) // ^^ [NEW] Yêu cầu đăng nhập lại
            }
            return
        }
        
        let url = URL(string: "\(baseURL)delete_event.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        print("🔍 Added Authorization header: Bearer \(token!)")
        request.httpBody = try? JSONEncoder().encode(["id": eventId])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               json["error"] == nil {
                DispatchQueue.main.async {
                    if let event = self.events.first(where: { $0.id == eventId }),
                       let googleEventId = event.googleEventId,
                       !googleEventId.isEmpty,
                       googleEventId != "0" {
                        GoogleCalendarService.shared.deleteEvent(eventId: googleEventId) { result in
                            switch result {
                            case .success:
                                print("✅ Deleted Google Calendar event: \(googleEventId)")
                            case .failure(let error):
                                print("❌ Failed to delete Google Calendar event: \(error)")
                                self.errorMessage = "Không thể xóa sự kiện trên Google Calendar: \(error.localizedDescription)"
                            }
                        }
                    } else {
                        print("⚠️ Skipping Google Calendar delete: Invalid or missing googleEventId")
                    }
                    self.events.removeAll { $0.id == eventId }
                    self.events.sort { $0.startDate < $1.startDate }
                    if let userId = self.userId {
                        self.fetchEvents(forUserId: userId)
                    }
                    print("✅ Xóa sự kiện ID: \(eventId)") // ^^ [NEW] Log chi tiết
                }
            } else {
                print("❌ Lỗi xóa sự kiện: \(error?.localizedDescription ?? "Không rõ")")
                DispatchQueue.main.async {
                    self.errorMessage = "Không thể xóa sự kiện từ server, đã xóa cục bộ"
                    self.events.removeAll { $0.id == eventId }
                    self.events.sort { $0.startDate < $1.startDate }
                    print("⚠️ Lỗi server, xóa cục bộ sự kiện ID: \(eventId)") // ^^ [NEW] Log chi tiết
                }
            }
        }.resume()
    }
    
    // MARK: - Đánh dấu sự kiện hoàn thành và lưu lịch sử
    func markEventCompleted(eventId: Int) {
        let token = UserDefaults.standard.string(forKey: "authToken")
        print("🔍 authToken: \(token ?? "nil")") // ^^ [NEW] Log để debug token
        
        if token == nil {
            DispatchQueue.main.async {
                self.errorMessage = "Không tìm thấy token, không thể hoàn thành sự kiện"
                print("⚠️ Thiếu authToken, không thể hoàn thành sự kiện ID: \(eventId)") // ^^ [NEW] Log chi tiết
                NotificationCenter.default.post(name: .showLoginScreen, object: nil) // ^^ [NEW] Yêu cầu đăng nhập lại
            }
            return
        }
        
        if let index = events.firstIndex(where: { $0.id == eventId }) {
            let event = events[index]
            let duration = Date().timeIntervalSince(event.startDate)
            let history = EventHistory(eventId: eventId, completedAt: Date(), duration: duration)
            eventHistory.append(history)
            completedEvents.append(event)
            events.remove(at: index)
            events.sort { $0.startDate < $1.startDate }
            
            let url = URL(string: "\(baseURL)complete_event.php")!
            print("📡 Gửi POST: \(url.absoluteString)")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
            print("🔍 Added Authorization header: Bearer \(token!)")
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
                DispatchQueue.main.async {
                    self.errorMessage = "Lỗi encode dữ liệu hoàn thành sự kiện"
                    self.events.insert(event, at: index)
                    self.events.sort { $0.startDate < $1.startDate }
                    self.completedEvents.removeAll { $0.id == eventId }
                    print("⚠️ Lỗi encode, khôi phục sự kiện: \(event.title) với ID: \(event.id)") // ^^ [NEW] Log chi tiết
                }
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, _ in
                guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                    DispatchQueue.main.async {
                        self.events.insert(event, at: index)
                        self.events.sort { $0.startDate < $1.startDate }
                        self.completedEvents.removeAll { $0.id == eventId }
                        self.errorMessage = "Không nhận được phản hồi từ server"
                        print("⚠️ Lỗi server, khôi phục sự kiện: \(event.title) với ID: \(event.id)") // ^^ [NEW] Log chi tiết
                    }
                    return
                }
                print("📥 Response: \(responseString)")
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    DispatchQueue.main.async {
                        if json["message"] as? String == "Event completed", let insertedId = json["inserted_history_id"] as? Int, insertedId > 0 {
                            self.deleteEvent(eventId: eventId)
                            print("✅ Hoàn thành: \(event.title) với ID: \(event.id)")
                            self.fetchEvents(forUserId: event.userId)
                            print("📋 Completed Events sau đồng bộ: \(self.completedEvents.map { $0.title })")
                            NotificationCenter.default.post(name: .dismissAddEvent, object: nil)
                        } else {
                            self.events.insert(event, at: index)
                            self.events.sort { $0.startDate < $1.startDate }
                            self.completedEvents.removeAll { $0.id == eventId }
                            self.errorMessage = "Lỗi server: \(responseString)"
                            print("⚠️ Lỗi server, khôi phục sự kiện: \(event.title) với ID: \(event.id)") // ^^ [NEW] Log chi tiết
                        }
                    }
                }
            }.resume()
            
            adjustRemindersBasedOnHabits()
        }
    }
    
    // MARK: - Kiểm tra xung đột lịch
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
    
    // MARK: - Lên lịch nhiều mốc nhắc nhở
    private func scheduleReminders(for event: EventModel) {
        SmartReminderManager.shared.removeExistingReminders(for: event)
        let reminders = [
            (time: -1440, message: "Ngày mai có sự kiện: \(event.title)"),
            (time: -60, message: "Sự kiện \(event.title) sẽ bắt đầu sau 1 giờ"),
            (time: -5, message: "Sắp đến giờ: \(event.title)")
        ]
        
        reminders.forEach { reminder in
            reminderManager.scheduleReminder(for: event, minutesBefore: reminder.time, message: reminder.message)
        }
    }
    
    // MARK: - Lấy danh sách sự kiện từ API
    func fetchEvents(forUserId userId: Int) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        
        let url = URL(string: "\(baseURL)get_events.php?user_id=\(userId)")!
        print("📡 Gửi GET: \(url.absoluteString)")
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                print("❌ Không nhận được dữ liệu từ server")
                DispatchQueue.main.async {
                    self.errorMessage = "Không nhận được dữ liệu từ server"
                }
                return
            }
            let jsonString = String(data: data, encoding: .utf8) ?? "Không decode được"
            print("📥 Response: \(jsonString)")
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            do {
                let events = try decoder.decode([EventModel].self, from: data)
                DispatchQueue.main.async {
                    self.events = events + self.events.filter { existing in
                        !events.contains { $0.id == existing.id || $0.googleEventId == existing.googleEventId }
                    }
                    self.events.sort { $0.startDate < $1.startDate }
                    self.userId = userId
                    events.forEach { self.scheduleReminders(for: $0) }
                    print("✅ Đã tải \(events.count) events")
                    print("📋 Current events: \(self.events.map { $0.title })")
                }
            } catch {
                print("❌ Lỗi decode events: \(error)")
                DispatchQueue.main.async {
                    self.errorMessage = "Lỗi decode dữ liệu sự kiện: \(error.localizedDescription)"
                }
            }
        }.resume()
        
        let historyUrl = URL(string: "\(baseURL)get_event_history.php?user_id=\(userId)")!
        print("📡 Gửi GET: \(historyUrl.absoluteString)")
        URLSession.shared.dataTask(with: historyUrl) { data, _, _ in
            guard let data = data else {
                print("❌ Không nhận được dữ liệu từ server")
                DispatchQueue.main.async {
                    self.errorMessage = "Không nhận được dữ liệu lịch sử sự kiện"
                }
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
                DispatchQueue.main.async {
                    self.errorMessage = "Lỗi decode dữ liệu lịch sử sự kiện: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
    
    // MARK: - Fetch sự kiện theo ngày (từ thông báo)
    @objc private func fetchEventsForDate(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let date = userInfo["date"] as? Date,
              let userId = userId else { return }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        GoogleCalendarService.shared.fetchEvents(from: startOfDay, to: endOfDay) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedEvents):
                    let newEvents = fetchedEvents.compactMap { (event: GTLRCalendar_Event) -> EventModel? in
                        guard let eventId = event.identifier,
                              let title = event.summary,
                              let startDate = event.start?.dateTime?.date else { return nil }
                        if self.events.contains(where: { $0.googleEventId == eventId }) {
                            print("⚠️ Bỏ qua sự kiện trùng: \(title) với googleEventId: \(eventId)")
                            return nil
                        }
                        let uniqueId = abs(UUID().uuidString.hashValue % 1000000)
                        return EventModel(
                            id: uniqueId,
                            userId: userId,
                            title: title,
                            description: event.descriptionProperty,
                            startDate: startDate,
                            endDate: event.end?.dateTime?.date,
                            priority: "Medium",
                            isAllDay: false,
                            createdAt: Date(),
                            updatedAt: Date(),
                            googleEventId: eventId
                        )
                    }
                    self.events.append(contentsOf: newEvents.filter { newEvent in
                        !self.events.contains { $0.googleEventId == newEvent.googleEventId || $0.id == newEvent.id }
                    })
                    self.events.sort { $0.startDate < $1.startDate }
                    newEvents.forEach { self.createLocalEvent($0) }
                    print("✅ Fetched \(newEvents.count) new events for date: \(date)")
                    print("📋 Current events after fetch: \(self.events.map { $0.title })")
                case .failure(let error):
                    print("❌ Failed to fetch events for date \(date): \(error)")
                    self.errorMessage = "Không thể tải sự kiện: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Tìm khoảng thời gian trống trong ngày
    func suggestFreeTimeSlot(on date: Date, duration: TimeInterval = 3600) -> Date? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let sortedEvents = events.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
        
        if sortedEvents.isEmpty {
            return date
        }
        
        var lastEndTime = startOfDay
        for event in sortedEvents {
            let eventStart = event.startDate
            if eventStart > lastEndTime {
                let gap = eventStart.timeIntervalSince(lastEndTime)
                if gap >= duration {
                    return lastEndTime
                }
            }
            lastEndTime = max(lastEndTime, event.endDate ?? event.startDate)
        }
        
        if endOfDay.timeIntervalSince(lastEndTime) >= duration {
            return lastEndTime
        }
        
        return nil
    }
    
    // MARK: - Gợi ý thời gian tạo sự kiện dựa trên thói quen
    func suggestPreferredTime(on date: Date) -> Date {
        let preferredHour = mostFrequentHour() ?? 9
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = preferredHour
        components.minute = 0
        return calendar.date(from: components) ?? date
    }
    
    // MARK: - Tìm giờ thường xuyên tạo sự kiện
    private func mostFrequentHour() -> Int? {
        guard !eventHistory.isEmpty else { return nil }
        let hours = eventHistory.map { Calendar.current.component(.hour, from: $0.completedAt) }
        let frequency = Dictionary(grouping: hours, by: { $0 }).mapValues { $0.count }
        return frequency.max(by: { $0.value < $1.value })?.key
    }
    
    // MARK: - Điều chỉnh nhắc nhở dựa trên thói quen
    private func adjustRemindersBasedOnHabits() {
        guard !eventHistory.isEmpty else { return }
        
        let avgDuration = eventHistory.compactMap { $0.duration }.reduce(0, +) / Double(eventHistory.count)
        let avgMinutesEarly = Int(avgDuration / 60)
        
        let reminders = [
            (time: -1440, message: "Ngày mai có sự kiện"),
            (time: -60 - avgMinutesEarly, message: "Sự kiện sắp bắt đầu"),
            (time: -5 - avgMinutesEarly / 2, message: "Sắp đến giờ")
        ]
        
        for event in events {
            reminders.forEach { reminder in
                reminderManager.scheduleReminder(for: event, minutesBefore: reminder.time, message: reminder.message + ": \(event.title)")
            }
        }
    }
}

extension Notification.Name {
    static let dismissAddEvent = Notification.Name("dismissAddEvent")
    static let fetchEventsForDate = Notification.Name("fetchEventsForDate")
    static let showLoginScreen = Notification.Name("showLoginScreen")
}
