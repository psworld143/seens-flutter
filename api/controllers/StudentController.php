<?php
require_once __DIR__ . '/../middleware/Auth.php';
require_once __DIR__ . '/../models/Student.php';
require_once __DIR__ . '/../models/Log.php';

/**
 * Student Controller
 */
class StudentController {
    private $studentModel;
    private $logModel;

    public function __construct() {
        $this->studentModel = new Student();
        $this->logModel = new Log();
    }

    /**
     * Get all students
     * GET /api/students
     */
    public function index() {
        try {
            $students = $this->studentModel->getAll();
            
            JWT::jsonResponse(true, $students, 'Students retrieved successfully');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Failed to retrieve students: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get student by ID number
     * GET /api/students/check/{id}
     */
    public function check($id) {
        try {
            if (empty($id)) {
                JWT::jsonResponse(false, null, 'Student ID is required', 400);
            }

            $student = $this->studentModel->getByIdNo($id);
            
            if ($student === null) {
                JWT::jsonResponse(false, null, 'Student not found', 404);
            }

            // Return photo location for Flutter app compatibility
            JWT::jsonResponse(true, $student['photo_location'], 'Student found');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Failed to check student: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Create new student
     * POST /api/students
     */
    public function create() {
        try {
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($input['id_no']) || !isset($input['picture'])) {
                JWT::jsonResponse(false, null, 'ID number and picture are required', 400);
            }

            $idNo = trim($input['id_no']);
            $picture = $input['picture'];

            if (empty($idNo)) {
                JWT::jsonResponse(false, null, 'ID number cannot be empty', 400);
            }

            // Check if student already exists
            if ($this->studentModel->exists($idNo)) {
                JWT::jsonResponse(false, null, 'Student with this ID already exists', 409);
            }

            $insertId = $this->studentModel->create($idNo, $picture);
            
            // Log the creation
            $this->logModel->create($idNo, 'student_created', "New student registered with ID: $idNo");

            JWT::jsonResponse(true, ['id' => $insertId], 'Student created successfully');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Failed to create student: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Delete student
     * DELETE /api/students/{id}
     */
    public function delete($id) {
        try {
            if (empty($id)) {
                JWT::jsonResponse(false, null, 'Student ID is required', 400);
            }

            // Check if student exists
            if (!$this->studentModel->exists($id)) {
                JWT::jsonResponse(false, null, 'Student not found', 404);
            }

            $deleted = $this->studentModel->deleteByIdNo($id);
            
            if ($deleted) {
                // Log the deletion
                $this->logModel->create($id, 'student_deleted', "Student deleted with ID: $id");
                JWT::jsonResponse(true, null, 'Student deleted successfully');
            } else {
                JWT::jsonResponse(false, null, 'Failed to delete student', 500);
            }
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Failed to delete student: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get recent registrations
     * GET /api/students/recent
     */
    public function recent() {
        try {
            $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 10;
            $limit = min($limit, 50); // Max 50 records
            
            $students = $this->studentModel->getRecent($limit);
            
            JWT::jsonResponse(true, $students, 'Recent students retrieved successfully');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Failed to retrieve recent students: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get student statistics
     * GET /api/students/stats
     */
    public function stats() {
        try {
            $count = $this->studentModel->getCount();
            
            $stats = [
                'total_students' => $count,
                'recent_registrations' => count($this->studentModel->getRecent(7)),
                'active_today' => $this->getActiveToday()
            ];
            
            JWT::jsonResponse(true, $stats, 'Student statistics retrieved successfully');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Failed to retrieve statistics: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get number of active students today
     */
    private function getActiveToday() {
        try {
            $sql = "SELECT COUNT(DISTINCT sl_student_id) as count 
                    FROM seens_logs 
                    WHERE DATE(sl_timestamp) = CURDATE()";
            
            $db = Database::getInstance();
            $result = $db->query($sql);
            $row = $result->fetch_assoc();
            
            return (int)$row['count'];
        } catch (Exception $e) {
            return 0;
        }
    }
}
?>
