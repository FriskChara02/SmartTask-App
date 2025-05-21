#  friends.php

**[Lưu ý]: Ở "$conn = new mysqli("localhost", "root", "", "SmartTask_DB");" --> "SmartTask_DB" ----> Đổi theo tên của bạn: "YourName_DB"

<?php
// friends.php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type");

// Đặt múi giờ mặc định là Asia/Ho_Chi_Minh (UTC+7)
date_default_timezone_set('Asia/Ho_Chi_Minh');

$conn = new mysqli("localhost", "root", "", "SmartTask_DB");
if ($conn->connect_error) {
    $error_message = "Database connection failed: " . $conn->connect_error;
    echo json_encode(["success" => false, "message" => $error_message]);
    exit;
}

$method = $_SERVER["REQUEST_METHOD"];

// Hàm parse JSON từ request body
function parseJsonInput() {
    $input = file_get_contents('php://input');
    $parsed_data = json_decode($input, true) ?? [];
    if (empty($parsed_data)) {
        error_log("❌ Failed to parse JSON input");
        return [];
    }
    error_log("✅ Parsed JSON data: " . print_r($parsed_data, true));
    return $parsed_data;
}

if ($method === "GET") {
    $action = $_GET["action"] ?? "";
    $user_id = (int)($_GET["user_id"] ?? 0);

    if ($user_id <= 0) {
        echo json_encode(["success" => false, "message" => "Invalid user_id"]);
        exit;
    }

    $sql = "SELECT id FROM users WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        $error_message = "Prepare failed: " . $conn->error;
        echo json_encode(["success" => false, "message" => $error_message]);
        exit;
    }
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    if ($stmt->get_result()->num_rows === 0) {
        echo json_encode(["success" => false, "message" => "User not found"]);
        exit;
    }

    if ($action === "list") {
        $sql = "SELECT u.id, u.name, u.avatar_url, u.status, u.date_of_birth, f.created_at,
                       (SELECT COUNT(*) FROM friends f1 
                        WHERE f1.user_id IN (SELECT friend_id FROM friends WHERE user_id = ? AND status = 'accepted') 
                        AND f1.friend_id = u.id AND f1.status = 'accepted') AS mutual_friends
                FROM friends f 
                JOIN users u ON f.friend_id = u.id 
                WHERE f.user_id = ? AND f.status = 'accepted'";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $stmt->bind_param("ii", $user_id, $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $friends = $result->fetch_all(MYSQLI_ASSOC);
        error_log("✅ Parsed " . count($friends) . " friends");
        echo json_encode(["success" => true, "message" => "Lấy danh sách bạn bè thành công", "data" => $friends]);
    } elseif ($action === "requests") {
        $sql = "SELECT fr.id, u.id AS sender_id, u.name, u.avatar_url, fr.created_at 
                FROM friend_requests fr 
                JOIN users u ON fr.sender_id = u.id 
                WHERE fr.receiver_id = ?";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $requests = $result->fetch_all(MYSQLI_ASSOC);
        error_log("✅ Parsed " . count($requests) . " friend requests");
        echo json_encode(["success" => true, "message" => "Lấy danh sách yêu cầu kết bạn thành công", "data" => $requests]);
    } elseif ($action === "search") {
        $query = $_GET["query"] ?? "";
        $sql = "SELECT u.id, u.name, u.avatar_url, u.status, u.date_of_birth, 
                       (SELECT COUNT(*) FROM friends f1 
                        WHERE f1.user_id IN (SELECT friend_id FROM friends WHERE user_id = ? AND status = 'accepted') 
                        AND f1.friend_id = u.id AND f1.status = 'accepted') AS mutual_friends,
                       (SELECT created_at FROM friends WHERE user_id = ? AND friend_id = u.id AND status = 'accepted') AS created_at,
                       EXISTS (SELECT 1 FROM friends WHERE user_id = ? AND friend_id = u.id AND status = 'accepted') AS is_friend,
                       EXISTS (SELECT 1 FROM friend_requests WHERE sender_id = ? AND receiver_id = u.id) AS is_pending
                FROM users u 
                WHERE (u.name LIKE ? OR u.email LIKE ?) AND u.id != ? AND u.id NOT IN (SELECT user_id FROM banned_users WHERE banned_by = ?)";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $search_term = "%$query%";
        $stmt->bind_param("iisissii", $user_id, $user_id, $user_id, $user_id, $search_term, $search_term, $user_id, $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $users = $result->fetch_all(MYSQLI_ASSOC);
        error_log("✅ Parsed " . count($users) . " users");
        echo json_encode(["success" => true, "message" => "Tìm kiếm người dùng thành công", "data" => $users]);
    } elseif ($action === "suggestions") {
        $sql = "SHOW TABLES LIKE 'banned_users'";
        $result = $conn->query($sql);
        if ($result->num_rows === 0) {
            $error_message = "Table banned_users does not exist";
            echo json_encode(["success" => false, "message" => $error_message, "data" => []]);
            exit;
        }

        $required_tables = ['users', 'friends', 'friend_requests', 'banned_users'];
        $required_columns = [
            'users' => ['id', 'name', 'avatar_url', 'status', 'date_of_birth'],
            'friends' => ['user_id', 'friend_id', 'status'],
            'friend_requests' => ['sender_id', 'receiver_id'],
            'banned_users' => ['user_id', 'banned_by']
        ];
        foreach ($required_tables as $table) {
            $sql = "SHOW COLUMNS FROM $table";
            $result = $conn->query($sql);
            if (!$result) {
                $error_message = "Table $table does not exist or is inaccessible: " . $conn->error;
                echo json_encode(["success" => false, "message" => $error_message, "data" => []]);
                exit;
            }
            $columns = array_column($result->fetch_all(MYSQLI_ASSOC), 'Field');
            foreach ($required_columns[$table] as $column) {
                if (!in_array($column, $columns)) {
                    $error_message = "Column $column does not exist in table $table";
                    echo json_encode(["success" => false, "message" => $error_message, "data" => []]);
                    exit;
                }
            }
        }

        $sql = "SELECT u.id, u.name, u.avatar_url, u.status, u.date_of_birth, 0 AS mutual_friends
                FROM users u
                WHERE u.id != ?
                AND u.id NOT IN (
                    SELECT friend_id FROM friends WHERE user_id = ? AND status = 'accepted'
                    UNION
                    SELECT sender_id FROM friend_requests WHERE receiver_id = ?
                    UNION
                    SELECT receiver_id FROM friend_requests WHERE sender_id = ?
                    UNION
                    SELECT user_id FROM banned_users WHERE banned_by = ?
                )
                ORDER BY u.id LIMIT 5";
        
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed in suggestions: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message, "data" => []]);
            exit;
        }

        $stmt->bind_param("iiiii", $user_id, $user_id, $user_id, $user_id, $user_id);
        
        if (!$stmt->execute()) {
            $error_message = "SQL Error in suggestions: " . $stmt->error;
            echo json_encode(["success" => false, "message" => $error_message, "data" => []]);
            exit;
        }

        $result = $stmt->get_result();
        if ($result === false) {
            $error_message = "Result Error in suggestions: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message, "data" => []]);
            exit;
        }

        $suggestions = $result->fetch_all(MYSQLI_ASSOC);
        error_log("✅ Parsed " . count($suggestions) . " friend suggestions");
        echo json_encode(["success" => true, "message" => "Lấy danh sách gợi ý thành công", "data" => $suggestions]);
    } elseif ($action === "birthdays") {
        $sql = "SELECT u.id, u.name, u.avatar_url, u.date_of_birth 
                FROM friends f 
                JOIN users u ON f.friend_id = u.id 
                WHERE f.user_id = ? AND f.status = 'accepted' 
                AND (
                    (DAY(u.date_of_birth) = DAY(CURDATE()) AND MONTH(u.date_of_birth) = MONTH(CURDATE()))
                    OR (DAY(u.date_of_birth) = DAY(CURDATE() + INTERVAL 1 DAY) AND MONTH(u.date_of_birth) = MONTH(CURDATE() + INTERVAL 1 DAY))
                    OR MONTH(u.date_of_birth) >= MONTH(CURDATE())
                )
                ORDER BY MONTH(u.date_of_birth), DAY(u.date_of_birth)";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $birthdays = $result->fetch_all(MYSQLI_ASSOC);
        error_log("✅ Parsed " . count($birthdays) . " birthday friends");
        echo json_encode(["success" => true, "message" => "Lấy danh sách sinh nhật thành công", "data" => $birthdays]);
    } elseif ($action === "blocked_users") {
        $sql = "SELECT u.id, u.name, u.avatar_url, u.status, u.date_of_birth, 
                       (SELECT COUNT(*) FROM friends f1 
                        WHERE f1.user_id IN (SELECT friend_id FROM friends WHERE user_id = ? AND status = 'accepted') 
                        AND f1.friend_id = u.id AND f1.status = 'accepted') AS mutual_friends,
                       (SELECT created_at FROM friends WHERE user_id = ? AND friend_id = u.id AND status = 'accepted') AS created_at
                FROM banned_users bu 
                JOIN users u ON bu.user_id = u.id 
                WHERE bu.banned_by = ?";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $stmt->bind_param("iii", $user_id, $user_id, $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $blocked_users = $result->fetch_all(MYSQLI_ASSOC);
        error_log("✅ Parsed " . count($blocked_users) . " blocked users");
        echo json_encode(["success" => true, "message" => "Lấy danh sách người bị chặn thành công", "data" => $blocked_users]);
    } else {
        echo json_encode(["success" => false, "message" => "Hành động không hợp lệ"]);
    }
} elseif ($method === "POST") {
    $contentType = $_SERVER['HTTP_CONTENT_TYPE'] ?? $_SERVER['CONTENT_TYPE'] ?? '';
    if (strpos($contentType, 'application/json') === false) {
        echo json_encode(["success" => false, "message" => "Content-Type phải là application/json"]);
        exit;
    }

    $parsed_data = parseJsonInput();
    $action = $parsed_data["action"] ?? "";
    $sender_id = (int)($parsed_data["sender_id"] ?? 0);
    $receiver_id = (int)($parsed_data["receiver_id"] ?? 0);
    $request_id = (int)($parsed_data["request_id"] ?? 0);
    $response = $parsed_data["response"] ?? "";

    if (empty($action)) {
        echo json_encode(["success" => false, "message" => "Hành động không hợp lệ (action rỗng)"]);
        exit;
    }

    if ($action === "send_request") {
        if ($sender_id <= 0 || $receiver_id <= 0) {
            $error_message = "Thiếu sender_id hoặc receiver_id";
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }

        $sql = "SELECT id FROM users WHERE id IN (?, ?)";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $stmt->bind_param("ii", $sender_id, $receiver_id);
        $stmt->execute();
        $result = $stmt->get_result();
        if ($result->num_rows < 2) {
            echo json_encode(["success" => false, "message" => "Người gửi hoặc người nhận không tồn tại"]);
            exit;
        }

        $sql = "SELECT user_id FROM friends WHERE user_id = ? AND friend_id = ? AND status = 'accepted'";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $stmt->bind_param("ii", $sender_id, $receiver_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows > 0) {
            echo json_encode(["success" => false, "message" => "Đã là bạn bè"]);
            exit;
        }

        $sql = "SELECT id FROM friend_requests WHERE sender_id = ? AND receiver_id = ?";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $stmt->bind_param("ii", $sender_id, $receiver_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows > 0) {
            echo json_encode(["success" => false, "message" => "Yêu cầu kết bạn đã tồn tại"]);
            exit;
        }

        $sql = "SELECT user_id FROM banned_users WHERE user_id = ? AND banned_by = ?";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $stmt->bind_param("ii", $receiver_id, $sender_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows > 0) {
            echo json_encode(["success" => false, "message" => "Không thể gửi yêu cầu do bị chặn"]);
            exit;
        }

        $sql = "INSERT INTO friend_requests (sender_id, receiver_id, created_at) VALUES (?, ?, NOW())";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $stmt->bind_param("ii", $sender_id, $receiver_id);
        if ($stmt->execute()) {
            echo json_encode(["success" => true, "message" => "Gửi yêu cầu kết bạn thành công"]);
        } else {
            $error_message = "Insert failed: " . $stmt->error;
            echo json_encode(["success" => false, "message" => $error_message]);
        }
    } elseif ($action === "respond_request") {
        if ($request_id <= 0 || !in_array($response, ["accept", "reject"])) {
            $error_message = "Thiếu request_id hoặc response không hợp lệ";
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }

        if ($response === "accept") {
            $sql = "SELECT sender_id, receiver_id FROM friend_requests WHERE id = ?";
            $stmt = $conn->prepare($sql);
            if (!$stmt) {
                $error_message = "Prepare failed: " . $conn->error;
                echo json_encode(["success" => false, "message" => $error_message]);
                exit;
            }
            $stmt->bind_param("i", $request_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $request = $result->fetch_assoc();

            if ($request) {
                $sender_id = $request["sender_id"];
                $receiver_id = $request["receiver_id"];
                $sql = "INSERT INTO friends (user_id, friend_id, status, created_at) VALUES (?, ?, 'accepted', NOW()), (?, ?, 'accepted', NOW())";
                $stmt = $conn->prepare($sql);
                if (!$stmt) {
                    $error_message = "Prepare failed: " . $conn->error;
                    echo json_encode(["success" => false, "message" => $error_message]);
                    exit;
                }
                $stmt->bind_param("iiii", $sender_id, $receiver_id, $receiver_id, $sender_id);
                if (!$stmt->execute()) {
                    $error_message = "Insert failed: " . $stmt->error;
                    echo json_encode(["success" => false, "message" => $error_message]);
                    exit;
                }

                $sql = "DELETE FROM friend_requests WHERE id = ?";
                $stmt = $conn->prepare($sql);
                if (!$stmt) {
                    $error_message = "Prepare failed: " . $conn->error;
                    echo json_encode(["success" => false, "message" => $error_message]);
                    exit;
                }
                $stmt->bind_param("i", $request_id);
                $stmt->execute();

                // Trả về thông tin bạn bè mới để cập nhật giao diện
                $sql = "SELECT u.id, u.name, u.avatar_url, u.status, u.date_of_birth, 
                               (SELECT COUNT(*) FROM friends f1 
                                WHERE f1.user_id IN (SELECT friend_id FROM friends WHERE user_id = ? AND status = 'accepted') 
                                AND f1.friend_id = u.id AND f1.status = 'accepted') AS mutual_friends,
                               f.created_at
                        FROM users u 
                        JOIN friends f ON f.friend_id = u.id 
                        WHERE u.id = ? AND f.user_id = ? AND f.status = 'accepted'";
                $stmt = $conn->prepare($sql);
                if (!$stmt) {
                    $error_message = "Prepare failed: " . $conn->error;
                    echo json_encode(["success" => false, "message" => $error_message]);
                    exit;
                }
                $stmt->bind_param("iii", $receiver_id, $sender_id, $receiver_id);
                $stmt->execute();
                $result = $stmt->get_result();
                $new_friend = $result->fetch_assoc();
                echo json_encode(["success" => true, "message" => "Chấp nhận yêu cầu kết bạn thành công", "data" => $new_friend]);
            } else {
                echo json_encode(["success" => false, "message" => "Yêu cầu không tồn tại"]);
            }
        } elseif ($response === "reject") {
            $sql = "DELETE FROM friend_requests WHERE id = ?";
            $stmt = $conn->prepare($sql);
            if (!$stmt) {
                $error_message = "Prepare failed: " . $conn->error;
                echo json_encode(["success" => false, "message" => $error_message]);
                exit;
            }
            $stmt->bind_param("i", $request_id);
            $stmt->execute();
            echo json_encode(["success" => true, "message" => "Từ chối yêu cầu kết bạn thành công"]);
        }
    } else {
        $error_message = "Hành động không hợp lệ";
        echo json_encode(["success" => false, "message" => $error_message]);
    }
} elseif ($method === "PUT") {
    $contentType = $_SERVER['HTTP_CONTENT_TYPE'] ?? $_SERVER['CONTENT_TYPE'] ?? '';
    if (strpos($contentType, 'application/json') === false) {
        echo json_encode(["success" => false, "message" => "Content-Type phải là application/json"]);
        exit;
    }

    $parsed_data = parseJsonInput();
    $user_id = (int)($parsed_data["user_id"] ?? 0);
    $status = $parsed_data["status"] ?? "";

    if ($user_id <= 0 || !in_array($status, ["online", "offline", "idle", "dnd", "invisible"])) {
        echo json_encode(["success" => false, "message" => "Thiếu user_id hoặc status không hợp lệ"]);
        exit;
    }

    $sql = "SELECT id FROM users WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        $error_message = "Prepare failed: " . $conn->error;
        echo json_encode(["success" => false, "message" => $error_message]);
        exit;
    }
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    if ($stmt->get_result()->num_rows === 0) {
        echo json_encode(["success" => false, "message" => "Người dùng không tồn tại"]);
        exit;
    }

    $sql = "UPDATE users SET status = ? WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        $error_message = "Prepare failed: " . $conn->error;
        echo json_encode(["success" => false, "message" => $error_message]);
        exit;
    }
    $stmt->bind_param("si", $status, $user_id);
    if ($stmt->execute()) {
        echo json_encode(["success" => true, "message" => "Cập nhật trạng thái thành công"]);
    } else {
        $error_message = "Update failed: " . $stmt->error;
        echo json_encode(["success" => false, "message" => $error_message]);
    }
} elseif ($method === "DELETE") {
    $contentType = $_SERVER['HTTP_CONTENT_TYPE'] ?? $_SERVER['CONTENT_TYPE'] ?? '';
    if (strpos($contentType, 'application/json') === false) {
        echo json_encode(["success" => false, "message" => "Content-Type phải là application/json"]);
        exit;
    }

    $parsed_data = parseJsonInput();
    $user_id = (int)($parsed_data["user_id"] ?? 0);
    $friend_id = (int)($parsed_data["friend_id"] ?? 0);
    $action = $parsed_data["action"] ?? "";
    $reason = $parsed_data["reason"] ?? "Blocked by user";

    if ($user_id <= 0 || $friend_id <= 0) {
        $error_message = "Thiếu user_id hoặc friend_id";
        echo json_encode(["success" => false, "message" => $error_message]);
        exit;
    }

    $sql = "SELECT id FROM users WHERE id IN (?, ?)";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        $error_message = "Prepare failed: " . $conn->error;
        echo json_encode(["success" => false, "message" => $error_message]);
        exit;
    }
    $stmt->bind_param("ii", $user_id, $friend_id);
    $stmt->execute();
    if ($stmt->get_result()->num_rows < 2) {
        echo json_encode(["success" => false, "message" => "Người dùng hoặc bạn bè không tồn tại"]);
        exit;
    }

    if ($action === "unfriend") {
        $sql = "DELETE FROM friends WHERE (user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $stmt->bind_param("iiii", $user_id, $friend_id, $friend_id, $user_id);
        if ($stmt->execute()) {
            echo json_encode(["success" => true, "message" => "Hủy kết bạn thành công"]);
        } else {
            $error_message = "Delete failed: " . $stmt->error;
            echo json_encode(["success" => false, "message" => $error_message]);
        }
    } elseif ($action === "block") {
        $sql = "SELECT user_id FROM banned_users WHERE user_id = ? AND banned_by = ?";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $stmt->bind_param("ii", $friend_id, $user_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows > 0) {
            echo json_encode(["success" => false, "message" => "Người dùng đã bị chặn trước đó"]);
            exit;
        }

        $sql = "INSERT INTO banned_users (user_id, banned_by, reason, created_at) VALUES (?, ?, ?, NOW())";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $stmt->bind_param("iis", $friend_id, $user_id, $reason);
        if ($stmt->execute()) {
            $sql = "DELETE FROM friends WHERE (user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)";
            $stmt = $conn->prepare($sql);
            if (!$stmt) {
                $error_message = "Prepare failed: " . $conn->error;
                echo json_encode(["success" => false, "message" => $error_message]);
                exit;
            }
            $stmt->bind_param("iiii", $user_id, $friend_id, $friend_id, $user_id);
            $stmt->execute();

            echo json_encode(["success" => true, "message" => "Chặn người dùng thành công"]);
        } else {
            $error_message = "Insert failed: " . $stmt->error;
            echo json_encode(["success" => false, "message" => $error_message]);
        }
    } elseif ($action === "unblock") {
        $sql = "DELETE FROM banned_users WHERE user_id = ? AND banned_by = ?";
        $stmt = $conn->prepare($sql);
        if (!$stmt) {
            $error_message = "Prepare failed: " . $conn->error;
            echo json_encode(["success" => false, "message" => $error_message]);
            exit;
        }
        $stmt->bind_param("ii", $friend_id, $user_id);
        if ($stmt->execute()) {
            if ($stmt->affected_rows > 0) {
                echo json_encode(["success" => true, "message" => "Bỏ chặn người dùng thành công"]);
            } else {
                echo json_encode(["success" => false, "message" => "Người dùng không bị chặn"]);
            }
        } else {
            $error_message = "Delete failed: " . $stmt->error;
            echo json_encode(["success" => false, "message" => $error_message]);
        }
    } else {
        echo json_encode(["success" => false, "message" => "Hành động không hợp lệ"]);
    }
}

$conn->close();
?>
