#  create_category.php

<?php
include "db_connect.php";

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");

$data = json_decode(file_get_contents("php://input"), true);

if (isset($data["name"])) {
    $name = $conn->real_escape_string($data["name"]);
    $isHidden = isset($data["isHidden"]) ? (int)$data["isHidden"] : 0;
    $color = isset($data["color"]) ? $conn->real_escape_string($data["color"]) : null;
    $icon = isset($data["icon"]) ? $conn->real_escape_string($data["icon"]) : null;

    $sql = "INSERT INTO categories (name, isHidden, color, icon) VALUES ('$name', '$isHidden', '$color', '$icon')";
    if ($conn->query($sql) === TRUE) {
        $newId = $conn->insert_id;
        echo json_encode(["id" => $newId, "name" => $name, "isHidden" => (bool)$isHidden, "color" => $color, "icon" => $icon]);
    } else {
        echo json_encode(["error" => "Error creating category: " . $conn->error]);
    }
} else {
    echo json_encode(["error" => "Name is required"]);
}

$conn->close();
?>
