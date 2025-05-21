#  update_event.php

<?php
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

$data = json_decode(file_get_contents("php://input"), true);

$id = $data['id'] ?? null;
$title = $data['title'] ?? null;
$description = $data['description'] ?? null;
$start_date = $data['startDate'] ?? null;
$end_date = $data['endDate'] ?? null;
$priority = $data['priority'] ?? null;
$is_all_day = isset($data['isAllDay']) ? (int)$data['isAllDay'] : null;
$google_event_id = $data['googleEventId'] ?? null;

if (!$id || !$title || !$start_date) {
    echo json_encode(["error" => "Missing required fields"]);
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

// Chuyển đổi định dạng ngày giờ
$start_date = (new DateTime($start_date))->format('Y-m-d H:i:s');
$end_date = $end_date ? (new DateTime($end_date))->format('Y-m-d H:i:s') : null;

$stmt = $conn->prepare("UPDATE events SET title = ?, description = ?, start_date = ?, end_date = ?, priority = ?, is_all_day = ?, google_event_id = ? WHERE id = ?");
$stmt->bind_param("sssssiis", $title, $description, $start_date, $end_date, $priority, $is_all_day, $google_event_id, $id);
$stmt->execute();
echo json_encode(["message" => "Event updated"]);
$stmt->close();
$conn->close();
?>
