import Foundation

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskModel] = []
    @Published var userId: Int?
    private let notificationsVM: NotificationsViewModel // Truyền qua init

    // Khởi tạo với notificationsVM
    init(notificationsVM: NotificationsViewModel) {
        self.notificationsVM = notificationsVM
    }

    // Lấy danh sách công việc theo userId
    func fetchTasks() {
        guard let userId = userId,
              let url = URL(string: "http://localhost/SmartTask_API/get_tasks.php?user_id=\(userId)") else {
            print("❌ Error: userId or URL is nil")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Lỗi khi tải tasks:", error)
                return
            }
            
            guard let data = data, !data.isEmpty else {
                print("❌ Không nhận được dữ liệu từ server")
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Tasks JSON:", jsonString)
            } else {
                print("❌ Không thể decode JSON thành string")
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let decodedTasks = try decoder.decode([TaskModel].self, from: data)
                DispatchQueue.main.async {
                    self.tasks = decodedTasks
                    print("✅ Đã tải \(decodedTasks.count) task")
                }
            } catch {
                print("Lỗi khi decode JSON:", error)
            }
        }.resume()
    }
    
    // Thêm công việc
    func addTask(title: String, description: String?, categoryId: Int, dueDate: Date?, priority: String = "Medium") {
        guard let userId = userId,
              let url = URL(string: "http://localhost/SmartTask_API/add_task.php") else {
            print("❌ Error: userId or URL is nil")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let newTask = TaskModel(id: nil, userId: userId, title: title, description: description, categoryId: categoryId, dueDate: dueDate, isCompleted: false, createdAt: nil, priority: priority)
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let jsonData = try encoder.encode(newTask)
            print("JSON gửi đi:", String(data: jsonData, encoding: .utf8) ?? "Không decode được")
            request.httpBody = jsonData
            
            URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                if let error = error {
                    print("❌ Lỗi khi gửi request:", error)
                    return
                }
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response từ server:", responseString)
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let id = json["id"] as? Int {
                        let taskWithId = TaskModel(
                            id: id,
                            userId: userId,
                            title: title,
                            description: description,
                            categoryId: categoryId,
                            dueDate: dueDate,
                            isCompleted: false,
                            createdAt: Date(),
                            priority: priority
                        )
                        DispatchQueue.main.async {
                            self?.tasks.append(taskWithId)
                            self?.notificationsVM.addNotification(task: taskWithId)
                        }
                    }
                }
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 201 {
                    print("✅ Task đã được thêm thành công!")
                    DispatchQueue.main.async {
                        self?.fetchTasks()
                    }
                } else {
                    print("❌ Lỗi server hoặc response không hợp lệ. Status code:", (response as? HTTPURLResponse)?.statusCode ?? -1)
                }
            }.resume()
        } catch {
            print("❌ Lỗi khi encode JSON:", error)
        }
    }

    // Trong TaskViewModel.swift
    func updateTask(task: TaskModel) {
        guard let id = task.id,
              let url = URL(string: "http://localhost/SmartTask_API/update_task.php?id=\(id)") else {
            print("❌ Error: Task ID or URL is nil")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(task)
            print("JSON gửi đi:", String(data: request.httpBody!, encoding: .utf8) ?? "Không decode được")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Lỗi khi gửi request:", error)
                    return
                }
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response từ server:", responseString)
                }
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    print("✅ Task đã được cập nhật thành công!")
                    DispatchQueue.main.async {
                        self.fetchTasks()
                    }
                }
            }.resume()
        } catch {
            print("❌ Lỗi khi encode JSON:", error)
        }
    }

    func deleteTask(id: Int) {
        guard let url = URL(string: "http://localhost/SmartTask_API/delete_task.php?id=\(id)") else {
            print("❌ Error: URL is nil")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi khi gửi request:", error)
                return
            }
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response từ server:", responseString)
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Task đã được xóa thành công! ID: \(id)")
                DispatchQueue.main.async {
                    self.fetchTasks()
                }
            } else {
                print("❌ Lỗi server. Status code:", (response as? HTTPURLResponse)?.statusCode ?? -1)
            }
        }.resume()
    }

    // Cập nhật trạng thái hoàn thành
    func toggleTaskCompletion(id: Int) {
        guard let url = URL(string: "http://localhost/SmartTask_API/toggle_task.php?id=\(id)") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("❌ Lỗi khi gửi request:", error)
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self.fetchTasks()
                }
            }
        }.resume()
    }
}
