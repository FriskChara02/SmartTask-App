#  upload_avatar.php

<?php
include "db_connect.php";

header('Content-Type: application/json');

// Lấy dữ liệu từ request
$user_id = $_POST['user_id'] ?? null;
$avatar = $_FILES['avatar'] ?? null;

// Kiểm tra dữ liệu đầu vào
if (!$user_id || !$avatar) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Thiếu user_id hoặc file avatar"]);
    exit;
}

// Kiểm tra lỗi upload file
if ($avatar['error'] !== UPLOAD_ERR_OK) {
    http_response_code(400);
    $error_messages = [
        UPLOAD_ERR_INI_SIZE => "File vượt quá kích thước tối đa cho phép (php.ini)",
        UPLOAD_ERR_FORM_SIZE => "File vượt quá kích thước tối đa của form",
        UPLOAD_ERR_PARTIAL => "File chỉ được upload một phần",
        UPLOAD_ERR_NO_FILE => "Không có file được upload",
        UPLOAD_ERR_NO_TMP_DIR => "Thiếu thư mục tạm để upload",
        UPLOAD_ERR_CANT_WRITE => "Không thể ghi file lên đĩa",
        UPLOAD_ERR_EXTENSION => "Upload bị chặn bởi extension PHP"
    ];
    $message = $error_messages[$avatar['error']] ?? "Lỗi upload không xác định (code: {$avatar['error']})";
    echo json_encode(["success" => false, "message" => $message]);
    exit;
}

// Kiểm tra định dạng file (chỉ cho phép JPEG, PNG)
$allowed_types = ['image/jpeg', 'image/png'];
$file_type = mime_content_type($avatar['tmp_name']);
if (!in_array($file_type, $allowed_types)) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Định dạng file không hợp lệ. Chỉ hỗ trợ JPEG hoặc PNG."]);
    exit;
}

// Kiểm tra kích thước file (giới hạn 5MB)
$max_size = 5 * 1024 * 1024; // 5MB
if ($avatar['size'] > $max_size) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "File quá lớn. Kích thước tối đa là 5MB."]);
    exit;
}

// Đường dẫn lưu file
$upload_dir = 'Uploads/';
$base_dir = __DIR__; // Thư mục hiện tại của file PHP
$full_upload_path = $base_dir . '/' . $upload_dir;

// Kiểm tra quyền thư mục cha
if (!is_writable($base_dir)) {
    http_response_code(500);
    error_log("DEBUG: Thư mục cha ($base_dir) không có quyền ghi");
    echo json_encode(["success" => false, "message" => "Thư mục cha không có quyền ghi"]);
    exit;
}

// Kiểm tra và tạo thư mục Uploads
if (!file_exists($full_upload_path)) {
    if (!mkdir($full_upload_path, 0777, true) || !chmod($full_upload_path, 0777)) {
        http_response_code(500);
        error_log("DEBUG: Không thể tạo hoặc thiết lập quyền cho thư mục Uploads ($full_upload_path)");
        echo json_encode(["success" => false, "message" => "Không thể tạo hoặc thiết lập quyền thư mục Uploads"]);
        exit;
    }
    error_log("DEBUG: Đã tạo thư mục Uploads ($full_upload_path)");
}

// Kiểm tra quyền ghi của thư mục Uploads
if (!is_writable($full_upload_path)) {
    http_response_code(500);
    error_log("DEBUG: Thư mục Uploads ($full_upload_path) không có quyền ghi");
    echo json_encode(["success" => false, "message" => "Thư mục Uploads không có quyền ghi"]);
    exit;
}

$extension = pathinfo($avatar['name'], PATHINFO_EXTENSION);
$avatar_path = $upload_dir . $user_id . '_' . time() . '.' . $extension;
$avatar_url = 'http://localhost/SmartTask_API/' . $avatar_path;

// Di chuyển file
if (move_uploaded_file($avatar['tmp_name'], $avatar_path)) {
    // Cập nhật database
    $sql = "UPDATE users SET avatar_url = ? WHERE id = ?";
    $stmt = $conn->prepare($sql);
    if ($stmt === false) {
        http_response_code(500);
        echo json_encode(["success" => false, "message" => "Lỗi chuẩn bị câu lệnh SQL: " . $conn->error]);
        exit;
    }
    $stmt->bind_param("si", $avatar_url, $user_id);
    if ($stmt->execute()) {
        echo json_encode(["success" => true, "message" => "Upload avatar thành công", "avatar_url" => $avatar_url]);
    } else {
        echo json_encode(["success" => false, "message" => "Lỗi cập nhật database: " . $stmt->error]);
    }
    $stmt->close();
} else {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Không thể lưu file avatar. Kiểm tra quyền thư mục Uploads."]);
}

$conn->close();
?>
