#  save_rating.php

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
$rating = $data['rating'] ?? null;
$comment = $data['comment'] ?? null;

if (!$user_id || !$rating) {
    http_response_code(400);
    echo json_encode(["error" => "user_id and rating are required"]);
    exit;
}

if ($rating < 1 || $rating > 5) {
    http_response_code(400);
    echo json_encode(["error" => "Rating must be between 1 and 5"]);
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

// Lưu rating
$sql = "INSERT INTO ratings (user_id, rating, comment, created_at) VALUES (?, ?, ?, NOW())";
$stmt = $conn->prepare($sql);
if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["error" => "Failed to prepare statement: " . $conn->error]);
    exit;
}
$stmt->bind_param("iis", $user_id, $rating, $comment);
if ($stmt->execute()) {
    http_response_code(200);
    echo json_encode(["message" => "Rating saved successfully"]);
} else {
    http_response_code(500);
    echo json_encode(["error" => "Failed to save rating: " . $stmt->error]);
}

$stmt->close();
$conn->close();
?>
