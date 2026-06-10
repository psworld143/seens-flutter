<?php
/**
 * API Router - Main Entry Point
 */

// Enhanced CORS for Flutter web development
$allowedOrigins = [
    'http://localhost:3000',
    'http://localhost:8080', 
    'http://127.0.0.1:3000',
    'http://127.0.0.1:8080',
    'http://localhost',
    'http://127.0.0.1',
    '*'
];

$origin = $_SERVER['HTTP_ORIGIN'] ?? '*';
if (in_array($origin, $allowedOrigins) || in_array('*', $allowedOrigins)) {
    header("Access-Control-Allow-Origin: $origin");
}

header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Accept, Origin");
header("Access-Control-Allow-Credentials: true");
header("Access-Control-Max-Age: 3600");

// Handle preflight requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Set content type for all responses
header("Content-Type: application/json");

// Get request method and path
$method = $_SERVER['REQUEST_METHOD'];
$requestUri = $_SERVER['REQUEST_URI'];
$path = parse_url($requestUri, PHP_URL_PATH);

// Extract only the part after /api/
$apiPath = str_replace('/seens_flutter/api/index.php', '', $path);
$apiPath = trim($apiPath, '/');

// Split path into segments
$segments = $apiPath === '' ? [] : explode('/', $apiPath);

// Remove index.php if it's the first segment
if (!empty($segments) && $segments[0] === 'index.php') {
    array_shift($segments);
}

// Route the request
try {
    switch ($segments[0] ?? '') {
        case 'auth':
            require_once 'controllers/AuthController.php';
            $controller = new AuthController();
            
            switch ($segments[1] ?? '') {
                case 'login':
                    if ($method === 'POST') $controller->login();
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                case 'refresh':
                    if ($method === 'POST') $controller->refresh();
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                case 'me':
                    if ($method === 'GET') $controller->me();
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                case 'logout':
                    if ($method === 'POST') $controller->logout();
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                case 'validate':
                    if ($method === 'GET') $controller->validate();
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                default:
                    JWT::jsonResponse(false, null, 'Auth endpoint not found', 404);
            }
            break;

        case 'students':
            require_once 'controllers/StudentController.php';
            $controller = new StudentController();
            
            switch ($segments[1] ?? '') {
                case '':
                    if ($method === 'GET') $controller->index();
                    elseif ($method === 'POST') $controller->create();
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                case 'check':
                    if ($method === 'GET') $controller->check($segments[2] ?? '');
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                case 'recent':
                    if ($method === 'GET') $controller->recent();
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                case 'stats':
                    if ($method === 'GET') $controller->stats();
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                default:
                    // Handle /students/{id} for DELETE
                    if ($method === 'DELETE' && !empty($segments[1])) {
                        $controller->delete($segments[1]);
                    } else {
                        JWT::jsonResponse(false, null, 'Student endpoint not found', 404);
                    }
            }
            break;

        case 'logs':
            require_once 'controllers/LogController.php';
            $controller = new LogController();
            
            switch ($segments[1] ?? '') {
                case '':
                    if ($method === 'POST') $controller->create();
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                case 'student':
                    if ($method === 'GET') $controller->getByStudent($segments[2] ?? '');
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                case 'recent':
                    if ($method === 'GET') $controller->recent();
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                case 'range':
                    if ($method === 'GET') $controller->getByDateRange();
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                case 'stats':
                    if ($method === 'GET') $controller->stats();
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                case 'today':
                    if ($method === 'GET') $controller->today();
                    else JWT::jsonResponse(false, null, 'Method not allowed', 405);
                    break;
                    
                default:
                    JWT::jsonResponse(false, null, 'Log endpoint not found', 404);
            }
            break;

        default:
            // Legacy endpoints for backward compatibility
            require_once 'vendor/JWT.php';
            
            switch ($segments[0] ?? '') {
                case 'get_users.php':
                    require_once 'controllers/StudentController.php';
                    $studentController = new StudentController();
                    $studentController->index();
                    break;
                    
                case 'check_id.php':
                    require_once 'controllers/StudentController.php';
                    $studentController = new StudentController();
                    $input = json_decode(file_get_contents('php://input'), true);
                    $qrCode = $input['qr'] ?? '';
                    $studentController->check($qrCode);
                    break;
                    
                case 'add_user.php':
                    require_once 'controllers/StudentController.php';
                    $studentController = new StudentController();
                    $studentController->create();
                    break;
                    
                case 'delete_user.php':
                    require_once 'controllers/StudentController.php';
                    $studentController = new StudentController();
                    $input = json_decode(file_get_contents('php://input'), true);
                    $idNo = $input['id_no'] ?? '';
                    $studentController->delete($idNo);
                    break;
                    
                case 'save_logs.php':
                    require_once 'controllers/LogController.php';
                    $logController = new LogController();
                    $logController->create();
                    break;
                    
                default:
                    JWT::jsonResponse(false, null, 'Endpoint not found', 404);
            }
    }
} catch (Exception $e) {
    error_log("API Error: " . $e->getMessage());
    JWT::jsonResponse(false, null, 'Internal server error', 500);
}
?>
