#  get_categories.php

<?php
include "db_connect.php";

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");

$sql = "SELECT id, name, isHidden, color, icon FROM categories";
$result = $conn->query($sql);

$categories = [];
while ($row = $result->fetch_assoc()) {
    $categories[] = [
        "id" => (int)$row["id"],
        "name" => $row["name"],
        "isHidden" => (bool)$row["isHidden"],
        "color" => $row["color"],
        "icon" => $row["icon"]
    ];
}

echo json_encode($categories);
$conn->close();
?>
