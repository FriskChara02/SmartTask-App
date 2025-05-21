#  toggle_task.php

<?php
include "db_connect.php";

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT");

$id = $_GET['id'] ?? null;

if ($id) {
    $sql = "UPDATE tasks SET is_completed = !is_completed WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        http_response_code(200);
        echo json_encode(["message" => "Task completion toggled successfully"]);
    } else {
        http_response_code(500);
        echo json_encode(["error" => "Failed to toggle task: " . $stmt->error]);
    }
    $stmt->close();
} else {
    http_response_code(400);
    echo json_encode(["error" => "Missing task ID"]);
}

$conn->close();
?>
