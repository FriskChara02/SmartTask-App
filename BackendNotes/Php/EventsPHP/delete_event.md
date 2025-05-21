#  delete_event.php

<?php
header("Content-Type: application/json");
include "db_connect.php";
include "config.php";

// ^^ Hàm xác minh JWT
function verifyJWT($token) {
    $secret = JWT_SECRET;
    $parts = explode('.', $token);
    if (count($parts) !== 3) {
        return false;
    }
    list($header, $payload, $signature) = $parts;
    $expectedSignature = base64_encode(hash_hmac("sha256", "$header.$payload", $secret, true));
    if ($signature !== $expectedSignature) {
        return false;
    }
    $payloadData = json_decode(base64_decode($payload), true);
    if (!$payloadData || !isset($payloadData['exp']) || $payloadData['exp'] < time()) {
        return false;
    }
    return true;
}

$data = json_decode(file_get_contents("php://input"), true);
$id = $data['id'] ?? null;

if (!$id) {
    echo json_encode(["error" => "Missing event id"]);
    exit;
}

// ^^ Kiểm tra xác thực
$headers = apache_request_headers();
$token = isset($headers['Authorization']) ? str_replace("Bearer ", "", $headers['Authorization']) : '';
if (!$token || !verifyJWT($token)) {
    http_response_code(401);
    echo json_encode(["error" => "Invalid or missing authorization token"]);
    exit;
}

$stmt = $conn->prepare("DELETE FROM events WHERE id = ?");
$stmt->bind_param("i", $id);
$stmt->execute();
echo json_encode(["message" => "Event deleted"]);
$stmt->close();
$conn->close();
?>
