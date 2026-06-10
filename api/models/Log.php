<?php
require_once __DIR__ . '/../config/Database.php';

/**
 * Log Model Class
 */
class Log {
    private $db;
    private $table = 'seens_logs';

    public function __construct() {
        $this->db = Database::getInstance();
    }

    /**
     * Create new log entry
     */
    public function create($studentId, $action, $details = '') {
        $sql = "INSERT INTO {$this->table} (sl_student_id, sl_action, sl_details, sl_timestamp) 
                VALUES (?, ?, ?, NOW())";
        
        try {
            $insertId = $this->db->insert($sql, [$studentId, $action, $details]);
            return $insertId;
        } catch (Exception $e) {
            throw $e;
        }
    }

    /**
     * Get logs by student ID
     */
    public function getByStudentId($studentId, $limit = 50) {
        $sql = "SELECT sl_id as id, sl_student_id as student_id, sl_action as action, 
                       sl_details as details, sl_timestamp as timestamp 
                FROM {$this->table} 
                WHERE sl_student_id = ? 
                ORDER BY sl_timestamp DESC 
                LIMIT ?";
        
        $result = $this->db->query($sql, [$studentId, $limit]);
        $logs = [];

        while ($row = $result->fetch_assoc()) {
            $logs[] = [
                'id' => (int)$row['id'],
                'student_id' => $row['student_id'],
                'action' => $row['action'],
                'details' => $row['details'],
                'timestamp' => $row['timestamp']
            ];
        }

        return $logs;
    }

    /**
     * Get recent logs
     */
    public function getRecent($limit = 100) {
        $sql = "SELECT sl_id as id, sl_student_id as student_id, sl_action as action, 
                       sl_details as details, sl_timestamp as timestamp 
                FROM {$this->table} 
                ORDER BY sl_timestamp DESC 
                LIMIT ?";
        
        $result = $this->db->query($sql, [$limit]);
        $logs = [];

        while ($row = $result->fetch_assoc()) {
            $logs[] = [
                'id' => (int)$row['id'],
                'student_id' => $row['student_id'],
                'action' => $row['action'],
                'details' => $row['details'],
                'timestamp' => $row['timestamp']
            ];
        }

        return $logs;
    }

    /**
     * Get logs by date range
     */
    public function getByDateRange($startDate, $endDate, $limit = 100) {
        $sql = "SELECT sl_id as id, sl_student_id as student_id, sl_action as action, 
                       sl_details as details, sl_timestamp as timestamp 
                FROM {$this->table} 
                WHERE DATE(sl_timestamp) BETWEEN ? AND ? 
                ORDER BY sl_timestamp DESC 
                LIMIT ?";
        
        $result = $this->db->query($sql, [$startDate, $endDate, $limit]);
        $logs = [];

        while ($row = $result->fetch_assoc()) {
            $logs[] = [
                'id' => (int)$row['id'],
                'student_id' => $row['student_id'],
                'action' => $row['action'],
                'details' => $row['details'],
                'timestamp' => $row['timestamp']
            ];
        }

        return $logs;
    }

    /**
     * Get log statistics
     */
    public function getStatistics($startDate = null, $endDate = null) {
        if ($startDate && $endDate) {
            $sql = "SELECT sl_action, COUNT(*) as count 
                    FROM {$this->table} 
                    WHERE DATE(sl_timestamp) BETWEEN ? AND ? 
                    GROUP BY sl_action";
            $result = $this->db->query($sql, [$startDate, $endDate]);
        } else {
            $sql = "SELECT sl_action, COUNT(*) as count 
                    FROM {$this->table} 
                    GROUP BY sl_action";
            $result = $this->db->query($sql);
        }

        $stats = [];
        while ($row = $result->fetch_assoc()) {
            $stats[$row['sl_action']] = (int)$row['count'];
        }

        return $stats;
    }

    /**
     * Get total log count
     */
    public function getCount() {
        $sql = "SELECT COUNT(*) as count FROM {$this->table}";
        $result = $this->db->query($sql);
        $row = $result->fetch_assoc();
        return (int)$row['count'];
    }
}
?>
