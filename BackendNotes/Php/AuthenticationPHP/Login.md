#  login.php

<?php
include "db_connect.php";
include "config.php";

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

// ^^ Hàm tạo JWT
function generateJWT($userId) {
    $secret = JWT_SECRET;
    $payload = [
        "iss" => "SmartTask_API",
        "iat" => time(),
        "exp" => time() + 3600 * 24, // ^^ Hết hạn sau 24 giờ
        "sub" => $userId
    ];
    $header = base64_encode(json_encode(["alg" => "HS256", "typ" => "JWT"]));
    $payload = base64_encode(json_encode($payload));
    $signature = hash_hmac("sha256", "$header.$payload", $secret, true);
    $signature = base64_encode($signature);
    return "$header.$payload.$signature";
}

$data = json_decode(file_get_contents("php://input"), true);

if ($data === null) {
    http_response_code(400);
    echo json_encode(["error" => "Invalid JSON input"]);
    exit;
}

$email = $data['email'] ?? null;
$password = $data['password'] ?? null;

if (!$email || !$password) {
    http_response_code(400);
    echo json_encode(["error" => "Email and password are required"]);
    exit;
}

if (!$conn) {
    http_response_code(500);
    echo json_encode(["error" => "Database connection failed"]);
    exit;
}

$sql = "SELECT id, name, email, password, description, date_of_birth, location, joined_date, gender, hobbies, bio, avatar_url, role FROM users WHERE email = ?";
$stmt = $conn->prepare($sql);

if ($stmt === false) {
    http_response_code(500);
    echo json_encode(["error" => "Failed to prepare statement: " . $conn->error]);
    exit;
}

$stmt->bind_param("s", $email);
if (!$stmt->execute()) {
    http_response_code(500);
    echo json_encode(["error" => "Query execution failed: " . $stmt->error]);
    exit;
}

$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    if (password_verify($password, $row['password'])) {
        $token = generateJWT($row['id']); // ^^ Tạo JWT
        http_response_code(200);
        echo json_encode([
            "userId" => $row['id'],
            "name" => $row['name'],
            "email" => $row['email'],
            "description" => $row['description'],
            "date_of_birth" => $row['date_of_birth'],
            "location" => $row['location'],
            "joined_date" => $row['joined_date'],
            "gender" => $row['gender'],
            "hobbies" => $row['hobbies'],
            "bio" => $row['bio'],
            "avatar_url" => $row['avatar_url'],
            "role" => $row['role'], // 🟢 Thêm role vào response
            "token" => $token // ^^ Trả về token
        ]);
    } else {
        http_response_code(401);
        echo json_encode(["error" => "Invalid password"]);
    }
} else {
    http_response_code(404);
    echo json_encode(["error" => "User not found"]);
}

$stmt->close();
$conn->close();
?>
