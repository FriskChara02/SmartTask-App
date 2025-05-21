#  get_ratings.php

<?php
include "db_connect.php";
header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");

if (!$conn) {
    http_response_code(500);
    echo json_encode(["error" => "Database connection failed"]);
    exit;
}

$sql = "SELECT r.id, r.user_id, u.name, r.rating, r.comment, r.created_at 
        FROM ratings r 
        JOIN users u ON r.user_id = u.id 
        ORDER BY r.created_at DESC";
$result = $conn->query($sql);

if ($result === false) {
    http_response_code(500);
    echo json_encode(["error" => "Query execution failed: " . $conn->error]);
    exit;
}

$ratings = [];
while ($row = $result->fetch_assoc()) {
    $ratings[] = [
        "id" => (int)$row["id"],          
        "user_id" => (int)$row["user_id"], 
        "name" => $row["name"],
        "rating" => (int)$row["rating"],   
        "comment" => $row["comment"],
        "created_at" => $row["created_at"]
    ];
}

http_response_code(200);
echo json_encode(["ratings" => $ratings]);

$result->free();
$conn->close();
?>
