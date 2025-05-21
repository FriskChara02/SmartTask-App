#  get_events.php

<?php
header("Content-Type: application/json");
include "db_connect.php";

$user_id = $_GET['user_id'] ?? null;

if (!$user_id) {
    echo json_encode(["error" => "Missing user_id"]);
    exit;
}

$stmt = $conn->prepare("SELECT * FROM events WHERE user_id = ? AND id NOT IN (SELECT event_id FROM event_history WHERE event_id IS NOT NULL)");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();
$events = $result->fetch_all(MYSQLI_ASSOC);

$transformedEvents = array_map(function($event) {
    return [
        "id" => $event["id"],
        "userId" => $event["user_id"],
        "title" => $event["title"],
        "description" => $event["description"],
        "startDate" => $event["start_date"],
        "endDate" => $event["end_date"],
        "priority" => $event["priority"],
        "isAllDay" => $event["is_all_day"],
        "createdAt" => $event["created_at"],
        "updatedAt" => $event["updated_at"],
        "googleEventId" => $event["google_event_id"]
    ];
}, $events);

echo json_encode($transformedEvents);
$stmt->close();
$conn->close();
?>
