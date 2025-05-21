#  save_feedback.php

<?php
include "db_connect.php";
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

$data = json_decode(file_get_contents("php://input"), true);

if ($data === null) {
    http_response_code(400);
    echo json_encode(["error" => "Invalid JSON input"]);
    exit;
}

$user_id = $data['user_id'] ?? null;
$feedback = $data['feedback'] ?? null;

if (!$user_id || !$feedback) {
    http_response_code(400);
    echo json_encode(["error" => "user_id and feedback are required"]);
    exit;
}

if (!$conn) {
    http_response_code(500);
    echo json_encode(["error" => "Database connection failed"]);
    exit;
}

// Kiểm tra user_id tồn tại
$sql = "SELECT id FROM users WHERE id = ?";
$stmt = $conn->prepare($sql);
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["error" => "Failed to prepare statement: " . $conn->error]);
    exit;
}
$stmt->bind_param("i", $user_id);
if (!$stmt->execute()) {
    http_response_code(500);
    echo json_encode(["error" => "Query execution failed: " . $stmt->error]);
    exit;
}
$result = $stmt->get_result();
if ($result->num_rows === 0) {
    http_response_code(404);
    echo json_encode(["error" => "User not found"]);
    $stmt->close();
    $conn->close();
    exit;
}
$stmt->close();

// Lưu feedback
$sql = "INSERT INTO feedbacks (user_id, feedback, created_at) VALUES (?, ?, NOW())";
$stmt = $conn->prepare($sql);
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["error" => "Failed to prepare statement: " . $conn->error]);
    exit;
}
$stmt->bind_param("is", $user_id, $feedback);
if ($stmt->execute()) {
    http_response_code(200);
    echo json_encode(["message" => "Feedback saved successfully"]);
} else {
    http_response_code(500);
    echo json_encode(["error" => "Failed to save feedback: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
