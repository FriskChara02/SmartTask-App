#  user_health.php

<?php
header("Content-Type: application/json");
include "db_connect.php";

$data = json_decode(file_get_contents("php://input"), true);

$user_id = $data['user_id'] ?? null;
$weight = $data['weight'] ?? null;
$height = $data['height'] ?? null;

if (!$user_id || !$weight || !$height) {
    echo json_encode(["error" => "Missing required fields"]);
    exit;
}

// Kiểm tra user_id tồn tại
$checkStmt = $conn->prepare("SELECT id FROM users WHERE id = ?");
$checkStmt->bind_param("i", $user_id);
$checkStmt->execute();
$result = $checkStmt->get_result();
if ($result->num_rows == 0) {
    echo json_encode(["error" => "User ID does not exist"]);
    $checkStmt->close();
    $conn->close();
    exit;
}
$checkStmt->close();

// Cập nhật dữ liệu
$stmt = $conn->prepare("UPDATE users SET weight = ?, height = ? WHERE id = ?");
$stmt->bind_param("ddi", $weight, $height, $user_id);
$success = $stmt->execute();

if ($success) {
    // Trả về thành công ngay cả khi không có thay đổi
    echo json_encode([
        "message" => "Measurements updated successfully",
        "affected_rows" => $stmt->affected_rows
    ]);
} else {
    echo json_encode(["error" => "Failed to update measurements", "sql_error" => $stmt->error]);
}

$stmt->close();
$conn->close();
?>
