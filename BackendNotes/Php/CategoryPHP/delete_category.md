#  delete_category.php

<?php
include "db_connect.php";

header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: DELETE");

$data = json_decode(file_get_contents("php://input"), true);

if (isset($data["id"])) {
    $id = (int)$data["id"];
    $sql = "DELETE FROM categories WHERE id=$id";
    if ($conn->query($sql) === TRUE) {
        echo json_encode(["success" => "Category deleted", "id" => $id]);
    } else {
        echo json_encode(["error" => "Error deleting category: " . $conn->error]);
    }
} else {
    echo json_encode(["error" => "ID is required"]);
}

$conn->close();
?>
