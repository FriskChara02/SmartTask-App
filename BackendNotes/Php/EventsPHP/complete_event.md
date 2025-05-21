#  complete_event.php

<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header("Content-Type: application/json");
include "db_connect.php";

$data = json_decode(file_get_contents("php://input"), true);

if (!$data || !isset($data['event_id']) || !isset($data['completed_at']) || !isset($data['duration'])) {
    echo json_encode(["error" => "Missing required fields"]);
    exit;
}

$event_id = $data['event_id'];
$completed_at = (new DateTime($data['completed_at']))->format('Y-m-d H:i:s');
$duration = $data['duration'];

// Lấy thông tin sự kiện trước khi insert
$stmt = $conn->prepare("SELECT user_id, title, description, start_date, end_date, priority, is_all_day FROM events WHERE id = ?");
$stmt->bind_param("i", $event_id);
$stmt->execute();
$result = $stmt->get_result();
$event = $result->fetch_assoc();
$stmt->close();

if (!$event) {
    echo json_encode(["error" => "Event not found"]);
    exit;
}

$stmt = $conn->prepare("INSERT INTO event_history (event_id, user_id, title, description, start_date, end_date, priority, is_all_day, completed_at, duration) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
if (!$stmt) {
    echo json_encode(["error" => "Prepare failed: " . $conn->error]);
    exit;
}
$stmt->bind_param("iisssssisi", $event_id, $event['user_id'], $event['title'], $event['description'], $event['start_date'], $event['end_date'], $event['priority'], $event['is_all_day'], $completed_at, $duration);
$success = $stmt->execute();

if ($success) {
    $inserted_id = $conn->insert_id;
    $check = $conn->query("SELECT * FROM event_history WHERE id = $inserted_id");
    $row = $check->fetch_assoc();
    echo json_encode([
        "message" => "Event completed",
        "event_id" => $event_id,
        "inserted_history_id" => $inserted_id,
        "affected_rows" => $stmt->affected_rows,
        "debug_row" => $row
    ]);
} else {
    echo json_encode([
        "error" => "Insert failed",
        "sql_error" => $stmt->error,
        "event_id" => $event_id,
        "completed_at" => $completed_at,
        "duration" => $duration
    ]);
}

$stmt->close();
$conn->close();
?>
