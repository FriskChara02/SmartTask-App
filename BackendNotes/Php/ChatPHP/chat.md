#  chat.php

**[Lưu ý]: Ở "$conn = new mysqli("localhost", "root", "", "SmartTask_DB");" --> "SmartTask_DB" ----> Đổi theo tên của bạn: "YourName_DB"
**[Lưu ý]: Đổi "DB: SmartTask_DB" --> YourName_DB

<?php
ob_start();
// chat.php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type");
// Thêm cấu hình error handling
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Kết nối database
$conn = new mysqli("localhost", "root", "", "SmartTask_DB");
error_log("DEBUG: Database connection - Host: localhost, User: root, DB: SmartTask_DB, Error: " . ($conn->connect_error ?: "None"));
$conn->set_charset("utf8mb4");

// Kiểm tra bảng tồn tại
$checkTables = $conn->query("SHOW TABLES LIKE 'world_chat'");
if ($checkTables->num_rows == 0) {
    error_log("ERROR: Table world_chat does not exist");
    echo json_encode(["success" => false, "message" => "Table world_chat not found"], JSON_NUMERIC_CHECK);
    exit;
}
$checkTables = $conn->query("SHOW TABLES LIKE 'smarttask_chat'");
if ($checkTables->num_rows == 0) {
    error_log("ERROR: Table smarttask_chat does not exist");
    echo json_encode(["success" => false, "message" => "Table smarttask_chat not found"], JSON_NUMERIC_CHECK);
    exit;
}
$checkTables = $conn->query("SHOW TABLES LIKE 'users'");
if ($checkTables->num_rows == 0) {
    error_log("ERROR: Table users does not exist");
    echo json_encode(["success" => false, "message" => "Table users not found"], JSON_NUMERIC_CHECK);
    exit;
}

if ($conn->connect_error) {
    echo json_encode(["success" => false, "message" => "Database connection failed"], JSON_NUMERIC_CHECK);
    exit;
}

date_default_timezone_set('Asia/Ho_Chi_Minh');

function formatBoldText($text) {
    // Tìm và xử lý các từ trong **...**, bọc trong thẻ <b> để in đậm
    return preg_replace_callback('/\*\*([^\*]+)\*\*/', function($matches) {
        $word = $matches[1];
        return "$word";
    }, $text);
}

// Hàm kiểm tra từ nhạy cảm
function checkSensitiveWords($content, $conn) {
    $sql = "SELECT word FROM sensitive_words";
    $result = $conn->query($sql);
    while ($row = $result->fetch_assoc()) {
        if (stripos($content, $row['word']) !== false) {
            return true;
        }
    }
    return false;
}

// Hàm tính độ tương đồng chuỗi bằng Levenshtein Distance
function calculateSimilarity($str1, $str2) {
    $lev = levenshtein(strtolower($str1), strtolower($str2));
    $maxLen = max(strlen($str1), strlen($str2));
    return $maxLen ? 1 - $lev / $maxLen : 0;
}

$method = $_SERVER["REQUEST_METHOD"];

if ($method === "GET") {
    // Lấy tin nhắn
    $type = $_GET["type"] ?? "";
    $user_id = $_GET["user_id"] ?? 0;

    // Kiểm tra user_id tồn tại
    $sql = "SELECT id FROM users WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    if ($stmt->get_result()->num_rows === 0) {
        echo json_encode(["success" => false, "message" => "User không tồn tại"], JSON_NUMERIC_CHECK);
        exit;
    }

    if ($type === "world") {
        $sql = "SELECT w.message_id, w.user_id, u.name, u.avatar_url, w.content, w.timestamp, CAST(w.is_edited AS UNSIGNED) AS is_edited, CAST(w.is_deleted AS UNSIGNED) AS is_deleted 
                FROM world_chat w LEFT JOIN users u ON w.user_id = u.id 
                ORDER BY w.timestamp DESC LIMIT 50";
        $result = $conn->query($sql);
        if (!$result) {
            error_log("ERROR: World query failed - SQL: $sql, Error: " . $conn->error);
            echo json_encode(["success" => false, "message" => "Query failed: " . $conn->error], JSON_NUMERIC_CHECK);
            exit;
        }
        if ($conn->error) {
            error_log("SQL Error in world: " . $conn->error);
            echo json_encode(["success" => false, "message" => "Lỗi SQL: " . $conn->error], JSON_NUMERIC_CHECK);
            exit;
        }
        $messages = $result->fetch_all(MYSQLI_ASSOC);
        echo json_encode(["success" => true, "message" => "Lấy tin nhắn thế giới thành công", "data" => $messages], JSON_NUMERIC_CHECK);
    } elseif ($type === "private") {
        $friend_id = $_GET["friend_id"] ?? 0;
        // Kiểm tra friend_id
        $sql = "SELECT id FROM users WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $friend_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            echo json_encode(["success" => false, "message" => "Friend không tồn tại"], JSON_NUMERIC_CHECK);
            exit;
        }
        $sql = "SELECT p.message_id, p.sender_id, u.name, u.avatar_url, p.content, p.timestamp, CAST(p.is_edited AS UNSIGNED) AS is_edited, CAST(p.is_deleted AS UNSIGNED) AS is_deleted 
                FROM private_chat p JOIN users u ON p.sender_id = u.id 
                WHERE ((p.sender_id = ? AND p.receiver_id = ?) OR (p.sender_id = ? AND p.receiver_id = ?)) 
                ORDER BY p.timestamp DESC LIMIT 50";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("iiii", $user_id, $friend_id, $friend_id, $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $messages = $result->fetch_all(MYSQLI_ASSOC);
        echo json_encode(["success" => true, "message" => "Lấy tin nhắn riêng tư thành công", "data" => $messages], JSON_NUMERIC_CHECK);
    } elseif ($type === "group") {
        $group_id = $_GET["group_id"] ?? 0;
        // Kiểm tra group_id
        $sql = "SELECT id FROM groups WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $group_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            echo json_encode(["success" => false, "message" => "Group không tồn tại"], JSON_NUMERIC_CHECK);
            exit;
        }
        $sql = "SELECT g.message_id, g.user_id, u.name, u.avatar_url, g.content, g.timestamp, CAST(g.is_edited AS UNSIGNED) AS is_edited, CAST(g.is_deleted AS UNSIGNED) AS is_deleted 
                FROM group_chat g JOIN users u ON g.user_id = u.id 
                WHERE g.group_id = ? 
                ORDER BY g.timestamp DESC LIMIT 50";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $group_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $messages = $result->fetch_all(MYSQLI_ASSOC);
        echo json_encode(["success" => true, "message" => "Lấy tin nhắn nhóm thành công", "data" => $messages], JSON_NUMERIC_CHECK);
    } elseif ($type === "limit") {
        $receiver_id = $_GET["receiver_id"] ?? 0;
        // Kiểm tra receiver_id
        $sql = "SELECT id FROM users WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $receiver_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            echo json_encode(["success" => false, "message" => "Receiver không tồn tại"], JSON_NUMERIC_CHECK);
            exit;
        }
        $sql = "SELECT message_count FROM chat_limits WHERE sender_id = ? AND receiver_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $user_id, $receiver_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $limit = $result->fetch_assoc();
        echo json_encode(["success" => true, "message" => "Lấy giới hạn tin nhắn thành công", "data" => $limit ?? ["message_count" => 0]], JSON_NUMERIC_CHECK);
    } elseif ($type === "smarttask") {
        $sql = "SELECT s.message_id, s.user_id, u.name, u.avatar_url, " . formatBoldText('s.content') . " AS content, s.timestamp, CAST(0 AS UNSIGNED) AS is_edited, CAST(s.is_deleted AS UNSIGNED) AS is_deleted, CAST(0 AS UNSIGNED) AS is_system_message 
                FROM smarttask_chat s LEFT JOIN users u ON s.user_id = u.id 
                WHERE s.is_deleted = 0 AND s.user_id = ? AND s.content IS NOT NULL
                UNION
                SELECT s.message_id, 0 AS user_id, 'SmartTask' AS name, NULL AS avatar_url, " . formatBoldText('s.response') . " AS content, s.timestamp, CAST(0 AS UNSIGNED) AS is_edited, CAST(s.is_deleted AS UNSIGNED) AS is_deleted, CAST(1 AS UNSIGNED) AS is_system_message 
                FROM smarttask_chat s 
                WHERE s.is_deleted = 0 AND s.user_id = ? AND s.response IS NOT NULL
                ORDER BY timestamp DESC LIMIT 50";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $user_id, $user_id);
        $stmt->execute();
        if ($stmt->error) {
            error_log("SQL Error in smarttask: " . $stmt->error);
            echo json_encode(["success" => false, "message" => "Lỗi SQL: " . $stmt->error], JSON_NUMERIC_CHECK);
            exit;
        }
        $result = $stmt->get_result();
        if (!$result) {
            error_log("ERROR: SmartTask query failed - SQL: $sql, Error: " . $stmt->error);
            echo json_encode(["success" => false, "message" => "Query failed: " . $stmt->error], JSON_NUMERIC_CHECK);
            exit;
        }
        $messages = $result->fetch_all(MYSQLI_ASSOC);
        echo json_encode(["success" => true, "message" => "Lấy tin nhắn SmartTaskChat thành công", "data" => $messages], JSON_NUMERIC_CHECK);
    } else {
        echo json_encode(["success" => false, "message" => "Loại chat không hợp lệ"], JSON_NUMERIC_CHECK);
    }
} elseif ($method === "POST") {
    // Gửi tin nhắn
    $contentType = $_SERVER["CONTENT_TYPE"] ?? "";
    if (strpos($contentType, "application/json") === false) {
        echo json_encode(["success" => false, "message" => "Content-Type phải là application/json"], JSON_NUMERIC_CHECK);
        exit;
    }

    $rawData = file_get_contents("php://input");
    $data = json_decode($rawData, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        echo json_encode(["success" => false, "message" => "Dữ liệu JSON không hợp lệ"], JSON_NUMERIC_CHECK);
        exit;
    }

    $type = $data["type"] ?? "";
    $user_id = $data["user_id"] ?? 0;
    $content = $data["content"] ?? "";

    if (!$user_id || !$content) {
        echo json_encode(["success" => false, "message" => "Thiếu user_id hoặc content"], JSON_NUMERIC_CHECK);
        exit;
    }

    // Kiểm tra user_id tồn tại
    $sql = "SELECT id FROM users WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    if ($stmt->get_result()->num_rows === 0) {
        echo json_encode(["success" => false, "message" => "User không tồn tại"], JSON_NUMERIC_CHECK);
        exit;
    }

    // Kiểm tra từ nhạy cảm
    if (checkSensitiveWords($content, $conn)) {
        echo json_encode(["success" => false, "message" => "Tin nhắn chứa từ nhạy cảm"], JSON_NUMERIC_CHECK);
        exit;
    }

    if ($type === "world") {
        $sql = "INSERT INTO world_chat (user_id, content) VALUES (?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("is", $user_id, $content);
        if ($stmt->execute()) {
            echo json_encode(["success" => true, "message" => "Gửi tin nhắn thế giới thành công"], JSON_NUMERIC_CHECK);
        } else {
            echo json_encode(["success" => false, "message" => "Gửi tin nhắn thế giới thất bại"], JSON_NUMERIC_CHECK);
        }
    } elseif ($type === "private") {
        $receiver_id = $data["receiver_id"] ?? 0;
        if (!$receiver_id) {
            echo json_encode(["success" => false, "message" => "Thiếu receiver_id"], JSON_NUMERIC_CHECK);
            exit;
        }
        // Kiểm tra receiver_id
        $sql = "SELECT id FROM users WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $receiver_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            echo json_encode(["success" => false, "message" => "Receiver không tồn tại"], JSON_NUMERIC_CHECK);
            exit;
        }

        // Kiểm tra giới hạn tin nhắn với người lạ
        $sql = "SELECT message_count FROM chat_limits WHERE sender_id = ? AND receiver_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $user_id, $receiver_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $limit = $result->fetch_assoc();
        $message_count = $limit["message_count"] ?? 0;

        // Kiểm tra xem có phải bạn bè không
        $sql = "SELECT status FROM friends WHERE user_id = ? AND friend_id = ? AND status = 'accepted'";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $user_id, $receiver_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $is_friend = $result->num_rows > 0;

        if (!$is_friend && $message_count >= 3) {
            echo json_encode(["success" => false, "message" => "Đạt giới hạn tin nhắn cho người không phải bạn bè"], JSON_NUMERIC_CHECK);
            exit;
        }

        $sql = "INSERT INTO private_chat (sender_id, receiver_id, content) VALUES (?, ?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("iis", $user_id, $receiver_id, $content);
        if ($stmt->execute()) {
            if (!$is_friend) {
                $sql = "INSERT INTO chat_limits (sender_id, receiver_id, message_count) 
                        VALUES (?, ?, 1) 
                        ON DUPLICATE KEY UPDATE message_count = message_count + 1";
                $stmt = $conn->prepare($sql);
                $stmt->bind_param("ii", $user_id, $receiver_id);
                $stmt->execute();
            }
            echo json_encode(["success" => true, "message" => "Gửi tin nhắn riêng tư thành công"], JSON_NUMERIC_CHECK);
        } else {
            echo json_encode(["success" => false, "message" => "Gửi tin nhắn riêng tư thất bại"], JSON_NUMERIC_CHECK);
        }
    } elseif ($type === "group") {
        $group_id = $data["group_id"] ?? 0;
        if (!$group_id) {
            echo json_encode(["success" => false, "message" => "Thiếu group_id"], JSON_NUMERIC_CHECK);
            exit;
        }
        // Kiểm tra group_id
        $sql = "SELECT id FROM groups WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $group_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            echo json_encode(["success" => false, "message" => "Group không tồn tại"], JSON_NUMERIC_CHECK);
            exit;
        }
        $sql = "INSERT INTO group_chat (group_id, user_id, content) VALUES (?, ?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("iis", $group_id, $user_id, $content);
        if ($stmt->execute()) {
            echo json_encode(["success" => true, "message" => "Gửi tin nhắn nhóm thành công"], JSON_NUMERIC_CHECK);
        } else {
            echo json_encode(["success" => false, "message" => "Gửi tin nhắn nhóm thất bại"], JSON_NUMERIC_CHECK);
        }
    } elseif ($type === "smarttask") {
        // Kiểm tra từ nhạy cảm
        if (checkSensitiveWords($content, $conn)) {
            echo json_encode(["success" => false, "message" => "Câu hỏi chứa từ nhạy cảm"], JSON_NUMERIC_CHECK);
            exit;
        }

        // Tìm câu trả lời từ smarttask_intents
        $sql = "SELECT intent, response, pattern FROM smarttask_intents";
        $result = $conn->query($sql);
        if (!$result) {
            error_log("ERROR: Failed to query smarttask_intents - SQL: $sql, Error: " . $conn->error);
            echo json_encode(["success" => false, "message" => "Lỗi truy vấn smarttask_intents"], JSON_NUMERIC_CHECK);
            exit;
        }
        $bestMatch = null;
        $bestIntent = null;
        $highestSimilarity = 0;
        $threshold = 0.7; // Ngưỡng tương đồng tối thiểu
        error_log("DEBUG: Similarity threshold set to $threshold");

        while ($row = $result->fetch_assoc()) {
            $similarity = calculateSimilarity($content, $row['pattern']);
            error_log("DEBUG: Comparing content '$content' with pattern '{$row['pattern']}' - Similarity: $similarity");
            if ($similarity > $highestSimilarity && $similarity >= $threshold) {
                $highestSimilarity = $similarity;
                $bestMatch = $row['response'];
                $bestIntent = $row['intent'];
            }
        }

        $response = $bestMatch ?? "Câu hỏi của bạn nằm ở ngoài SmartTask nên mình không biết trả lời câu hỏi của bạn.";
        if ($bestMatch === null) {
            error_log("WARNING: No matching intent found for content '$content' - Using default response");
        }
        $intent = $bestIntent ?? "unknown";

        // Xử lý content và response trước khi lưu
        $formatted_content = formatBoldText($content);
        $formatted_response = formatBoldText($response);

        // Lưu cả câu hỏi và câu trả lời
        $sql = "INSERT INTO smarttask_chat (user_id, content, response, intent) VALUES (?, ?, ?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("isss", $user_id, $formatted_content, $formatted_response, $intent);
        error_log("DEBUG: Saving SmartTask question and response - user_id: $user_id, content: $content, response: $response, intent: $intent");
        if ($stmt->execute()) {
            echo json_encode(["success" => true, "message" => "Gửi câu hỏi SmartTaskChat thành công", "data" => ["response" => $response]], JSON_NUMERIC_CHECK);
        } else {
            error_log("ERROR: Failed to save SmartTask question and response - SQL: $sql, Error: " . $stmt->error);
            echo json_encode(["success" => false, "message" => "Lưu câu hỏi SmartTaskChat thất bại: " . $stmt->error], JSON_NUMERIC_CHECK);
        }
    }
} elseif ($method === "PUT") {
    // Chỉnh sửa/thu hồi tin nhắn
    $contentType = $_SERVER["CONTENT_TYPE"] ?? "";
    if (strpos($contentType, "application/json") === false) {
        echo json_encode(["success" => false, "message" => "Content-Type phải là application/json"], JSON_NUMERIC_CHECK);
        exit;
    }

    $rawData = file_get_contents("php://input");
    $data = json_decode($rawData, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        echo json_encode(["success" => false, "message" => "Dữ liệu JSON không hợp lệ"], JSON_NUMERIC_CHECK);
        exit;
    }

    $message_id = $data["message_id"] ?? 0;
    $type = $data["type"] ?? "";
    $action = $data["action"] ?? "";
    $user_id = $data["user_id"] ?? 0;
    $content = $data["content"] ?? "";

    if (!$message_id || !$type || !$action || !$user_id) {
        error_log("Missing parameters: message_id=$message_id, type=$type, action=$action, user_id=$user_id");
        echo json_encode(["success" => false, "message" => "Thiếu tham số cần thiết"], JSON_NUMERIC_CHECK);
        exit;
    }

    // Kiểm tra user_id tồn tại
    $sql = "SELECT id, role FROM users WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result->num_rows === 0) {
        error_log("User không tồn tại: user_id=$user_id");
        echo json_encode(["success" => false, "message" => "User không tồn tại"], JSON_NUMERIC_CHECK);
        exit;
    }
    $user = $result->fetch_assoc();
    $is_authorized = in_array($user['role'], ['admin', 'super_admin']);

    // Kiểm tra quyền chỉnh sửa/xóa
    if (!$is_authorized) {
        if ($type === "world") {
            $sql = "SELECT user_id FROM world_chat WHERE message_id = ? AND is_deleted = 0";
        } elseif ($type === "private") {
            $sql = "SELECT sender_id AS user_id FROM private_chat WHERE message_id = ? AND is_deleted = 0";
        } elseif ($type === "group") {
            $sql = "SELECT user_id FROM group_chat WHERE message_id = ? AND is_deleted = 0";
        } else {
            error_log("Invalid type: $type");
            echo json_encode(["success" => false, "message" => "Loại chat không hợp lệ"], JSON_NUMERIC_CHECK);
            exit;
        }
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $message_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $message = $result->fetch_assoc();
        if (!$message) {
            error_log("Message not found or already deleted: message_id=$message_id, type=$type");
            echo json_encode(["success" => false, "message" => "Tin nhắn không tồn tại hoặc đã bị xóa"], JSON_NUMERIC_CHECK);
            exit;
        }
        $is_authorized = $message['user_id'] == $user_id;
    }

    if (!$is_authorized) {
        error_log("Unauthorized: user_id=$user_id, message_id=$message_id, type=$type");
        echo json_encode(["success" => false, "message" => "Không có quyền chỉnh sửa/xóa tin nhắn"], JSON_NUMERIC_CHECK);
        exit;
    }

    if ($action === "edit") {
        if (empty($content)) {
            error_log("Empty content for edit: message_id=$message_id, type=$type");
            echo json_encode(["success" => false, "message" => "Nội dung chỉnh sửa không được để trống"], JSON_NUMERIC_CHECK);
            exit;
        }
        // Kiểm tra từ nhạy cảm
        if (checkSensitiveWords($content, $conn)) {
            error_log("Sensitive word detected in edit: message_id=$message_id, type=$type");
            echo json_encode(["success" => false, "message" => "Tin nhắn chứa từ nhạy cảm"], JSON_NUMERIC_CHECK);
            exit;
        }
        if ($type === "world") {
            $sql = "UPDATE world_chat SET content = ?, is_edited = 1 WHERE message_id = ? AND is_deleted = 0";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("si", $content, $message_id);
        } elseif ($type === "private") {
            $sql = "UPDATE private_chat SET content = ?, is_edited = 1 WHERE message_id = ? AND is_deleted = 0";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("si", $content, $message_id);
        } elseif ($type === "group") {
            $sql = "UPDATE group_chat SET content = ?, is_edited = 1 WHERE message_id = ? AND is_deleted = 0";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("si", $content, $message_id);
        } else {
            error_log("Invalid type for edit: $type");
            echo json_encode(["success" => false, "message" => "Loại chat không hợp lệ"], JSON_NUMERIC_CHECK);
            exit;
        }
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode(["success" => true, "message" => "Chỉnh sửa tin nhắn thành công"], JSON_NUMERIC_CHECK);
            } else {
                error_log("No rows affected for edit: message_id=$message_id, type=$type");
                echo json_encode(["success" => false, "message" => "Không thể chỉnh sửa tin nhắn, có thể tin nhắn đã bị xóa"], JSON_NUMERIC_CHECK);
            }
        } else {
            error_log("SQL error for edit: message_id=$message_id, type=$type, error=" . $stmt->error);
            echo json_encode(["success" => false, "message" => "Chỉnh sửa tin nhắn thất bại: " . $stmt->error], JSON_NUMERIC_CHECK);
        }
    } elseif ($action === "delete") {
        if ($type === "world") {
            $sql = "UPDATE world_chat SET is_deleted = 1 WHERE message_id = ? AND is_deleted = 0";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $message_id);
        } elseif ($type === "private") {
            $sql = "UPDATE private_chat SET is_deleted = 1 WHERE message_id = ? AND is_deleted = 0";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $message_id);
        } elseif ($type === "group") {
            $sql = "UPDATE group_chat SET is_deleted = 1 WHERE message_id = ? AND is_deleted = 0";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $message_id);
        } else {
            error_log("Invalid type for delete: $type");
            echo json_encode(["success" => false, "message" => "Loại chat không hợp lệ"], JSON_NUMERIC_CHECK);
            exit;
        }
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode(["success" => true, "message" => "Xóa tin nhắn thành công"], JSON_NUMERIC_CHECK);
            } else {
                error_log("No rows affected for delete: message_id=$message_id, type=$type");
                echo json_encode(["success" => false, "message" => "Không thể xóa tin nhắn, có thể tin nhắn đã bị xóa"], JSON_NUMERIC_CHECK);
            }
        } else {
            error_log("SQL error for delete: message_id=$message_id, type=$type, error=" . $stmt->error);
            echo json_encode(["success" => false, "message" => "Xóa tin nhắn thất bại: " . $stmt->error], JSON_NUMERIC_CHECK);
        }
    } else {
        error_log("Invalid action: $action");
        echo json_encode(["success" => false, "message" => "Hành động không hợp lệ"], JSON_NUMERIC_CHECK);
    }
}

// Log phản hồi
error_log("DEBUG: chat.php response - Method: $method, Type: " . ($_GET["type"] ?? ($data["type"] ?? "none")) . ", UserID: " . ($user_id ?? "none") . ", Response: " . json_encode(["success" => true, "message" => "Processed"], JSON_NUMERIC_CHECK));
ob_end_flush();
$conn->close();
?>
