//
//  CategoryModel.swift
//  SmartTask
//
//  Created by Loi Nguyen on 20/3/25.
//

import Foundation

class CategoryViewModel: ObservableObject {
    @Published var categories: [Category] = []
    
    // Lấy danh sách danh mục từ API
    func fetchCategories() {
        guard let url = URL(string: "http://localhost/SmartTask_API/get_categories.php") else {
            print("❌ Error: URL is nil")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("❌ Lỗi khi tải categories:", error)
                return
            }
            
            guard let data = data, !data.isEmpty else {
                print("❌ Không nhận được dữ liệu từ server")
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Categories JSON:", jsonString)
            }
            
            do {
                let decoded = try JSONDecoder().decode([Category].self, from: data)
                DispatchQueue.main.async {
                    self.categories = decoded
                    print("✅ Đã tải \(decoded.count) categories")
                }
            } catch {
                print("❌ Lỗi khi decode categories: \(error.localizedDescription)")            }
        }.resume()
    }
    
    // Thêm danh mục mới
    func createCategory(name: String, isHidden: Bool = false, color: String? = nil, icon: String? = nil) {
        guard let url = URL(string: "http://localhost/SmartTask_API/create_category.php") else {
            print("❌ Error: URL is nil")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let newCategory = Category(id: 0, name: name, isHidden: isHidden, color: color, icon: icon) // id tạm là 0, server sẽ trả lại id thật
        
        do {
            let jsonData = try JSONEncoder().encode(newCategory)
            request.httpBody = jsonData
            print("JSON gửi đi:", String(data: jsonData, encoding: .utf8) ?? "Không decode được")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Lỗi khi gửi request:", error)
                    return
                }
                
                guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                    print("❌ Không nhận được dữ liệu từ server")
                    return
                }
                print("Response từ server:", responseString)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                    do {
                        let createdCategory = try JSONDecoder().decode(Category.self, from: data)
                        DispatchQueue.main.async {
                            self.categories.append(createdCategory)
                            print("✅ Category đã được thêm thành công: \(createdCategory.name)")
                        }
                    } catch {
                        print("Lỗi khi decode response:", error)
                    }
                } else {
                    print("❌ Lỗi server. Status code:", (response as? HTTPURLResponse)?.statusCode ?? -1)                }
            }.resume()
        } catch {
            print("❌ Lỗi khi encode JSON:", error)
        }
    }
    
    // Cập nhật danh mục
    func updateCategory(category: Category) {
        guard let url = URL(string: "http://localhost/SmartTask_API/update_category.php") else {
            print("❌ Error: URL is nil")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONEncoder().encode(category)
            request.httpBody = jsonData
            print("JSON gửi đi:", String(data: jsonData, encoding: .utf8) ?? "Không decode được")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Lỗi khi gửi request:", error)
                    return
                }
                
                guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                    print("❌ Không nhận được dữ liệu từ server")
                    return
                }
                print("Response từ server:", responseString)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    do {
                        let updatedCategory = try JSONDecoder().decode(Category.self, from: data)
                        DispatchQueue.main.async {
                            if let index = self.categories.firstIndex(where: { $0.id == updatedCategory.id }) {
                                self.categories[index] = updatedCategory
                                print("✅ Category đã được cập nhật: \(updatedCategory.name)")
                            }
                        }
                    } catch {
                        print("Lỗi khi decode response:", error)
                    }
                } else {
                    print("❌ Lỗi server. Status code:", (response as? HTTPURLResponse)?.statusCode ?? -1)                }
            }.resume()
        } catch {
            print("❌ Lỗi khi encode JSON:", error)
        }
    }
    
    // Xóa danh mục
    func deleteCategory(id: Int) {
        guard let url = URL(string: "http://localhost/SmartTask_API/delete_category.php") else {
            print("❌ Error: URL is nil")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Int] = ["id": id]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Lỗi khi gửi request:", error)
                return
            }
            
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                print("❌ Không nhận được dữ liệu từ server")
                return
            }
            print("Response từ server:", responseString)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                DispatchQueue.main.async {
                    self.categories.removeAll { $0.id == id }
                    print("✅ Category đã được xóa thành công! ID: \(id)")
                }
            } else {
                print("❌ Lỗi server. Status code:", (response as? HTTPURLResponse)?.statusCode ?? -1)            }
        }.resume()
    }
}
