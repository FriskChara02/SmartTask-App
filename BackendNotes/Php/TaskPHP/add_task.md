#  add_task.php

<?php
include "db_connect.php";

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

$data = json_decode(file_get_contents("php://input"), true);
error_log("Received data: " . print_r($data, true));

if ($data === null) {
    http_response_code(400);
    echo json_encode(["error" => "Failed to decode JSON", "raw_input" => file_get_contents("php://input")]);
    $conn->close();
    exit;
}

if ($data) {
    // Sửa key để khớp với JSON từ Swift
    $user_id = $data['user_id'] ?? null; // Đổi từ 'userId' thành 'user_id'
    $title = $data['title'] ?? null;
    $description = $data['description'] ?? "";
    $category_id = $data['category_id'] ?? null; // Đổi từ 'categoryId' thành 'category_id'
    $due_date = isset($data['due_date']) ? date("Y-m-d H:i:s", strtotime($data['due_date'])) : null; // Đổi 'dueDate' thành 'due_date'
    $is_completed = isset($data['isCompleted']) ? ($data['isCompleted'] ? 1 : 0) : 0;
    $priority = $data['priority'] ?? "Medium";

    if (!$user_id || !$title || !$category_id) {
        http_response_code(400);
        echo json_encode(["error" => "User ID, title, and category ID are required"]);
        exit;
    }

    $sql = "INSERT INTO tasks (user_id, title, description, category_id, due_date, is_completed, priority) 
            VALUES (?, ?, ?, ?, ?, ?, ?)";
    $stmt = $conn->prepare($sql);

    if ($stmt === false) {
        http_response_code(500);
        echo json_encode(["error" => "Failed to prepare statement: " . $conn->error]);
        $conn->close();
        exit;
    }

    $stmt->bind_param("issisis", $user_id, $title, $description, $category_id, $due_date, $is_completed, $priority);

    if ($stmt->execute()) {
        http_response_code(201);
        echo json_encode(["message" => "Task added successfully", "id" => $conn->insert_id]);
    } else {
        http_response_code(500);
        echo json_encode(["error" => "Failed to add task: " . $stmt->error, "mysql_error" => $conn->error]);
    }

    $stmt->close();
} else {
    http_response_code(400);
    echo json_encode(["error" => "Invalid JSON input"]);
}

$conn->close();
?>
