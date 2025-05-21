#  Database SmartTask: 

**[Lưu ý]: Bạn chỉ cần copy code hết chỗ này vào SQL trên Database theo tên của bạn.

------------------------------------------------------------------------------------------------------
CREATE TABLE users (
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(255) NOT NULL,
email VARCHAR(255) NOT NULL UNIQUE,
password VARCHAR(255) NOT NULL,
avatar_url VARCHAR(255) DEFAULT NULL,
description TEXT, -- Mô tả
date_of_birth DATE, -- Ngày sinh
location VARCHAR(255), -- Địa điểm
joined_date DATETIME DEFAULT CURRENT_TIMESTAMP, -- Tham gia vào (mặc định ngày hiện tại)
gender VARCHAR(50), -- Giới tính
hobbies TEXT, -- Sở thích
bio TEXT, -- Giới thiệu
weight FLOAT DEFAULT NULL,  -- Cân nặng (kg)
height FLOAT DEFAULT NULL,  -- Chiều cao (cm)
role ENUM('user', 'admin', 'super_admin') DEFAULT 'user' NOT NULL,
status ENUM('online', 'offline', 'idle', 'dnd', 'invisible') DEFAULT 'offline' NOT NULL
);

CREATE TABLE tasks (
id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT NOT NULL,               -- Liên kết với [users.id](http://users.id/)
title VARCHAR(255) NOT NULL,
description TEXT,
category_id INT NOT NULL,           -- Liên kết với [categories.id](http://categories.id/)
due_date DATETIME,
is_completed TINYINT DEFAULT 0,     -- 0: chưa hoàn thành, 1: hoàn thành
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
priority VARCHAR(50) DEFAULT 'Medium',
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
);

CREATE TABLE categories (
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(255) NOT NULL,
is_hidden TINYINT DEFAULT 0,        -- 0: không ẩn, 1: ẩn
color VARCHAR(50) DEFAULT NULL,     -- Lưu tên màu (ví dụ: "blue", "red")
icon VARCHAR(50) DEFAULT NULL       -- Lưu tên icon (ví dụ: "pencil", "star")
);

CREATE TABLE notifications (
id VARCHAR(36) PRIMARY KEY,         -- UUID dạng chuỗi
message TEXT NOT NULL,              -- Nội dung thông báo
task_id INT DEFAULT NULL,           -- Liên kết với [tasks.id](http://tasks.id/) (nếu có)
is_read TINYINT DEFAULT 0,          -- 0: chưa đọc, 1: đã đọc
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE SET NULL
);

CREATE TABLE events (
id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT NOT NULL,               -- Liên kết với [[users.id](http://users.id/)]
title VARCHAR(255) NOT NULL,        -- Tiêu đề sự kiện
description TEXT,                   -- Mô tả sự kiện
start_date DATETIME NOT NULL,       -- Ngày giờ bắt đầu
end_date DATETIME,                  -- Ngày giờ kết thúc (có thể null nếu sự kiện không có kết thúc rõ ràng)
priority VARCHAR(50) DEFAULT 'Medium', -- Mức độ quan trọng (Low, Medium, High)
is_all_day TINYINT DEFAULT 0,       -- 0: không phải cả ngày, 1: sự kiện cả ngày
google_event_id VARCHAR(255) DEFAULT NULL, -- ID sự kiện tương ứng trên Google Calendar
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời gian tạo
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, -- Thời gian cập nhật
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE event_history (
id INT AUTO_INCREMENT PRIMARY KEY,
event_id INT NOT NULL,
user_id INT NOT NULL,
title VARCHAR(255) NOT NULL,
description TEXT,
start_date DATETIME NOT NULL,
end_date DATETIME,
priority VARCHAR(50) DEFAULT 'Medium',
is_all_day TINYINT DEFAULT 0,
completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
duration INT DEFAULT NULL,
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

------------------------------------------------------------------------------------------------------

CREATE TABLE feedbacks (
id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT NOT NULL,               -- Liên kết với [users.id](http://users.id/)
feedback TEXT NOT NULL,             -- Nội dung feedback
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời gian gửi
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE ratings (
id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT NOT NULL,               -- Liên kết với [users.id](http://users.id/)
rating INT NOT NULL,                -- Số sao (1-5)
comment TEXT,                       -- Bình luận của user (có thể null)
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời gian đánh giá
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

------------------------------------------------------------------------------------------------------

CREATE TABLE friends (
user_id INT NOT NULL,
friend_id INT NOT NULL,
status ENUM('pending', 'accepted') DEFAULT 'pending' NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (user_id, friend_id),
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
FOREIGN KEY (friend_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE friend_requests (
id INT AUTO_INCREMENT PRIMARY KEY,
sender_id INT NOT NULL,
receiver_id INT NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE banned_users (
user_id INT NOT NULL,
banned_by INT NOT NULL,
reason VARCHAR(255) DEFAULT 'Blocked by user',
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (user_id, banned_by),
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
FOREIGN KEY (banned_by) REFERENCES users(id) ON DELETE CASCADE
);

------------------------------------------------------------------------------------------------------

CREATE TABLE smarttask_chat (
message_id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT NOT NULL,               -- Liên kết với [users.id](http://users.id/)
content TEXT NOT NULL,             -- Câu hỏi từ người dùng
response TEXT,                      -- Câu trả lời tự động từ hệ thống
intent VARCHAR(100),                -- Ý định được nhận diện (ví dụ: "ask_app_info")
timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời gian gửi
is_deleted TINYINT DEFAULT 0,       -- 0: chưa xóa, 1: đã xóa
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE smarttask_intents (
id INT AUTO_INCREMENT PRIMARY KEY,
intent VARCHAR(100) NOT NULL,          -- Tên ý định (ví dụ: "ask_app_info")
pattern TEXT NOT NULL,                 -- Mẫu câu hỏi (ví dụ: "App của bạn là gì")
response TEXT NOT NULL,                -- Câu trả lời tương ứng
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Thời gian tạo
updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP -- Thời gian cập nhật
);

CREATE TABLE world_chat (
message_id INT AUTO_INCREMENT PRIMARY KEY,
user_id INT NOT NULL,
content TEXT NOT NULL,
timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
is_edited TINYINT DEFAULT 0,
is_deleted TINYINT DEFAULT 0,
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE private_chat (
message_id INT AUTO_INCREMENT PRIMARY KEY,
sender_id INT NOT NULL,
receiver_id INT NOT NULL,
content TEXT NOT NULL,
timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
is_edited TINYINT DEFAULT 0,
is_deleted TINYINT DEFAULT 0,
FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE chat_limits (
sender_id INT NOT NULL,
receiver_id INT NOT NULL,
message_count INT DEFAULT 0,
PRIMARY KEY (sender_id, receiver_id),
FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE sensitive_words (
id INT AUTO_INCREMENT PRIMARY KEY,
word VARCHAR(255) NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

------------------------------------------------------------------------------------------------------

CREATE TABLE groups (
id INT AUTO_INCREMENT PRIMARY KEY,
name VARCHAR(255) NOT NULL,
created_by INT NOT NULL,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
color VARCHAR(50) DEFAULT 'blue',
icon VARCHAR(100) DEFAULT 'person.3.fill',
FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE group_chat (
message_id INT AUTO_INCREMENT PRIMARY KEY,
group_id INT NOT NULL,
user_id INT NOT NULL,
content TEXT NOT NULL,
timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
is_edited TINYINT DEFAULT 0,
is_deleted TINYINT DEFAULT 0,
FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE group_members (
group_id INT NOT NULL,
user_id INT NOT NULL,
joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (group_id, user_id),
FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE,
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE group_projects (
id INT AUTO_INCREMENT PRIMARY KEY,
group_id INT NOT NULL,
name VARCHAR(255) NOT NULL,
progress FLOAT DEFAULT 0, -- Phần trăm hoàn thành (0-100)
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
FOREIGN KEY (group_id) REFERENCES groups(id) ON DELETE CASCADE
);

CREATE TABLE group_tasks (
id INT AUTO_INCREMENT PRIMARY KEY,
project_id INT NOT NULL,
title VARCHAR(255) NOT NULL,
description TEXT,
due_date DATETIME,
is_completed TINYINT DEFAULT 0,
created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
priority VARCHAR(50) DEFAULT 'Medium',
FOREIGN KEY (project_id) REFERENCES group_projects(id) ON DELETE CASCADE
);

- Tạo bảng task_assignments để lưu quan hệ nhiều-nhiều
CREATE TABLE task_assignments (
task_id INT NOT NULL,
user_id INT NOT NULL,
PRIMARY KEY (task_id, user_id),
FOREIGN KEY (task_id) REFERENCES group_tasks(id) ON DELETE CASCADE,
FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

------------------------------------------------------------------------------------------------------
