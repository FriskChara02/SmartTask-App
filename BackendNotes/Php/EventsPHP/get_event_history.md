#  get_event_history.php

<?php
header("Content-Type: application/json");
include "db_connect.php";

$user_id = $_GET['user_id'] ?? null;

if (!$user_id) {
    echo json_encode(["error" => "Missing user_id"]);
    exit;
}

$stmt = $conn->prepare("SELECT event_id AS id, user_id AS userId, title, description, start_date AS startDate, end_date AS endDate, priority, is_all_day AS isAllDay, completed_at AS createdAt, completed_at AS updatedAt 
                       FROM event_history 
                       WHERE user_id = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();
$result = $stmt->get_result();
$events = $result->fetch_all(MYSQLI_ASSOC);

if (empty($events)) {
    echo json_encode([]);
} else {
    $transformedEvents = array_map(function($event) {
        return [
            "id" => $event["id"],
            "userId" => $event["userId"],
            "title" => $event["title"],
            "description" => $event["description"],
            "startDate" => $event["startDate"],
            "endDate" => $event["endDate"],
            "priority" => $event["priority"],
            "isAllDay" => $event["isAllDay"],
            "createdAt" => $event["createdAt"],
            "updatedAt" => $event["updatedAt"]
        ];
    }, $events);
    echo json_encode($transformedEvents);
}

$stmt->close();
$conn->close();
?>
