#  admin.php

**[Lưu ý]: Ở "$conn = new mysqli("localhost", "root", "", "SmartTask_DB");" --> "SmartTask_DB" ----> Đổi theo tên của bạn: "YourName_DB"


<?php
// admin.php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type");

// Kết nối database
$conn = new mysqli("localhost", "root", "", "SmartTask_DB");
if ($conn->connect_error) {
    error_log("DEBUG: Database connection failed: " . $conn->connect_error);
    echo json_encode(["success" => false, "message" => "Database connection failed"]);
    exit;
}

// Hàm parse multipart/form-data
function parseMultipartData() {
    $data = [];
    $input = file_get_contents('php://input');
    if (empty($input)) {
        error_log("DEBUG: No input data received for multipart/form-data");
        return $data;
    }
    $boundary = substr($input, 0, strpos($input, "\r\n"));
    $parts = array_slice(explode($boundary, $input), 1);
    
    foreach ($parts as $part) {
        if (strpos($part, 'Content-Disposition') !== false) {
            preg_match('/name="([^"]+)"/', $part, $nameMatch);
            preg_match('/\r\n\r\n(.+)\r\n--/', $part, $valueMatch);
            if (isset($nameMatch[1], $valueMatch[1])) {
                $data[$nameMatch[1]] = trim($valueMatch[1]);
            }
        }
    }
    return $data;
}

$method = $_SERVER["REQUEST_METHOD"];

if ($method === "GET") {
    // Xử lý các yêu cầu GET
    $action = $_GET["action"] ?? "";
    $admin_id = $_GET["admin_id"] ?? 0;

    // Kiểm tra quyền admin/super_admin
    $sql = "SELECT role FROM users WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $admin_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();

    if (!$user || !in_array($user['role'], ['admin', 'super_admin'])) {
        error_log("DEBUG: User $admin_id has no permission for GET action=$action");
        echo json_encode(["success" => false, "message" => "Không có quyền thực hiện hành động"]);
        exit;
    }

    if ($action === "sensitive_words") {
        // Lấy danh sách từ nhạy cảm
        $sql = "SELECT id, word, created_at FROM sensitive_words";
        $result = $conn->query($sql);
        $words = $result->fetch_all(MYSQLI_ASSOC);
        echo json_encode(["success" => true, "message" => "Lấy danh sách từ nhạy cảm thành công", "data" => $words]);
    } elseif ($action === "users") {
        // Lấy danh sách người dùng
        $sql = "SELECT id AS user_id, name, email, avatar_url, description, date_of_birth, location, joined_date, gender, hobbies, bio, status, role FROM users";
        $result = $conn->query($sql);
        $users = $result->fetch_all(MYSQLI_ASSOC);
        echo json_encode(["success" => true, "message" => "Lấy danh sách người dùng thành công", "data" => $users]);
    }  elseif ($action === "stats") {
        // Lấy thống kê hoạt động
        $sql = "
            SELECT
                (SELECT COUNT(*) FROM users) AS user_count,
                (SELECT COUNT(*) FROM users WHERE status = 'online') AS online_count,
                (SELECT COUNT(*) FROM users WHERE role = 'admin') AS admin_count,
                (SELECT COUNT(*) FROM users WHERE role = 'super_admin') AS super_admin_count,
                (SELECT COUNT(*) FROM world_chat) AS world_message_count,
                (SELECT COUNT(*) FROM private_chat) AS private_message_count,
                (SELECT COUNT(*) FROM group_chat) AS group_message_count,
                (SELECT COUNT(*) FROM groups) AS group_count,
                (SELECT COUNT(*) FROM group_projects) AS project_count,
                (SELECT COUNT(*) FROM group_tasks) AS task_count
        ";
        $result = $conn->query($sql);
        $stats = $result->fetch_assoc();
        $stats['message_count'] = (int)$stats['world_message_count'] + (int)$stats['private_message_count'] + (int)$stats['group_message_count'];
        echo json_encode(["success" => true, "message" => "Lấy thống kê thành công", "data" => $stats]);
    } else {
        error_log("DEBUG: Invalid GET action: $action");
        echo json_encode(["success" => false, "message" => "Hành động không hợp lệ"]);
    }
} elseif ($method === "POST") {
    // Xử lý các yêu cầu POST
    $action = $_POST["action"] ?? "";
    $admin_id = $_POST["admin_id"] ?? 0;

    // Kiểm tra quyền admin/super_admin
    $sql = "SELECT role FROM users WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $admin_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();

    if (!$user || !in_array($user['role'], ['admin', 'super_admin'])) {
        error_log("DEBUG: User $admin_id has no permission for POST action=$action");
        echo json_encode(["success" => false, "message" => "Không có quyền thực hiện hành động"]);
        exit;
    }

    if ($action === "add_sensitive_word") {
        // Thêm từ nhạy cảm
        $word = $_POST["word"] ?? "";
        if (!$word) {
            error_log("DEBUG: Missing word for add_sensitive_word action");
            echo json_encode(["success" => false, "message" => "Thiếu word"]);
            exit;
        }
        // Kiểm tra trùng lặp
        $sql = "SELECT id FROM sensitive_words WHERE word = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("s", $word);
        $stmt->execute();
        if ($stmt->get_result()->num_rows > 0) {
            error_log("DEBUG: Word '$word' already exists");
            echo json_encode(["success" => false, "message" => "Từ nhạy cảm đã tồn tại"]);
            exit;
        }
        $sql = "INSERT INTO sensitive_words (word) VALUES (?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("s", $word);
        if ($stmt->execute()) {
            error_log("DEBUG: Added sensitive word '$word'");
            echo json_encode(["success" => true, "message" => "Thêm từ nhạy cảm thành công"]);
        } else {
            error_log("DEBUG: Failed to add sensitive word '$word': " . $conn->error);
            echo json_encode(["success" => false, "message" => "Thêm từ nhạy cảm thất bại"]);
        }
    } elseif ($action === "create_group") {
        // Tạo nhóm
        $name = $_POST["name"] ?? "";
        $type = $_POST["type"] ?? "";
        if (!$name || !$type) {
            error_log("DEBUG: Missing name or type for create_group action");
            echo json_encode(["success" => false, "message" => "Thiếu name hoặc type"]);
            exit;
        }
        $sql = "INSERT INTO groups (name, type, created_by, created_at) VALUES (?, ?, ?, NOW())";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ssi", $name, $type, $admin_id);
        if ($stmt->execute()) {
            $group_id = $conn->insert_id;
            $sql = "INSERT INTO group_members (group_id, user_id) VALUES (?, ?)";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("ii", $group_id, $admin_id);
            if ($stmt->execute()) {
                error_log("DEBUG: Created group $group_id and added admin $admin_id");
                echo json_encode(["success" => true, "message" => "Tạo nhóm thành công", "data" => ["group_id" => $group_id]]);
            } else {
                error_log("DEBUG: Failed to add admin $admin_id to group $group_id: " . $conn->error);
                echo json_encode(["success" => false, "message" => "Thêm admin vào nhóm thất bại"]);
            }
        } else {
            error_log("DEBUG: Failed to create group: " . $conn->error);
            echo json_encode(["success" => false, "message" => "Tạo nhóm thất bại"]);
        }
    } elseif ($action === "add_member") {
        // Thêm thành viên vào nhóm
        $group_id = $_POST["group_id"] ?? 0;
        $user_id = $_POST["user_id"] ?? 0;
        if (!$group_id || !$user_id) {
            error_log("DEBUG: Missing group_id or user_id for add_member action");
            echo json_encode(["success" => false, "message" => "Thiếu group_id hoặc user_id"]);
            exit;
        }
        // Kiểm tra group_id và user_id
        $sql = "SELECT id FROM groups WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $group_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            error_log("DEBUG: Group $group_id does not exist");
            echo json_encode(["success" => false, "message" => "Group không tồn tại"]);
            exit;
        }
        $sql = "SELECT id FROM users WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            error_log("DEBUG: User $user_id does not exist");
            echo json_encode(["success" => false, "message" => "User không tồn tại"]);
            exit;
        }
        // Kiểm tra đã là thành viên chưa
        $sql = "SELECT * FROM group_members WHERE group_id = ? AND user_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $group_id, $user_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows > 0) {
            error_log("DEBUG: User $user_id already a member of group $group_id");
            echo json_encode(["success" => false, "message" => "User đã là thành viên"]);
            exit;
        }
        $sql = "INSERT INTO group_members (group_id, user_id) VALUES (?, ?)";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $group_id, $user_id);
        if ($stmt->execute()) {
            error_log("DEBUG: Added user $user_id to group $group_id");
            echo json_encode(["success" => true, "message" => "Thêm thành viên thành công"]);
        } else {
            error_log("DEBUG: Failed to add user $user_id to group $group_id: " . $conn->error);
            echo json_encode(["success" => false, "message" => "Thêm thành viên thất bại"]);
        }
    } else {
        error_log("DEBUG: Invalid POST action: $action");
        echo json_encode(["success" => false, "message" => "Hành động không hợp lệ"]);
    }
} elseif ($method === "PUT") {
    // Xử lý các yêu cầu PUT
    $put_vars = parseMultipartData();
    $action = $put_vars["action"] ?? "";
    $admin_id = $put_vars["admin_id"] ?? 0;

    // Kiểm tra quyền admin/super_admin
    $sql = "SELECT role FROM users WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $admin_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();

    if (!$user || !in_array($user['role'], ['admin', 'super_admin'])) {
        error_log("DEBUG: User $admin_id has no permission for PUT action=$action");
        echo json_encode(["success" => false, "message" => "Không có quyền thực hiện hành động"]);
        exit;
    }

    if ($action === "promote") {
        // Nâng cấp vai trò người dùng
        $user_id = $put_vars["user_id"] ?? 0;
        $new_role = $put_vars["new_role"] ?? "";
        if (!$user_id || !$new_role) {
            error_log("DEBUG: Missing user_id or new_role for promote action");
            echo json_encode(["success" => false, "message" => "Thiếu user_id hoặc new_role"]);
            exit;
        }
        // Kiểm tra quyền: chỉ super_admin được phép promote
        if ($user['role'] !== 'super_admin') {
            error_log("DEBUG: User $admin_id is not super_admin for promote action");
            echo json_encode(["success" => false, "message" => "Chỉ super_admin có quyền thực hiện hành động này"]);
            exit;
        }
        // Kiểm tra new_role hợp lệ
        if (!in_array($new_role, ['user', 'admin', 'super_admin'])) {
            error_log("DEBUG: Invalid new_role '$new_role' for user $user_id");
            echo json_encode(["success" => false, "message" => "Vai trò không hợp lệ"]);
            exit;
        }
        // Kiểm tra user_id
        $sql = "SELECT id FROM users WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            error_log("DEBUG: User $user_id does not exist for promote action");
            echo json_encode(["success" => false, "message" => "User không tồn tại"]);
            exit;
        }
        $sql = "UPDATE users SET role = ? WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("si", $new_role, $user_id);
        if ($stmt->execute()) {
            error_log("DEBUG: Promoted user $user_id to $new_role by admin $admin_id");
            echo json_encode(["success" => true, "message" => "Cập nhật vai trò người dùng thành công"]);
        } else {
            error_log("DEBUG: Failed to promote user $user_id to $new_role: " . $conn->error);
            echo json_encode(["success" => false, "message" => "Cập nhật vai trò người dùng thất bại: " . $conn->error]);
        }
    } elseif ($action === "update_group") {
        // Sửa nhóm
        $group_id = $put_vars["group_id"] ?? 0;
        $name = $put_vars["name"] ?? null;
        $type = $put_vars["type"] ?? null;
        if (!$group_id) {
            error_log("DEBUG: Missing group_id for update_group action");
            echo json_encode(["success" => false, "message" => "Thiếu group_id"]);
            exit;
        }
        // Kiểm tra group_id
        $sql = "SELECT id FROM groups WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $group_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            error_log("DEBUG: Group $group_id does not exist");
            echo json_encode(["success" => false, "message" => "Group không tồn tại"]);
            exit;
        }
        $updates = [];
        $params = [];
        $types = "";
        if ($name !== null) {
            $updates[] = "name = ?";
            $params[] = $name;
            $types .= "s";
        }
        if ($type !== null) {
            $updates[] = "type = ?";
            $params[] = $type;
            $types .= "s";
        }
        if (empty($updates)) {
            error_log("DEBUG: No fields to update for group $group_id");
            echo json_encode(["success" => false, "message" => "Không có thông tin để cập nhật"]);
            exit;
        }
        $sql = "UPDATE groups SET " . implode(", ", $updates) . " WHERE id = ? AND created_by = ?";
        $params[] = $group_id;
        $params[] = $admin_id;
        $types .= "ii";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types, ...$params);
        if ($stmt->execute()) {
            error_log("DEBUG: Updated group $group_id by admin $admin_id");
            echo json_encode(["success" => true, "message" => "Cập nhật nhóm thành công"]);
        } else {
            error_log("DEBUG: Failed to update group $group_id: " . $conn->error);
            echo json_encode(["success" => false, "message" => "Cập nhật nhóm thất bại: " . $conn->error]);
        }
    } else {
        error_log("DEBUG: Invalid PUT action: $action");
        echo json_encode(["success" => false, "message" => "Hành động không hợp lệ"]);
    }
} elseif ($method === "DELETE") {
    // Xử lý các yêu cầu DELETE
    $delete_vars = parseMultipartData();
    $action = $delete_vars["action"] ?? "";
    $admin_id = $delete_vars["admin_id"] ?? 0;

    // Kiểm tra quyền admin/super_admin
    $sql = "SELECT role FROM users WHERE id = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $admin_id);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();

    if (!$user || !in_array($user['role'], ['admin', 'super_admin'])) {
        error_log("DEBUG: User $admin_id has no permission for DELETE action=$action");
        echo json_encode(["success" => false, "message" => "Không có quyền thực hiện hành động"]);
        exit;
    }

    if ($action === "delete_group") {
        // Xóa nhóm
        $group_id = $delete_vars["group_id"] ?? 0;
        if (!$group_id) {
            error_log("DEBUG: Missing group_id for delete_group action");
            echo json_encode(["success" => false, "message" => "Thiếu group_id"]);
            exit;
        }
        // Kiểm tra group_id
        $sql = "SELECT id FROM groups WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $group_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            error_log("DEBUG: Group $group_id does not exist");
            echo json_encode(["success" => false, "message" => "Group không tồn tại"]);
            exit;
        }
        $sql = "DELETE FROM groups WHERE id = ? AND created_by = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $group_id, $admin_id);
        if ($stmt->execute()) {
            error_log("DEBUG: Deleted group $group_id by admin $admin_id");
            echo json_encode(["success" => true, "message" => "Xóa nhóm thành công"]);
        } else {
            error_log("DEBUG: Failed to delete group $group_id: " . $conn->error);
            echo json_encode(["success" => false, "message" => "Xóa nhóm thất bại"]);
        }
    } elseif ($action === "remove_member") {
        // Xóa thành viên khỏi nhóm
        $group_id = $delete_vars["group_id"] ?? 0;
        $user_id = $delete_vars["user_id"] ?? 0;
        if (!$group_id || !$user_id) {
            error_log("DEBUG: Missing group_id or user_id for remove_member action");
            echo json_encode(["success" => false, "message" => "Thiếu group_id hoặc user_id"]);
            exit;
        }
        // Kiểm tra group_id và user_id
        $sql = "SELECT id FROM groups WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $group_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            error_log("DEBUG: Group $group_id does not exist");
            echo json_encode(["success" => false, "message" => "Group không tồn tại"]);
            exit;
        }
        $sql = "SELECT id FROM users WHERE id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        if ($stmt->get_result()->num_rows === 0) {
            error_log("DEBUG: User $user_id does not exist");
            echo json_encode(["success" => false, "message" => "User không tồn tại"]);
            exit;
        }
        $sql = "DELETE FROM group_members WHERE group_id = ? AND user_id = ?";
        $stmt = $conn->prepare($sql);
        $stmt->bind_param("ii", $group_id, $user_id);
        if ($stmt->execute()) {
            error_log("DEBUG: Removed user $user_id from group $group_id by admin $admin_id");
            echo json_encode(["success" => true, "message" => "Xóa thành viên thành công"]);
        } else {
            error_log("DEBUG: Failed to remove user $user_id from group $group_id: " . $conn->error);
            echo json_encode(["success" => false, "message" => "Xóa thành viên thất bại"]);
        }
    } else {
        error_log("DEBUG: Invalid DELETE action: $action");
        echo json_encode(["success" => false, "message" => "Hành động không hợp lệ"]);
    }
}

// Đóng kết nối database
$conn->close();
?>
