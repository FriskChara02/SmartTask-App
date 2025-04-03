# 🚀 SmartTask-App - Ứng dụng quản lý công việc & thời gian biểu

![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift) ![SwiftUI](https://img.shields.io/badge/SwiftUI-5.9-purple?style=flat-square&logo=apple) ![XAMPP](https://img.shields.io/badge/XAMPP-8.2.12-orange?style=flat-square&logo=xampp) ![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?style=flat-square&logo=mysql) ![PHP](https://img.shields.io/badge/PHP-8.2-blue?style=flat-square&logo=php)

📅 **SmartTask-App** là ứng dụng iOS quản lý công việc và thời gian biểu, được xây dựng bằng Swift và SwiftUI. Ứng dụng kết nối với API PHP tự viết, sử dụng XAMPP và MySQL để lưu trữ dữ liệu, giúp bạn tổ chức công việc, sự kiện, và tối ưu hóa năng suất.

🔗 **Demo**: (Updating...)

📌 **GitHub**: [https://github.com/FriskChara02/SmartTask-App](https://github.com/FriskChara02/SmartTask-App)

---

## 🌟 Tính năng chính

- ✔ Quản lý công việc với TaskViewModel (thêm, sửa, xóa, ưu tiên).
- ✔ Theo dõi sự kiện qua EventViewModel và giao diện Calendar View.
- ✔ Quản lý danh mục công việc/sự kiện với CategoryViewModel.
- ✔ Thông báo nhắc nhở qua NotificationsViewModel.
- ✔ Tùy chỉnh cài đặt cá nhân bằng SettingsViewModel.
- ✔ Đăng ký/đăng nhập bảo mật với AuthViewModel (JWT).
- ✔ Quản lý hồ sơ người dùng qua UserViewModel.

(Updating...)

---

## 🏗 Công nghệ sử dụng

| Công nghệ         | Mô tả                            | Icon                          |
|-------------------|----------------------------------|-------------------------------|
| **Swift**         | Ngôn ngữ lập trình iOS           | ![Swift](https://img.shields.io/badge/-Swift-FA7343?logo=swift) |
| **SwiftUI**       | Framework giao diện iOS          | ![SwiftUI](https://img.shields.io/badge/-SwiftUI-000000?logo=apple) |
| **XAMPP**         | Môi trường phát triển cục bộ     | ![XAMPP](https://img.shields.io/badge/-XAMPP-FB7A24?logo=xampp) |
| **MySQL**         | Cơ sở dữ liệu quan hệ            | ![MySQL](https://img.shields.io/badge/-MySQL-4479A1?logo=mysql) |
| **PHP**           | API backend                      | ![PHP](https://img.shields.io/badge/-PHP-777BB4?logo=php) |
| **MVVM**          | Kiến trúc ứng dụng               | ![MVVM](https://img.shields.io/badge/-MVVM-000000) |

---

## 📂 Cấu trúc dự án

```
/SmartTask-App
├── SmartTask.xcodeproj      # Dự án Xcode
├── SmartTask/              # Source code Swift
│   ├── ViewModels/         # AuthViewModel.swift, TaskViewModel.swift, EventViewModel.swift, ...
│   ├── Models/            # CategoryModel.swift, ...
│   ├── Views/             # Giao diện SwiftUI
│   │   ├── Authentication/ # Đăng ký, đăng nhập
│   │   ├── Components/    # Các thành phần UI tái sử dụng
│   │   ├── Events/        # Giao diện sự kiện
│   │   ├── Health/        # Giao diện cảnh báo sức khỏe
│   │   ├── Home/          # Trang chính
│   │   ├── Settings/      # Cài đặt
│   │   └── Categories/    # Danh mục
│   ├── Utils/             # Công cụ hỗ trợ
│   └── Services/          # Xử lý API calls
├── api/                   # API PHP tự viết
│   └── (các file PHP)     # Xử lý kết nối MySQL
├── SmartTask_DB.sql       # Schema và dữ liệu mẫu MySQL
└── README.md             # File này
```

---

## 📥 Cài đặt & Chạy ứng dụng

1. **Clone dự án**:
   ```bash
   git clone https://github.com/FriskChara02/SmartTask-App.git
   cd SmartTask-App
   ```

2. **Cài đặt XAMPP và MySQL**:
   - Cài XAMPP và khởi động Apache + MySQL.
   - Tạo database `smarttask_db` trong phpMyAdmin.
   - Import file `SmartTask_DB.sql`:
     ```bash
     mysql -u root -p smarttask_db < SmartTask_DB.sql
     ```

3. **Cấu hình API PHP**:
   - Copy thư mục `api/` vào `/Applications/XAMPP/xamppfiles/htdocs/`.
   - Đảm bảo API chạy tại `http://localhost/api/` (cập nhật URL trong `Services/` nếu cần).

4. **Mở dự án trong Xcode**:
   ```bash
   open SmartTask.xcodeproj
   ```
   - Chọn iPhone Simulator hoặc thiết bị thật → Nhấn **Run**.

---

## 🎯 Lộ trình phát triển (Roadmap)

- ✅ Đăng ký/đăng nhập với API PHP và MySQL.
- ✅ Quản lý công việc (TaskViewModel).
- ✅ Quản lý sự kiện (EventViewModel).
- ✅ Quản lý danh mục (CategoryViewModel).
- 🚧 Tích hợp thông báo (NotificationsViewModel).
- 🚧 Tùy chỉnh cài đặt (SettingsViewModel).
- 🚀 Cảnh báo sức khỏe khi lịch trình quá tải (Sắp tới).

---

## 🤝 Đóng góp

Muốn đóng góp cho **SmartTask-App**? Hãy:
1. Fork repo.
2. Tạo branch mới (`git checkout -b feature/ten-tinh-nang`).
3. Commit thay đổi (`git commit -m "Mô tả thay đổi"`).
4. Push lên branch (`git push origin feature/ten-tinh-nang`).
5. Tạo Pull Request.

---

## 📧 Liên hệ

- 📌 **GitHub**: [FriskChara02](https://github.com/FriskChara02)
- 📌 **Email**: loi.nguyenbao02@gmail.com

---

## 🚀 Hỗ trợ dự án

Nếu bạn thích **SmartTask-App**, hãy ⭐ repo này để ủng hộ mình tiếp tục phát triển nhé! 🎉
