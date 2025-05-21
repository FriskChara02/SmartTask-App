#  get_user_health.php

<?php
header("Content-Type: application/json");
include "db_connect.php";

$user_id = $_GET['user_id'] ?? null;

if (!$user_id) {
    echo json_encode(["error" => "Missing user_id"]);
    exit;
}

$stmt = $conn->prepare("SELECT weight, height FROM users WHERE id = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    echo json_encode($row);
} else {
    echo json_encode(["weight" => null, "height" => null]);
}

$stmt->close();
$conn->close();
?>
