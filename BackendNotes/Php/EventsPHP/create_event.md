#  create_event.php

<?php
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

header("Content-Type: application/json");
include "db_connect.php";
include "config.php";

// Đặt múi giờ server
date_default_timezone_set('Asia/Ho_Chi_Minh'); // +07:00

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

// Hàm trả về lỗi với mã HTTP
function sendError($message, $httpCode = 400) {
    http_response_code($httpCode);
    echo json_encode(["error" => $message]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);
if (!$data) {
    sendError("Invalid JSON");
}

$user_id = $data['userId'] ?? null;
$title = $data['title'] ?? null;
$description = $data['description'] ?? '';
$start_date = $data['startDate'] ?? null;
$end_date = $data['endDate'] ?? null;
$priority = $data['priority'] ?? 'Medium';
$is_all_day = isset($data['isAllDay']) ? (int)$data['isAllDay'] : 0;
$google_event_id = $data['googleEventId'] ?? null;

// Kiểm tra xác thực
$headers = apache_request_headers();
$token = isset($headers['Authorization']) ? str_replace("Bearer ", "", $headers['Authorization']) : '';
if (!$token || !verifyJWT($token)) {
    sendError("Invalid or missing authorization token", 401);
}

if (!$user_id || !$title || !$start_date) {
    sendError("Missing required fields");
}

if (!$conn) {
    sendError("Database connection failed", 500);
}

try {
    $start_date = (new DateTime($start_date))->format('Y-m-d H:i:s');
    $end_date = $end_date ? (new DateTime($end_date))->format('Y-m-d H:i:s') : null;
} catch (Exception $e) {
    sendError("Invalid date format: " . $e->getMessage());
}

$stmt = $conn->prepare("INSERT INTO events (user_id, title, description, start_date, end_date, priority, is_all_day, google_event_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
if (!$stmt) {
    sendError("Prepare failed: " . $conn->error, 500);
}
$stmt->bind_param("isssssis", $user_id, $title, $description, $start_date, $end_date, $priority, $is_all_day, $google_event_id);

if ($stmt->execute()) {
    echo json_encode(["message" => "Event created", "id" => $conn->insert_id]);
} else {
    sendError("Insert failed: " . $stmt->error, 500);
}

$stmt->close();
$conn->close();
?>
