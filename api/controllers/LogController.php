<?php
require_once __DIR__ . '/../middleware/Auth.php';
require_once __DIR__ . '/../models/Log.php';

/**
 * Log Controller
 */
class LogController {
    private $logModel;

    public function __construct() {
        $this->logModel = new Log();
    }

    /**
     * Create new log entry
     * POST /api/logs
     */
    public function create() {
        try {
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($input['qr']) || !isset($input['action'])) {
                JWT::jsonResponse(false, null, 'QR code and action are required', 400);
            }

            $qrCode = trim($input['qr']);
            $action = $input['action'];
            $details = $input['details'] ?? '';

            if (empty($qrCode)) {
                JWT::jsonResponse(false, null, 'QR code cannot be empty', 400);
            }

            if (!in_array($action, ['entry', 'exit', 'scan'])) {
                JWT::jsonResponse(false, null, 'Invalid action. Must be entry, exit, or scan', 400);
            }

            $logId = $this->logModel->create($qrCode, $action, $details);
            
            JWT::jsonResponse(true, ['id' => $logId], 'Log entry created successfully');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Failed to create log entry: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get logs by student ID
     * GET /api/logs/student/{id}
     */
    public function getByStudent($studentId) {
        try {
            if (empty($studentId)) {
                JWT::jsonResponse(false, null, 'Student ID is required', 400);
            }

            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
            $limit = min($limit, 100); // Max 100 records
            
            $logs = $this->logModel->getByStudentId($studentId, $limit);
            
            JWT::jsonResponse(true, $logs, 'Logs retrieved successfully');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Failed to retrieve logs: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get recent logs
     * GET /api/logs/recent
     */
    public function recent() {
        try {
            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;
            $limit = min($limit, 200); // Max 200 records
            
            $logs = $this->logModel->getRecent($limit);
            
            JWT::jsonResponse(true, $logs, 'Recent logs retrieved successfully');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Failed to retrieve recent logs: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get logs by date range
     * GET /api/logs/range
     */
    public function getByDateRange() {
        try {
            $startDate = $_GET['start_date'] ?? null;
            $endDate = $_GET['end_date'] ?? null;
            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 100;

            if (!$startDate || !$endDate) {
                JWT::jsonResponse(false, null, 'Start date and end date are required', 400);
            }

            // Validate date format
            if (!DateTime::createFromFormat('Y-m-d', $startDate) || 
                !DateTime::createFromFormat('Y-m-d', $endDate)) {
                JWT::jsonResponse(false, null, 'Invalid date format. Use Y-m-d', 400);
            }

            $limit = min($limit, 200); // Max 200 records
            
            $logs = $this->logModel->getByDateRange($startDate, $endDate, $limit);
            
            JWT::jsonResponse(true, $logs, 'Logs retrieved successfully');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Failed to retrieve logs: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get log statistics
     * GET /api/logs/stats
     */
    public function stats() {
        try {
            $startDate = $_GET['start_date'] ?? null;
            $endDate = $_GET['end_date'] ?? null;

            if ($startDate && $endDate) {
                // Validate date format
                if (!DateTime::createFromFormat('Y-m-d', $startDate) || 
                    !DateTime::createFromFormat('Y-m-d', $endDate)) {
                    JWT::jsonResponse(false, null, 'Invalid date format. Use Y-m-d', 400);
                }
                
                $stats = $this->logModel->getStatistics($startDate, $endDate);
            } else {
                $stats = $this->logModel->getStatistics();
            }
            
            // Add additional statistics
            $totalLogs = $this->logModel->getCount();
            $stats['total_logs'] = $totalLogs;
            
            JWT::jsonResponse(true, $stats, 'Log statistics retrieved successfully');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Failed to retrieve statistics: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get today's activity
     * GET /api/logs/today
     */
    public function today() {
        try {
            $today = date('Y-m-d');
            $logs = $this->logModel->getByDateRange($today, $today, 50);
            
            // Group by hour for activity chart
            $hourlyActivity = [];
            foreach ($logs as $log) {
                $hour = date('H', strtotime($log['timestamp']));
                if (!isset($hourlyActivity[$hour])) {
                    $hourlyActivity[$hour] = 0;
                }
                $hourlyActivity[$hour]++;
            }
            
            $stats = [
                'date' => $today,
                'total_logs' => count($logs),
                'hourly_activity' => $hourlyActivity,
                'recent_logs' => array_slice($logs, 0, 10)
            ];
            
            JWT::jsonResponse(true, $stats, 'Today\'s activity retrieved successfully');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Failed to retrieve today\'s activity: ' . $e->getMessage(), 500);
        }
    }
}
?>
