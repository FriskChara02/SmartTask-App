# 🚀 SmartTask-App - Ứng dụng quản lý công việc & thời gian biểu

![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift) ![SwiftUI](https://img.shields.io/badge/SwiftUI-5.9-purple?style=flat-square&logo=apple) ![XAMPP](https://img.shields.io/badge/XAMPP-8.2.12-orange?style=flat-square&logo=xampp) ![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?style=flat-square&logo=mysql) ![PHP](https://img.shields.io/badge/PHP-8.2-blue?style=flat-square&logo=php)

❀ **SmartTask-App** là ứng dụng iOS quản lý công việc và thời gian biểu, được xây dựng bằng Swift và SwiftUI. Ứng dụng kết nối với API PHP tự viết, sử dụng XAMPP và MySQL để lưu trữ dữ liệu, giúp bạn tổ chức công việc, sự kiện và tối ưu hóa năng suất.

✦ **SmartTask** - Ứng dụng thông minh, hỗ trợ người dùng lên kế hoạch, tổ chức công việc, làm việc nhóm, kết bạn, nhắn tin vui vẻ và cải thiện sức khỏe bằng cách cân bằng khối lượng công việc với thời gian nghỉ ngơi.

🔗 **Demo**: (Updating...)

📌 **GitHub**: [https://github.com/FriskChara02/SmartTask-App](https://github.com/FriskChara02/SmartTask-App)

---

## 🌟 Tính năng chính

- ✅ **Quản lý công việc (Tasks)**
- ✅ **Quản lý sự kiện (Events)**
- ✅ **Theo dõi sức khỏe (Health)**
- ✅ **Kết nối bạn bè (Friends)**
- ✅ **Làm việc nhóm (Groups)**
- ✅ **Nhắn tin (Chat)**
- ✅ **Xem thời tiết (Weather)**
- ✅ **Đồng bộ Google Calendar**
- ✅ **Thông báo thông minh**
- ✅ **Quản lý hồ sơ & danh mục**
- ✅ **Phản hồi và đánh giá**
- ✅ **Đăng ký/đăng nhập bảo mật**

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
| **Google APIs**   | Đồng bộ Google Calendar, Weather | ![Google APIs](https://img.shields.io/badge/-Google%20APIs-4285F4?logo=google) |

---

## 📥 Cài đặt & Chạy ứng dụng

### 1. Clone dự án
```bash
git clone https://github.com/FriskChara02/SmartTask-App.git
cd SmartTask-App
```

### 2. Cài đặt thư viện phụ thuộc
- Đảm bảo đã cài **Xcode** (phiên bản 15.0 trở lên) và **Swift Package Manager**.
- Thêm các thư viện phụ thuộc sau vào dự án qua Swift Package Manager:
  - [EmojiKit](https://github.com/danielsaidi/EmojiKit.git)
  - [GTMAppAuth](https://github.com/google/GTMAppAuth.git)
  - [GTMSessionFetcher](https://github.com/google/gtm-session-fetcher.git)
  - [AppAuth-iOS](https://github.com/openid/AppAuth-iOS.git)
  - [Google API Client](https://github.com/google/google-api-objectivec-client-for-rest.git)
  - [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS.git)
- Mở `SmartTask.xcodeproj`, vào **File > Add Package Dependencies**, và nhập URL của các thư viện trên.

### 3. Cấu hình XAMPP và MySQL
- Cài đặt **XAMPP** (phiên bản 8.2.12 hoặc cao hơn) và khởi động **Apache** + **MySQL**.
- Mở **phpMyAdmin**, tạo cơ sở dữ liệu `smarttask_db`.
- Import file `SmartTask_DB.sql` vào cơ sở dữ liệu:
  ```bash
  mysql -u root -p smarttask_db < SmartTask_DB.sql
  ```

### 4. Cấu hình API PHP
- Copy thư mục `api/` vào `/Applications/XAMPP/xamppfiles/htdocs/` (macOS) hoặc thư mục tương ứng trên hệ điều hành của bạn.
- Đảm bảo API chạy tại `http://localhost/api/`. Nếu cần, cập nhật URL API trong file `Services/` của dự án.

### 5. Cấu hình Google Calendar API
- Tạo file `Config.swift` trong thư mục gốc của dự án, dựa trên mẫu `Config.sample.swift`.
- Thay thế các giá trị placeholder bằng thông tin Google API của bạn:
  ```swift
  struct Config {
      static let googleClientID = "YOUR_GOOGLE_CLIENT_ID"
      static let googleAPIKey = "YOUR_GOOGLE_API_KEY"
      static let googleRedirectURI = "YOUR_GOOGLE_REDIRECT_URI"
  }
  ```
- **Hướng dẫn lấy thông tin:**
  - **YOUR_GOOGLE_CLIENT_ID:** Lấy từ Google Cloud Console (Credentials > OAuth 2.0 Client IDs).
  - **YOUR_GOOGLE_API_KEY:** Lấy từ Google Cloud Console (Credentials > API Keys).
  - **YOUR_GOOGLE_REDIRECT_URI:** Thường có dạng `com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID:/oauth2redirect`.

### 6. Cấu hình Info.plist
- Mở file `Info.plist` trong dự án và cập nhật các giá trị sau:
  ```xml
  <key>CFBundleIdentifier</key>
  <string>Your_Bundle_Identifier</string>

  <key>GIDClientID</key>
  <string>YOUR_GOOGLE_CLIENT_ID</string>

  <key>CFBundleURLTypes</key>
  <array>
      <dict>
          <key>CFBundleTypeRole</key>
          <string>Editor</string>
          <key>CFBundleURLName</key>
          <string>Your_Bundle_Identifier</string>
          <key>CFBundleURLSchemes</key>
          <array>
              <string>com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID</string>
          </array>
      </dict>
  </array>
  ```
- **Hướng dẫn cập nhật:**
  - **Your_Bundle_Identifier:** Định danh duy nhất của ứng dụng (ví dụ: `com.friskchara.SmartTask`).
  - **YOUR_GOOGLE_CLIENT_ID:** ID client từ Google Cloud Console.
  - Đảm bảo các giá trị khớp với `Config.swift`.

### 7. Chạy ứng dụng ⟡
- Mở `SmartTask.xcodeproj` trong Xcode:
  ```bash
  open SmartTask.xcodeproj
  ```
- Chọn iPhone Simulator hoặc thiết bị thật, sau đó nhấn **Run** để chạy ứng dụng.

---

## 🤝 Đóng góp

Muốn đóng góp cho **SmartTask-App**? Hãy làm theo các bước sau:  
1. Fork repository này.  
2. Tạo branch mới: `git checkout -b feature/ten-tinh-nang`.  
3. Commit thay đổi: `git commit -m "Mô tả thay đổi"`.  
4. Push lên branch: `git push origin feature/ten-tinh-nang`.  
5. Tạo **Pull Request** trên GitHub.  

---

## 📧 Liên hệ

- 📌 **GitHub**: [FriskChara02](https://github.com/FriskChara02)  
- 📌 **Email**: loi.nguyenbao02@gmail.com  

---

## 🚀 Hỗ trợ dự án

Nếu bạn thích **SmartTask-App**, hãy ⭐ repository này để ủng hộ mình tiếp tục phát triển nhé! 🎉


---
