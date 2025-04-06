import Foundation

class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationsModel] = []
    
    // API base URL (dùng URL thật từ XAMPP của bạn)
    private let baseURL = "http://localhost/SmartTask_API"
    
    // Lấy tất cả thông báo từ API
    func fetchNotifications() {
        guard let url = URL(string: "\(baseURL)/notifications.php") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601 // Đảm bảo giải mã ngày đúng
                    let decoded = try decoder.decode([NotificationsModel].self, from: data)
                    DispatchQueue.main.async {
                        self.notifications = decoded
                    }
                } catch {
                    print("Error decoding notifications: \(error)")
                }
            }
        }.resume()
    }
    
    // Thêm thông báo mới
    func addNotification(task: TaskModel) {
        guard let url = URL(string: "\(baseURL)/notifications.php") else { return }
        
        let newNotification = NotificationsModel(
            id: UUID().uuidString,
            message: "Bạn đã thêm task '\(task.title)' thành công",
            taskId: task.id,
            isRead: false,
            createdAt: Date()
        )
        
        print("Task ID trong thông báo: \(String(describing: task.id))")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601 // Đảm bảo định dạng ngày đúng
            let jsonData = try encoder.encode(newNotification)
            print("JSON gửi đi:", String(data: jsonData, encoding: .utf8) ?? "Không decode được")
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error adding notification: \(error)")
                    return
                }
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response từ server:", responseString)
                }
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 201 {
                    DispatchQueue.main.async {
                        self.notifications.append(newNotification)
                    }
                }
            }.resume()
        } catch {
            print("Error encoding notification: \(error)")
        }
    }
    
    // Đánh dấu thông báo là đã đọc
    func markAsRead(notificationId: String) {
        guard let url = URL(string: "\(baseURL)/notifications.php?id=\(notificationId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Bool] = ["is_read": true]
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if error == nil {
                DispatchQueue.main.async {
                    if let index = self?.notifications.firstIndex(where: { $0.id == notificationId }) {
                        self?.notifications[index].isRead = true
                    }
                }
            }
        }.resume()
    }
    
    // Đánh dấu tất cả là đã đọc
    func markAllAsRead() {
        guard let url = URL(string: "\(baseURL)/notifications.php?mark_all=true") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.notifications.indices.forEach { self?.notifications[$0].isRead = true }
                }
            }
        }.resume()
    }
    
    // Xóa thông báo
    func deleteNotification(notificationId: String) {
        guard let url = URL(string: "\(baseURL)/notifications.php?id=\(notificationId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.notifications.removeAll { $0.id == notificationId }
                }
            }
        }.resume()
    }
    
    // Xóa nhiều thông báo cùng lúc
    func deleteNotifications(ids: [String]) {
        guard let url = URL(string: "\(baseURL)/notifications.php") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["ids": ids]
        request.httpBody = try? JSONEncoder().encode(body)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if error == nil {
                DispatchQueue.main.async {
                    self?.notifications.removeAll { ids.contains($0.id) }
                }
            }
        }.resume()
    }
    
    // Đếm số thông báo chưa đọc
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
}
