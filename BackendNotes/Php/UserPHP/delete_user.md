#  delete_user.php

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

if (!$user_id) {
    echo json_encode(["success" => false, "message" => "Thiếu user_id"]);
    exit;
}

// Xóa người dùng
$sql = "DELETE FROM users WHERE id = ?";
$stmt = $conn->prepare($sql);

if ($stmt === false) {
    echo json_encode(["success" => false, "message" => "Lỗi prepare SQL: " . $conn->error]);
    exit;
}

$stmt->bind_param("i", $user_id);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Xóa tài khoản thành công"]);
} else {
    echo json_encode(["success" => false, "message" => "Xóa tài khoản thất bại: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
