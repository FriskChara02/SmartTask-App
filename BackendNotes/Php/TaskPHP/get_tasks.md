#  get_tasks.php

<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");

include "db_connect.php"; // Kết nối database

// Lấy `user_id` từ query string
$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

if ($user_id <= 0) {
    http_response_code(400);
    echo json_encode(["error" => "Invalid user ID"]);
    exit;
}

// Truy vấn danh sách công việc của user
$sql = "SELECT id, user_id, title, description, category_id, due_date, is_completed, created_at, priority 
        FROM tasks WHERE user_id = ?";
$stmt = $conn->prepare($sql);

if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["error" => "Failed to prepare statement: " . $conn->error]);
    $conn->close();
    exit;
}

$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

$tasks = [];
while ($row = $result->fetch_assoc()) {
    $tasks[] = [
        "id" => (int)$row["id"],
        "user_id" => (int)$row["user_id"], // Thêm user_id để khớp với TaskModel
        "title" => $row["title"],
        "description" => $row["description"] ?: "",
        "category_id" => (int)$row["category_id"],
        "due_date" => $row["due_date"] ? date(DATE_ATOM, strtotime($row["due_date"])) : null, // Chuẩn hóa key
        "isCompleted" => (bool)$row["is_completed"],
        "created_at" => $row["created_at"] ? date(DATE_ATOM, strtotime($row["created_at"])) : null, // Chuẩn hóa key
        "priority" => $row["priority"] ?: "Medium"
    ];
}

echo json_encode($tasks, JSON_PRETTY_PRINT);

$stmt->close();
$conn->close();
?>
