#  register.php

**[Lưu ý]: Ở "$dbname = "SmartTask_DB";" --> "SmartTask_DB" ----> Đổi theo tên của bạn: "YourName_DB"

<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

$servername = "localhost";
$username = "root";
$password = "";
$dbname = "SmartTask_DB";

$conn = new mysqli($servername, $username, $password, $dbname);
if ($conn->connect_error) {
    die(json_encode(["success" => false, "message" => "Kết nối thất bại"]));
}

$data = json_decode(file_get_contents("php://input"));
if (!isset($data->name) || !isset($data->email) || !isset($data->password)) {
    echo json_encode(["success" => false, "message" => "Vui lòng nhập đủ thông tin"]);
    exit;
}

$name = $data->name;
$email = $data->email;
$password = password_hash($data->password, PASSWORD_BCRYPT);
$role = "user"; // 🟢 Gán role mặc định là "user"

$sql = "INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)";
$stmt = $conn->prepare($sql);
$stmt->bind_param("ssss", $name, $email, $password, $role);

if ($stmt->execute()) {
    echo json_encode(["success" => true, "message" => "Đăng ký thành công"]);
} else {
    echo json_encode(["success" => false, "message" => "Email đã tồn tại"]);
}

$conn->close();
?>
