#  update_task.php

<?php
include "db_connect.php";

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT");
header("Access-Control-Allow-Headers: Content-Type");

$data = json_decode(file_get_contents("php://input"), true);
$id = $_GET['id'] ?? null;

if ($id && $data) {
    $title = $data['title'] ?? null;
    $description = $data['description'] ?? null;
    $category_id = $data['category_id'] ?? null; // Sửa từ 'categoryId'
    $due_date = isset($data['due_date']) ? date("Y-m-d H:i:s", strtotime($data['due_date'])) : null; // Sửa từ 'dueDate'
    $is_completed = isset($data['isCompleted']) ? ($data['isCompleted'] ? 1 : 0) : 0;
    $priority = $data['priority'] ?? "Medium";

    if (!$title || !$category_id) {
        http_response_code(400);
        echo json_encode(["error" => "Title and category ID are required"]);
        exit;
    }

    $sql = "UPDATE tasks SET title = ?, description = ?, category_id = ?, due_date = ?, is_completed = ?, priority = ? WHERE id = ?";
    $stmt = $conn->prepare($sql);
    
    if ($stmt === false) {
        http_response_code(500);
        echo json_encode(["error" => "Failed to prepare statement: " . $conn->error]);
        $conn->close();
        exit;
    }
    
    $stmt->bind_param("ssisisi", $title, $description, $category_id, $due_date, $is_completed, $priority, $id);

    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["message" => "Task updated successfully"]);
    } else {
        http_response_code(500);
        echo json_encode(["error" => "Failed to update task: " . $stmt->error]);
    }
    $stmt->close();
} else {
    http_response_code(400);
    echo json_encode(["error" => "Invalid input or missing ID"]);
}

$conn->close();
?>
