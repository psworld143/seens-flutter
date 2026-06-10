<?php
require_once __DIR__ . '/../config/Database.php';

/**
 * Student Model Class
 */
class Student {
    private $db;
    private $table = 'seens_student';

    public function __construct() {
        $this->db = Database::getInstance();
    }

    /**
     * Get all students
     */
    public function getAll() {
        $sql = "SELECT ss_id as id, ss_id_no as id_no, ss_photo_location as photo_location, 
                       ss_date_added as date_added 
                FROM {$this->table} 
                ORDER BY ss_date_added DESC";
        
        $result = $this->db->query($sql);
        $students = [];

        while ($row = $result->fetch_assoc()) {
            $students[] = [
                'id' => (int)$row['id'],
                'id_no' => $row['id_no'],
                'photo_location' => $row['photo_location'],
                'date_added' => $row['date_added']
            ];
        }

        return $students;
    }

    /**
     * Get student by ID number
     */
    public function getByIdNo($idNo) {
        $sql = "SELECT ss_id as id, ss_id_no as id_no, ss_photo_location as photo_location, 
                       ss_date_added as date_added 
                FROM {$this->table} 
                WHERE TRIM(ss_id_no) = ?";
        
        $result = $this->db->query($sql, [$idNo]);
        
        if ($result->num_rows === 0) {
            return null;
        }

        $row = $result->fetch_assoc();
        return [
            'id' => (int)$row['id'],
            'id_no' => $row['id_no'],
            'photo_location' => $row['photo_location'],
            'date_added' => $row['date_added']
        ];
    }

    /**
     * Create new student
     */
    public function create($idNo, $photoLocation) {
        $sql = "INSERT INTO {$this->table} (ss_id_no, ss_photo_location, ss_date_added) 
                VALUES (?, ?, NOW())";
        
        try {
            $insertId = $this->db->insert($sql, [$idNo, $photoLocation]);
            return $insertId;
        } catch (Exception $e) {
            if (strpos($e->getMessage(), 'Duplicate entry') !== false) {
                throw new Exception('Student ID already exists');
            }
            throw $e;
        }
    }

    /**
     * Delete student by ID number
     */
    public function deleteByIdNo($idNo) {
        $sql = "DELETE FROM {$this->table} WHERE TRIM(ss_id_no) = ?";
        
        $affectedRows = $this->db->delete($sql, [$idNo]);
        return $affectedRows > 0;
    }

    /**
     * Check if student exists
     */
    public function exists($idNo) {
        $sql = "SELECT COUNT(*) as count FROM {$this->table} WHERE TRIM(ss_id_no) = ?";
        $result = $this->db->query($sql, [$idNo]);
        $row = $result->fetch_assoc();
        return (int)$row['count'] > 0;
    }

    /**
     * Get recent registrations
     */
    public function getRecent($limit = 10) {
        $sql = "SELECT ss_id as id, ss_id_no as id_no, ss_photo_location as photo_location, 
                       ss_date_added as date_added 
                FROM {$this->table} 
                ORDER BY ss_date_added DESC 
                LIMIT ?";
        
        $result = $this->db->query($sql, [$limit]);
        $students = [];

        while ($row = $result->fetch_assoc()) {
            $students[] = [
                'id' => (int)$row['id'],
                'id_no' => $row['id_no'],
                'photo_location' => $row['photo_location'],
                'date_added' => $row['date_added']
            ];
        }

        return $students;
    }

    /**
     * Get student count
     */
    public function getCount() {
        $sql = "SELECT COUNT(*) as count FROM {$this->table}";
        $result = $this->db->query($sql);
        $row = $result->fetch_assoc();
        return (int)$row['count'];
    }
}
?>
