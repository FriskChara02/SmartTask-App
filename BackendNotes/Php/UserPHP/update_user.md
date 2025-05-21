#  update_user.php

**[Lưu ý]: Ở "$conn = new mysqli("localhost", "root", "", "SmartTask_DB");" --> "SmartTask_DB" ----> Đổi theo tên của bạn: "YourName_DB"


<?php
header('Content-Type: application/json');
include "db_connect.php";

$conn = new mysqli("localhost", "root", "", "SmartTask_DB");

if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "Lỗi kết nối database: " . $conn->connect_error]);
    exit;
}

$user_id = $_POST['user_id'] ?? null;
$name = $_POST['name'] ?? null;
$email = $_POST['email'] ?? null;
$password = $_POST['password'] ?? null;
$description = $_POST['description'] ?? null;
$date_of_birth = $_POST['date_of_birth'] ?? null;
$location = $_POST['location'] ?? null;
$gender = $_POST['gender'] ?? null;
$hobbies = $_POST['hobbies'] ?? null;
$bio = $_POST['bio'] ?? null;
$status = $_POST['status'] ?? null;

if (!$user_id) {
    echo json_encode(["success" => false, "message" => "Thiếu user_id"]);
    exit;
}

// Kiểm tra user_id tồn tại
$sql = "SELECT id FROM users WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $user_id);
$stmt->execute();
if ($stmt->get_result()->num_rows === 0) {
    echo json_encode(["success" => false, "message" => "User không tồn tại"]);
    exit;
}

// Kiểm tra email hợp lệ
if ($email && !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(["success" => false, "message" => "Email không hợp lệ"]);
    exit;
}

// Kiểm tra status hợp lệ
$valid_statuses = ['online', 'offline', 'idle', 'dnd', 'invisible'];
if ($status && !in_array($status, $valid_statuses)) {
    echo json_encode(["success" => false, "message" => "Trạng thái không hợp lệ"]);
    exit;
}

// Hash mật khẩu nếu được cung cấp
if ($password) {
    $password = password_hash($password, PASSWORD_BCRYPT);
}

// Chuyển đổi date_of_birth sang định dạng YYYY-MM-DD
if ($date_of_birth) {
    $date = DateTime::createFromFormat('Y-m-d', $date_of_birth);
    if ($date) {
        $date_of_birth = $date->format('Y-m-d');
    } else {
        echo json_encode(["success" => false, "message" => "Định dạng date_of_birth không hợp lệ: $date_of_birth"]);
        exit;
    }
}

// Xây dựng câu lệnh SQL động
$fields = [];
$params = [];
$types = "";
if ($name) { $fields[] = "name = ?"; $params[] = $name; $types .= "s"; }
if ($email) { $fields[] = "email = ?"; $params[] = $email; $types .= "s"; }
if ($password) { $fields[] = "password = ?"; $params[] = $password; $types .= "s"; }
if ($description !== null) { $fields[] = "description = ?"; $params[] = $description; $types .= "s"; }
if ($date_of_birth !== null) { $fields[] = "date_of_birth = ?"; $params[] = $date_of_birth; $types .= "s"; }
if ($location !== null) { $fields[] = "location = ?"; $params[] = $location; $types .= "s"; }
if ($gender !== null) { $fields[] = "gender = ?"; $params[] = $gender; $types .= "s"; }
if ($hobbies !== null) { $fields[] = "hobbies = ?"; $params[] = $hobbies; $types .= "s"; }
if ($bio !== null) { $fields[] = "bio = ?"; $params[] = $bio; $types .= "s"; }
if ($status !== null) { $fields[] = "status = ?"; $params[] = $status; $types .= "s"; }

if (empty($fields)) {
    echo json_encode(["success" => false, "message" => "Không có thông tin để cập nhật"]);
    exit;
}

$sql = "UPDATE users SET " . implode(", ", $fields) . " WHERE id = ?";
$types .= "i";
$params[] = $user_id;

$stmt = $conn->prepare($sql);
if ($stmt === false) {
    echo json_encode(["success" => false, "message" => "Lỗi prepare SQL: " . $conn->error]);
    exit;
}

$stmt->bind_param($types, ...$params);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Cập nhật thành công"]);
} else {
    echo json_encode(["success" => false, "message" => "Cập nhật thất bại: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
