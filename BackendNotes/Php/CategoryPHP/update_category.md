#  update_category.php

<?php
include "db_connect.php";

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: PUT");

$data = json_decode(file_get_contents("php://input"), true);

if (isset($data["id"]) && isset($data["name"])) {
    $id = (int)$data["id"];
    $name = $conn->real_escape_string($data["name"]);
    $isHidden = isset($data["isHidden"]) ? (int)$data["isHidden"] : 0;
    $color = isset($data["color"]) ? $conn->real_escape_string($data["color"]) : null;
    $icon = isset($data["icon"]) ? $conn->real_escape_string($data["icon"]) : null;

    $sql = "UPDATE categories SET name='$name', isHidden='$isHidden', color='$color', icon='$icon' WHERE id=$id";
    if ($conn->query($sql) === TRUE) {
        echo json_encode(["id" => $id, "name" => $name, "isHidden" => (bool)$isHidden, "color" => $color, "icon" => $icon]);
    } else {
        echo json_encode(["error" => "Error updating category: " . $conn->error]);
    }
} else {
    echo json_encode(["error" => "ID and name are required"]);
}

$conn->close();
?>
