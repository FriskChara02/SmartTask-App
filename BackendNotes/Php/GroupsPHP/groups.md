#  groups.php

**[Lưu ý]: Ở "$conn = new mysqli("localhost", "root", "", "SmartTask_DB");" --> "SmartTask_DB" ----> Đổi theo tên của bạn: "YourName_DB"


<?php
// groups.php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");
header("Access-Control-Allow-Headers: Content-Type");

// Kiểm tra PHP có lỗi cú pháp hoặc thực thi không
error_log("DEBUG: groups.php started");

// Hàm parse multipart/form-data cho PUT và DELETE
function parseMultipartFormData($boundary) {
    $data = [];
    $input = file_get_contents('php://input');
    error_log("DEBUG: Raw input data: $input"); // Log dữ liệu thô để debug

    // Tách các phần của multipart/form-data
    $parts = explode("--$boundary", $input);
    foreach ($parts as $part) {
        if (trim($part) === '' || $part === '--') {
            continue;
        }
        // Tách header và body của mỗi phần
        if (preg_match('/Content-Disposition: form-data; name="([^"]+)"\r\n\r\n(.*)\r\n/', $part, $matches)) {
            $name = $matches[1];
            $value = $matches[2];
            $data[$name] = $value;
            error_log("DEBUG: Parsed form-data: $name = $value"); // Log từng field đã parse
        }
    }
    return $data;
}

try {
    // Kết nối database
    $conn = new mysqli("localhost", "root", "", "SmartTask_DB");
    if ($conn->connect_error) {
        error_log("DEBUG: Database connection failed: " . $conn->connect_error);
        echo json_encode(["success" => false, "message" => "Database connection failed: " . $conn->connect_error]);
        exit;
    }

    $method = $_SERVER["REQUEST_METHOD"];

    if ($method === "GET") {
        $action = $_GET["action"] ?? "";
        $user_id = $_GET["user_id"] ?? 0;
        $role = $_GET["role"] ?? "user";
        error_log("DEBUG: GET action=$action, user_id=$user_id, role=$role");

        if ($user_id) {
            $sql = "SELECT id FROM users WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $user_id);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                error_log("DEBUG: User $user_id does not exist for GET action=$action");
                echo json_encode(["success" => false, "message" => "User không tồn tại"]);
                exit;
            }
        }

        if ($action === "list") {
            if ($role === "super_admin") {
                // Super admin thấy tất cả nhóm
                $sql = "SELECT id, name, created_by, created_at, color, icon 
                        FROM groups";
                $stmt = $conn->prepare($sql);
            } else {
                // Người dùng thường thấy nhóm họ tạo hoặc là thành viên
                $sql = "SELECT DISTINCT g.id, g.name, g.created_by, g.created_at, g.color, g.icon 
                        FROM groups g 
                        LEFT JOIN group_members gm ON g.id = gm.group_id 
                        WHERE g.created_by = ? OR gm.user_id = ?";
                $stmt = $conn->prepare($sql);
                $stmt->bind_param("ii", $user_id, $user_id);
            }
            $stmt->execute();
            $result = $stmt->get_result();
            $groups = $result->fetch_all(MYSQLI_ASSOC);
            echo json_encode(["success" => true, "message" => "Lấy danh sách nhóm thành công", "data" => $groups]);
        } elseif ($action === "projects") {
            $group_id = $_GET["group_id"] ?? 0;
            $sql = "SELECT id FROM groups WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $group_id);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                error_log("DEBUG: Group $group_id does not exist for action=projects");
                echo json_encode(["success" => false, "message" => "Group không tồn tại"]);
                exit;
            }
            $sql = "SELECT p.id, p.name, p.progress, p.created_at, 
                           (SELECT COUNT(*) FROM group_tasks t WHERE t.project_id = p.id) AS task_count 
                    FROM group_projects p 
                    WHERE p.group_id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $group_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $projects = $result->fetch_all(MYSQLI_ASSOC);
            echo json_encode(["success" => true, "message" => "Lấy danh sách dự án thành công", "data" => $projects]);
        } elseif ($action === "tasks") {
            $project_id = $_GET["project_id"] ?? 0;
            $sql = "SELECT id FROM group_projects WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $project_id);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                error_log("DEBUG: Project $project_id does not exist for action=tasks");
                echo json_encode(["success" => false, "message" => "Project không tồn tại"]);
                exit;
            }
            $sql = "SELECT t.id, t.title, t.description, t.due_date, t.is_completed, t.priority 
                    FROM group_tasks t 
                    WHERE t.project_id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $project_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $tasks = $result->fetch_all(MYSQLI_ASSOC);

            // Lấy danh sách assigned_to và assigned_to_names cho mỗi task
            foreach ($tasks as &$task) {
                $task_id = $task['id'];
                $sql = "SELECT u.id, u.name 
                        FROM task_assignments ta 
                        JOIN users u ON ta.user_id = u.id 
                        WHERE ta.task_id = ?";
                $stmt = $conn->prepare($sql);
                $stmt->bind_param("i", $task_id);
                $stmt->execute();
                $result = $stmt->get_result();
                $assignments = $result->fetch_all(MYSQLI_ASSOC);
                $task['assigned_to'] = array_map('intval', array_column($assignments, 'id')); // Đảm bảo id là int
                $task['assigned_to_names'] = array_column($assignments, 'name');
                $task['is_completed'] = (bool)$task['is_completed']; // Chuyển is_completed thành bool
            }
            unset($task); // Hủy tham chiếu để tránh lỗi
            error_log("DEBUG: Tasks fetched for project_id=$project_id: " . json_encode($tasks));
            echo json_encode(["success" => true, "message" => "Lấy danh sách nhiệm vụ thành công", "data" => $tasks]);
        } elseif ($action === "members") {
            $group_id = $_GET["group_id"] ?? 0;
            $sql = "SELECT id FROM groups WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $group_id);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                error_log("DEBUG: Group $group_id does not exist for action=members");
                echo json_encode(["success" => false, "message" => "Group không tồn tại"]);
                exit;
            }
            $sql = "SELECT u.id, u.name, u.avatar_url 
                    FROM group_members gm 
                    JOIN users u ON gm.user_id = u.id 
                    WHERE gm.group_id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $group_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $members = $result->fetch_all(MYSQLI_ASSOC);
            echo json_encode(["success" => true, "message" => "Lấy danh sách thành viên thành công", "data" => $members]);
        } elseif ($action === "get_user") {
            // Endpoint mới để lấy thông tin user
            $user_id = $_GET["user_id"] ?? 0;
            error_log("DEBUG: Get user info for user_id=$user_id");
            if (!$user_id) {
                error_log("DEBUG: Missing user_id for get_user");
                echo json_encode(["success" => false, "message" => "Thiếu user_id"]);
                exit;
            }
            $sql = "SELECT id, name, email, avatar_url, role 
                    FROM users 
                    WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $user_id);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                error_log("DEBUG: User $user_id does not exist for get_user");
                echo json_encode(["success" => false, "message" => "User không tồn tại"]);
                exit;
            }
            $user = $result->fetch_assoc();
            echo json_encode(["success" => true, "message" => "Lấy thông tin user thành công", "data" => $user]);
        } elseif ($action === "get_group_id") {
            // Endpoint mới để lấy group_id từ project_id
            $project_id = $_GET["project_id"] ?? 0;
            error_log("DEBUG: Get group_id for project_id=$project_id");
            if (!$project_id) {
                error_log("DEBUG: Missing project_id for get_group_id");
                echo json_encode(["success" => false, "message" => "Thiếu project_id"]);
                exit;
            }
            $sql = "SELECT group_id FROM group_projects WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $project_id);
            $stmt->execute();
            $result = $stmt->get_result();
            if ($result->num_rows === 0) {
                error_log("DEBUG: Project $project_id does not exist for get_group_id");
                echo json_encode(["success" => false, "message" => "Project không tồn tại"]);
                exit;
            }
            $row = $result->fetch_assoc();
            $group_id = $row["group_id"];
            echo json_encode([
                "success" => true,
                "message" => "Lấy group_id thành công",
                "group_id" => $group_id
            ]);
        } else {
            error_log("DEBUG: Invalid GET action: $action");
            echo json_encode(["success" => false, "message" => "Hành động không hợp lệ"]);
        }
    } elseif ($method === "POST") {
        // Debug toàn bộ dữ liệu POST
        error_log("DEBUG: Raw POST data: " . print_r($_POST, true));
        $action = $_POST["action"] ?? "";
        error_log("DEBUG: POST action=$action");

        if ($action === "create") {
            $name = $_POST["name"] ?? "";
            $created_by = $_POST["created_by"] ?? 0;
            $color = $_POST["color"] ?? "blue";
            $icon = $_POST["icon"] ?? "person.3.fill";
            error_log("DEBUG: Create group params: name=$name, created_by=$created_by, color=$color, icon=$icon");

            if (!$name || !$created_by) {
                error_log("DEBUG: Missing name or created_by for create group");
                echo json_encode(["success" => false, "message" => "Thiếu name hoặc created_by"]);
                exit;
            }

            $sql = "SELECT id FROM users WHERE id = ?";
            $stmt = $conn->prepare($sql);
            if (!$stmt) {
                error_log("DEBUG: Prepare failed for SELECT users: " . $conn->error);
                echo json_encode(["success" => false, "message" => "Lỗi chuẩn bị truy vấn: " . $conn->error]);
                exit;
            }
            $stmt->bind_param("i", $created_by);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                error_log("DEBUG: User $created_by does not exist");
                echo json_encode(["success" => false, "message" => "User không tồn tại"]);
                exit;
            }

            $sql = "INSERT INTO groups (name, created_by, created_at, color, icon) VALUES (?, ?, NOW(), ?, ?)";
            $stmt = $conn->prepare($sql);
            if (!$stmt) {
                error_log("DEBUG: Prepare failed for INSERT groups: " . $conn->error);
                echo json_encode(["success" => false, "message" => "Lỗi chuẩn bị truy vấn: " . $conn->error]);
                exit;
            }
            $stmt->bind_param("siss", $name, $created_by, $color, $icon);
            if ($stmt->execute()) {
                $group_id = $conn->insert_id;
                error_log("DEBUG: Created group $group_id successfully");

                // Thêm creator vào group_members
                $sql = "INSERT INTO group_members (group_id, user_id) VALUES (?, ?)";
                $stmt = $conn->prepare($sql);
                if (!$stmt) {
                    error_log("DEBUG: Prepare failed for INSERT group_members: " . $conn->error);
                    echo json_encode(["success" => false, "message" => "Lỗi chuẩn bị truy vấn: " . $conn->error]);
                    exit;
                }
                $stmt->bind_param("ii", $group_id, $created_by);
                $stmt->execute();

                // Cập nhật role thành admin nếu là user
                $sql = "UPDATE users SET role = 'admin' WHERE id = ? AND role = 'user'";
                $stmt = $conn->prepare($sql);
                if (!$stmt) {
                    error_log("DEBUG: Prepare failed for UPDATE users: " . $conn->error);
                    echo json_encode(["success" => false, "message" => "Lỗi chuẩn bị truy vấn: " . $conn->error]);
                    exit;
                }
                $stmt->bind_param("i", $created_by);
                $stmt->execute();

                echo json_encode([
                    "success" => true,
                    "message" => "Tạo nhóm thành công",
                    "group_id" => $group_id
                ]);
            } else {
                error_log("DEBUG: Failed to create group: " . $conn->error);
                echo json_encode(["success" => false, "message" => "Tạo nhóm thất bại: " . $conn->error]);
            }
        } elseif ($action === "add_member") {
            $group_id = $_POST["group_id"] ?? 0;
            $user_id = $_POST["user_id"] ?? 0;
            error_log("DEBUG: Add member params: group_id=$group_id, user_id=$user_id");

            if (!$group_id || !$user_id) {
                error_log("DEBUG: Missing group_id or user_id for add_member");
                echo json_encode(["success" => false, "message" => "Thiếu group_id hoặc user_id"]);
                exit;
            }
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
                error_log("DEBUG: Failed to add member: " . $conn->error);
                echo json_encode(["success" => false, "message" => "Thêm thành viên thất bại: " . $conn->error]);
            }
        } elseif ($action === "create_project") {
            $group_id = $_POST["group_id"] ?? 0;
            $name = $_POST["name"] ?? "";
            error_log("DEBUG: Create project params: group_id=$group_id, name=$name");

            if (!$group_id || !$name) {
                error_log("DEBUG: Missing group_id or name for create_project");
                echo json_encode(["success" => false, "message" => "Thiếu group_id hoặc name"]);
                exit;
            }
            $sql = "SELECT id FROM groups WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $group_id);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                error_log("DEBUG: Group $group_id does not exist");
                echo json_encode(["success" => false, "message" => "Group không tồn tại"]);
                exit;
            }
            $sql = "INSERT INTO group_projects (group_id, name) VALUES (?, ?)";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("is", $group_id, $name);
            if ($stmt->execute()) {
                error_log("DEBUG: Created project for group $group_id");
                echo json_encode(["success" => true, "message" => "Tạo dự án thành công"]);
            } else {
                error_log("DEBUG: Failed to create project: " . $conn->error);
                echo json_encode(["success" => false, "message" => "Tạo dự án thất bại: " . $conn->error]);
            }
        } elseif ($action === "add_task") {
            $project_id = $_POST["project_id"] ?? 0;
            $title = $_POST["title"] ?? "";
            $description = $_POST["description"] ?? null;
            $assigned_to = isset($_POST["assigned_to"]) ? $_POST["assigned_to"] : []; // Mảng assigned_to
            $due_date = $_POST["due_date"] ?? null;
            $priority = $_POST["priority"] ?? "Medium";
            error_log("DEBUG: Add task params: project_id=$project_id, title=$title, assigned_to=" . print_r($assigned_to, true));

            if (!$project_id || !$title) {
                error_log("DEBUG: Missing project_id or title for add_task");
                echo json_encode(["success" => false, "message" => "Thiếu project_id hoặc title"]);
                exit;
            }

            $sql = "SELECT id FROM group_projects WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $project_id);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                error_log("DEBUG: Project $project_id does not exist");
                echo json_encode(["success" => false, "message" => "Project không tồn tại"]);
                exit;
            }

            // Kiểm tra tất cả user_id trong assigned_to
            if (!empty($assigned_to)) {
                foreach ($assigned_to as $user_id) {
                    $sql = "SELECT id FROM users WHERE id = ?";
                    $stmt = $conn->prepare($sql);
                    $stmt->bind_param("i", $user_id);
                    $stmt->execute();
                    if ($stmt->get_result()->num_rows === 0) {
                        error_log("DEBUG: Assigned user $user_id does not exist");
                        echo json_encode(["success" => false, "message" => "User được giao ($user_id) không tồn tại"]);
                        exit;
                    }
                }
            }

            // Thêm task vào group_tasks
            $sql = "INSERT INTO group_tasks (project_id, title, description, due_date, priority) VALUES (?, ?, ?, ?, ?)";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("issss", $project_id, $title, $description, $due_date, $priority);
            if ($stmt->execute()) {
                $task_id = $conn->insert_id;
                error_log("DEBUG: Added task $task_id to project $project_id");

                // Thêm các assigned_to vào task_assignments
                if (!empty($assigned_to)) {
                    $sql = "INSERT INTO task_assignments (task_id, user_id) VALUES (?, ?)";
                    $stmt = $conn->prepare($sql);
                    foreach ($assigned_to as $user_id) {
                        $stmt->bind_param("ii", $task_id, $user_id);
                        if (!$stmt->execute()) {
                            error_log("DEBUG: Failed to assign user $user_id to task $task_id: " . $conn->error);
                            echo json_encode(["success" => false, "message" => "Thêm người được giao thất bại: " . $conn->error]);
                            exit;
                        }
                    }
                }

                echo json_encode(["success" => true, "message" => "Thêm nhiệm vụ thành công"]);
            } else {
                error_log("DEBUG: Failed to add task: " . $conn->error);
                echo json_encode(["success" => false, "message" => "Thêm nhiệm vụ thất bại: " . $conn->error]);
            }
        } else {
            error_log("DEBUG: Invalid action for POST: $action");
            echo json_encode(["success" => false, "message" => "Hành động không hợp lệ"]);
        }
    } elseif ($method === "PUT") {
        // Parse multipart/form-data cho PUT
        $content_type = $_SERVER["CONTENT_TYPE"] ?? "";
        $parsed_data = [];
        if (preg_match('/boundary=(.*)$/', $content_type, $matches)) {
            $boundary = $matches[1];
            $parsed_data = parseMultipartFormData($boundary);
        } else {
            error_log("DEBUG: No boundary found in Content-Type for PUT");
            echo json_encode(["success" => false, "message" => "Não tìm thấy boundary trong Content-Type"]);
            exit;
        }

        // Debug dữ liệu đã parse
        error_log("DEBUG: Parsed PUT data: " . print_r($parsed_data, true));
        $action = $parsed_data["action"] ?? "";
        error_log("DEBUG: PUT action=$action");

        if ($action === "update_group") {
            $group_id = $parsed_data["group_id"] ?? 0;
            $name = $parsed_data["name"] ?? "";
            $color = $parsed_data["color"] ?? "blue";
            $icon = $parsed_data["icon"] ?? "person.3.fill";
            error_log("DEBUG: Update group params: group_id=$group_id, name=$name, color=$color, icon=$icon");

            if (!$group_id || !$name) {
                error_log("DEBUG: Missing group_id or name for update_group");
                echo json_encode(["success" => false, "message" => "Thiếu group_id hoặc name"]);
                exit;
            }
            $sql = "SELECT id FROM groups WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $group_id);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                error_log("DEBUG: Group $group_id does not exist");
                echo json_encode(["success" => false, "message" => "Group không tồn tại"]);
                exit;
            }
            $sql = "UPDATE groups SET name = ?, color = ?, icon = ? WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("sssi", $name, $color, $icon, $group_id);
            if ($stmt->execute()) {
                error_log("DEBUG: Updated group $group_id");
                echo json_encode(["success" => true, "message" => "Cập nhật nhóm thành công"]);
            } else {
                error_log("DEBUG: Failed to update group: " . $conn->error);
                echo json_encode(["success" => false, "message" => "Cập nhật nhóm thất bại: " . $conn->error]);
            }
        } elseif ($action === "update_task") {
            $task_id = $parsed_data["task_id"] ?? 0;
            $title = $parsed_data["title"] ?? "";
            $description = $parsed_data["description"] ?? null;
            $assigned_to = isset($parsed_data["assigned_to"]) ? json_decode($parsed_data["assigned_to"], true) : []; // Parse mảng JSON
            $due_date = $parsed_data["due_date"] ?? null;
            // Parse is_completed thành Bool và chuyển thành Int cho database
            $is_completed = isset($parsed_data["is_completed"]) ? filter_var($parsed_data["is_completed"], FILTER_VALIDATE_BOOLEAN) : false;
            $is_completed_int = $is_completed ? 1 : 0; // Chuyển Bool thành 0/1 cho database
            $priority = $parsed_data["priority"] ?? "Medium";
            error_log("DEBUG: Update task params: task_id=$task_id, title=$title, is_completed=$is_completed, assigned_to=" . print_r($assigned_to, true));

            if (!$task_id || !$title) {
                error_log("DEBUG: Missing task_id or title for update_task");
                echo json_encode(["success" => false, "message" => "Thiếu task_id hoặc title"]);
                exit;
            }

            $sql = "SELECT id FROM group_tasks WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $task_id);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                error_log("DEBUG: Task $task_id does not exist");
                echo json_encode(["success" => false, "message" => "Task không tồn tại"]);
                exit;
            }

            // Kiểm tra tất cả user_id trong assigned_to
            if (!empty($assigned_to)) {
                foreach ($assigned_to as $user_id) {
                    $sql = "SELECT id FROM users WHERE id = ?";
                    $stmt = $conn->prepare($sql);
                    $stmt->bind_param("i", $user_id);
                    $stmt->execute();
                    if ($stmt->get_result()->num_rows === 0) {
                        error_log("DEBUG: Assigned user $user_id does not exist");
                        echo json_encode(["success" => false, "message" => "User được giao ($user_id) không tồn tại"]);
                        exit;
                    }
                }
            }

            // Cập nhật task
            $sql = "UPDATE group_tasks SET title = ?, description = ?, due_date = ?, is_completed = ?, priority = ? WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("sssisi", $title, $description, $due_date, $is_completed_int, $priority, $task_id);
            if ($stmt->execute()) {
                // Xóa các bản ghi cũ trong task_assignments
                $sql = "DELETE FROM task_assignments WHERE task_id = ?";
                $stmt = $conn->prepare($sql);
                $stmt->bind_param("i", $task_id);
                $stmt->execute();

                // Thêm các assigned_to mới vào task_assignments
                if (!empty($assigned_to)) {
                    $sql = "INSERT INTO task_assignments (task_id, user_id) VALUES (?, ?)";
                    $stmt = $conn->prepare($sql);
                    foreach ($assigned_to as $user_id) {
                        $stmt->bind_param("ii", $task_id, $user_id);
                        if (!$stmt->execute()) {
                            error_log("DEBUG: Failed to assign user $user_id to task $task_id: " . $conn->error);
                            echo json_encode(["success" => false, "message" => "Thêm người được giao thất bại: " . $conn->error]);
                            exit;
                        }
                    }
                }

                error_log("DEBUG: Updated task $task_id");
                echo json_encode(["success" => true, "message" => "Cập nhật nhiệm vụ thành công"]);
            } else {
                error_log("DEBUG: Failed to update task: " . $conn->error);
                echo json_encode(["success" => false, "message" => "Cập nhật nhiệm vụ thất bại: " . $conn->error]);
            }
        } else {
            error_log("DEBUG: Invalid action for PUT: $action");
            echo json_encode(["success" => false, "message" => "Hành động không hợp lệ"]);
        }
    } elseif ($method === "DELETE") {
        // Parse multipart/form-data cho DELETE
        $content_type = $_SERVER["CONTENT_TYPE"] ?? "";
        $parsed_data = [];
        if (preg_match('/boundary=(.*)$/', $content_type, $matches)) {
            $boundary = $matches[1];
            $parsed_data = parseMultipartFormData($boundary);
        } else {
            error_log("DEBUG: No boundary found in Content-Type for DELETE");
            echo json_encode(["success" => false, "message" => "Không tìm thấy boundary trong Content-Type"]);
            exit;
        }

        // Debug dữ liệu đã parse
        error_log("DEBUG: Parsed DELETE data: " . print_r($parsed_data, true));
        $action = $parsed_data["action"] ?? "";
        error_log("DEBUG: DELETE action=$action");

        if ($action === "delete_group") {
            $group_id = $parsed_data["group_id"] ?? 0;
            $user_id = $parsed_data["user_id"] ?? 0;
            error_log("DEBUG: Delete group params: group_id=$group_id, user_id=$user_id");

            if (!$group_id || !$user_id) {
                error_log("DEBUG: Missing group_id or user_id for delete_group");
                echo json_encode(["success" => false, "message" => "Thiếu group_id hoặc user_id"]);
                exit;
            }

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

            $sql = "SELECT created_by, role FROM groups g JOIN users u ON u.id = ? WHERE g.id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("ii", $user_id, $group_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $group = $result->fetch_assoc();

            if (!$group || ($group['created_by'] != $user_id && $group['role'] !== 'super_admin')) {
                error_log("DEBUG: User $user_id has no permission to delete group $group_id");
                echo json_encode(["success" => false, "message" => "Không có quyền xóa nhóm"]);
                exit;
            }

            $sql = "DELETE FROM groups WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $group_id);
            if ($stmt->execute()) {
                error_log("DEBUG: Deleted group $group_id");
                echo json_encode(["success" => true, "message" => "Xóa nhóm thành công"]);
            } else {
                error_log("DEBUG: Failed to delete group: " . $conn->error);
                echo json_encode(["success" => false, "message" => "Xóa nhóm thất bại: " . $conn->error]);
            }
        } elseif ($action === "remove_member") {
            $group_id = $parsed_data["group_id"] ?? 0;
            $user_id = $parsed_data["user_id"] ?? 0;
            $requesting_user_id = $parsed_data["requesting_user_id"] ?? 0;
            error_log("DEBUG: Remove member params: group_id=$group_id, user_id=$user_id, requesting_user_id=$requesting_user_id");

            if (!$group_id || !$user_id || !$requesting_user_id) {
                error_log("DEBUG: Missing group_id, user_id or requesting_user_id for remove_member");
                echo json_encode(["success" => false, "message" => "Thiếu group_id, user_id hoặc requesting_user_id"]);
                exit;
            }

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
            $sql = "SELECT id FROM users WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $requesting_user_id);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                error_log("DEBUG: Requesting user $requesting_user_id does not exist");
                echo json_encode(["success" => false, "message" => "Requesting user không tồn tại"]);
                exit;
            }

            $sql = "SELECT created_by, role FROM groups g JOIN users u ON u.id = ? WHERE g.id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("ii", $requesting_user_id, $group_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $group = $result->fetch_assoc();

            if (!$group || ($group['created_by'] != $requesting_user_id && $group['role'] !== 'super_admin')) {
                error_log("DEBUG: User $requesting_user_id has no permission to remove member from group $group_id");
                echo json_encode(["success" => false, "message" => "Không có quyền xóa thành viên"]);
                exit;
            }

            $sql = "DELETE FROM group_members WHERE group_id = ? AND user_id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("ii", $group_id, $user_id);
            if ($stmt->execute()) {
                error_log("DEBUG: Removed user $user_id from group $group_id");
                echo json_encode(["success" => true, "message" => "Xóa thành viên thành công"]);
            } else {
                error_log("DEBUG: Failed to remove member: " . $conn->error);
                echo json_encode(["success" => false, "message" => "Xóa thành viên thất bại: " . $conn->error]);
            }
        } elseif ($action === "delete_task") {
            $task_id = $parsed_data["task_id"] ?? 0;
            $user_id = $parsed_data["user_id"] ?? 0;
            error_log("DEBUG: Delete task params: task_id=$task_id, user_id=$user_id");

            if (!$task_id || !$user_id) {
                error_log("DEBUG: Missing task_id or user_id for delete_task");
                echo json_encode(["success" => false, "message" => "Thiếu task_id hoặc user_id"]);
                exit;
            }

            $sql = "SELECT id FROM group_tasks WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $task_id);
            $stmt->execute();
            if ($stmt->get_result()->num_rows === 0) {
                error_log("DEBUG: Task $task_id does not exist");
                echo json_encode(["success" => false, "message" => "Task không tồn tại"]);
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

            $sql = "SELECT g.created_by, u.role 
                    FROM group_tasks t 
                    JOIN group_projects p ON t.project_id = p.id 
                    JOIN groups g ON p.group_id = g.id 
                    JOIN users u ON u.id = ? 
                    WHERE t.id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("ii", $user_id, $task_id);
            $stmt->execute();
            $result = $stmt->get_result();
            $task = $result->fetch_assoc();

            if (!$task || ($task['created_by'] != $user_id && $task['role'] !== 'super_admin')) {
                error_log("DEBUG: User $user_id has no permission to delete task $task_id");
                echo json_encode(["success" => false, "message" => "Không có quyền xóa nhiệm vụ"]);
                exit;
            }

            $sql = "DELETE FROM group_tasks WHERE id = ?";
            $stmt = $conn->prepare($sql);
            $stmt->bind_param("i", $task_id);
            if ($stmt->execute()) {
                error_log("DEBUG: Deleted task $task_id");
                echo json_encode(["success" => true, "message" => "Xóa nhiệm vụ thành công"]);
            } else {
                error_log("DEBUG: Failed to delete task: " . $conn->error);
                echo json_encode(["success" => false, "message" => "Xóa nhiệm vụ thất bại: " . $conn->error]);
            }
        } else {
            error_log("DEBUG: Invalid action for DELETE: $action");
            echo json_encode(["success" => false, "message" => "Hành động không hợp lệ"]);
        }
    }

    $conn->close();
} catch (Exception $e) {
    error_log("DEBUG: Exception in groups.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Lỗi server: " . $e->getMessage()]);
}
?>
