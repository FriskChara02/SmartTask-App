#  notifications.php

<?php
include "db_connect.php";

header('Content-Type: application/json');
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type");

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        // Lấy tất cả thông báo
        ob_start(); // Bật output buffering
        $notifications = []; // Khởi tạo sớm
        $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : null;
        try {
            if ($user_id) {
                $sql = "SELECT n.* FROM notifications n LEFT JOIN tasks t ON n.task_id = t.id WHERE (t.user_id = ? OR t.user_id IS NULL) ORDER BY n.created_at DESC";
                $stmt = $conn->prepare($sql);
                if ($stmt === false) {
                    throw new Exception("Failed to prepare statement: " . $conn->error);
                }
                $stmt->bind_param("i", $user_id);
                if (!$stmt->execute()) {
                    throw new Exception("Failed to execute statement: " . $stmt->error);
                }
                $result = $stmt->get_result();
                while ($row = $result->fetch_assoc()) {
                    $notifications[] = [
                        "id" => $row['id'],
                        "message" => $row['message'],
                        "task_id" => $row['task_id'] ? (int)$row['task_id'] : null,
                        "is_read" => (bool)$row['is_read'],
                        "created_at" => date("c", strtotime($row['created_at'])) // Định dạng ISO8601
                    ];
                }
                $stmt->close();
            } else {
                $sql = "SELECT * FROM notifications ORDER BY created_at DESC";
                $result = $conn->query($sql);
                if ($result === false) {
                    throw new Exception("Failed to execute query: " . $conn->error);
                }
                while ($row = $result->fetch_assoc()) {
                    $notifications[] = [
                        "id" => $row['id'],
                        "message" => $row['message'],
                        "task_id" => $row['task_id'] ? (int)$row['task_id'] : null,
                        "is_read" => (bool)$row['is_read'],
                        "created_at" => date("c", strtotime($row['created_at'])) // Định dạng ISO8601
                    ];
                }
            }
            $json_response = json_encode($notifications, JSON_THROW_ON_ERROR);
            error_log("Notifications response: " . $json_response);
            header("Content-Length: " . strlen($json_response)); // Thêm Content-Length
            echo $json_response;
        } catch (Exception $e) {
            $error_response = json_encode(["error" => $e->getMessage()], JSON_THROW_ON_ERROR);
            http_response_code(500);
            error_log("GET notifications error: " . $e->getMessage());
            header("Content-Length: " . strlen($error_response)); // Thêm Content-Length cho lỗi
            echo $error_response;
        }
        ob_end_flush(); // Kết thúc output buffering
        break;

    case 'POST':
        // Thêm thông báo mới
        $raw_input = file_get_contents("php://input");
        error_log("Raw input: " . $raw_input);
        $data = json_decode($raw_input, true);
        error_log("Decoded data: " . print_r($data, true));

        if ($data === null) {
            http_response_code(400);
            echo json_encode(["error" => "Failed to decode JSON", "raw_input" => $raw_input]);
            break;
        }

        $id = $data['id'] ?? null;
        $message = $data['message'] ?? null;
        $task_id = $data['task_id'] ?? null; // Sửa từ 'taskId' thành 'task_id'
        $is_read = isset($data['isRead']) ? ($data['isRead'] ? 1 : 0) : 0;
        $created_at = isset($data['createdAt']) ? date("Y-m-d H:i:s", strtotime($data['createdAt'])) : date("Y-m-d H:i:s");

        error_log("Task ID before insert: " . ($task_id !== null ? $task_id : "null"));

        if (!$id || !$message) {
            http_response_code(400);
            echo json_encode(["error" => "ID and message are required"]);
            break;
        }

        $sql = "INSERT INTO notifications (id, message, task_id, is_read, created_at) VALUES (?, ?, ?, ?, ?)";
        $stmt = $conn->prepare($sql);
        if ($stmt === false) {
            http_response_code(500);
            echo json_encode(["error" => "Failed to prepare statement: " . $conn->error]);
            break;
        }

        $stmt->bind_param("sssis", $id, $message, $task_id, $is_read, $created_at);
        if ($stmt->execute()) {
            http_response_code(201);
            echo json_encode(["message" => "Notification added successfully"]);
        } else {
            http_response_code(500);
            echo json_encode(["error" => "Failed to add notification: " . $stmt->error]);
        }
        $stmt->close();
        break;

    case 'PUT':
        // Cập nhật thông báo (đánh dấu đã đọc hoặc tất cả)
        if (isset($_GET['mark_all']) && $_GET['mark_all'] === "true") {
            $sql = "UPDATE notifications SET is_read = 1";
            if ($conn->query($sql)) {
                echo json_encode(["message" => "All notifications marked as read"]);
            } else {
                http_response_code(500);
                echo json_encode(["error" => "Failed to mark all as read: " . $conn->error]);
            }
        } else {
            $id = $_GET['id'] ?? null;
            if (!$id) {
                http_response_code(400);
                echo json_encode(["error" => "Notification ID is required"]);
                break;
            }

            $data = json_decode(file_get_contents("php://input"), true);
            $is_read = isset($data['is_read']) ? ($data['is_read'] ? 1 : 0) : 1;

            $sql = "UPDATE notifications SET is_read = ? WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("is", $is_read, $id);
            if ($stmt->execute()) {
                echo json_encode(["message" => "Notification updated"]);
            } else {
                http_response_code(500);
                echo json_encode(["error" => "Failed to update notification: " . $stmt->error]);
            }
            $stmt->close();
        }
        break;

    case 'DELETE':
        // Xóa thông báo
        $data = json_decode(file_get_contents("php://input"), true);
        if (isset($data['ids']) && is_array($data['ids'])) {
            // Xóa nhiều thông báo
            $ids = $data['ids'];
            $placeholders = implode(',', array_fill(0, count($ids), '?'));
            $sql = "DELETE FROM notifications WHERE id IN ($placeholders)";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param(str_repeat('s', count($ids)), ...$ids);
            if ($stmt->execute()) {
                echo json_encode(["message" => "Notifications deleted"]);
            } else {
                http_response_code(500);
                echo json_encode(["error" => "Failed to delete notifications: " . $stmt->error]);
            }
            $stmt->close();
        } else {
            // Xóa một thông báo
            $id = $_GET['id'] ?? null;
            if (!$id) {
                http_response_code(400);
                echo json_encode(["error" => "Notification ID is required"]);
                break;
            }

            $sql = "DELETE FROM notifications WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("s", $id);
            if ($stmt->execute()) {
                echo json_encode(["message" => "Notification deleted"]);
            } else {
                http_response_code(500);
                echo json_encode(["error" => "Failed to delete notification: " . $stmt->error]);
            }
            $stmt->close();
        }
        break;
}

$conn->close();
?>
