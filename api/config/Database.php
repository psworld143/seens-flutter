<?php
/**
 * Database Configuration and Connection Class
 */
class Database {
    private static $instance = null;
    private $connection;
    
    private $host = 'localhost';
    private $username = 'root';
    private $password = '';
    private $database = 'seait_seens';
    private $socket = null;

    private function __construct() {
        // Detect operating system and set appropriate socket configuration
        if (strtoupper(substr(PHP_OS, 0, 3)) !== 'WIN') {
            // macOS/Linux - use socket for XAMPP
            $this->socket = '/Applications/XAMPP/xamppfiles/var/mysql/mysql.sock';
        }
        
        $this->connect();
    }

    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }

    private function connect() {
        try {
            if ($this->socket) {
                $this->connection = new mysqli($this->host, $this->username, $this->password, $this->database, 3306, $this->socket);
            } else {
                $this->connection = new mysqli($this->host, $this->username, $this->password, $this->database, 3306);
            }

            if ($this->connection->connect_error) {
                throw new Exception("Connection failed: " . $this->connection->connect_error);
            }

            // Set charset to utf8mb4 for full Unicode support
            $this->connection->set_charset("utf8mb4");
            
        } catch (Exception $e) {
            error_log("Database connection error: " . $e->getMessage());
            throw $e;
        }
    }

    public function getConnection() {
        return $this->connection;
    }

    public function query($sql, $params = []) {
        try {
            $stmt = $this->connection->prepare($sql);
            
            if ($stmt === false) {
                throw new Exception("Prepare failed: " . $this->connection->error);
            }

            if (!empty($params)) {
                $types = str_repeat('s', count($params));
                $stmt->bind_param($types, ...$params);
            }

            if (!$stmt->execute()) {
                throw new Exception("Execute failed: " . $stmt->error);
            }

            $result = $stmt->get_result();
            $stmt->close();

            return $result;
        } catch (Exception $e) {
            error_log("Query error: " . $e->getMessage());
            throw $e;
        }
    }

    public function insert($sql, $params = []) {
        try {
            $stmt = $this->connection->prepare($sql);
            
            if ($stmt === false) {
                throw new Exception("Prepare failed: " . $this->connection->error);
            }

            if (!empty($params)) {
                $types = str_repeat('s', count($params));
                $stmt->bind_param($types, ...$params);
            }

            if (!$stmt->execute()) {
                throw new Exception("Execute failed: " . $stmt->error);
            }

            $insertId = $this->connection->insert_id;
            $stmt->close();

            return $insertId;
        } catch (Exception $e) {
            error_log("Insert error: " . $e->getMessage());
            throw $e;
        }
    }

    public function update($sql, $params = []) {
        try {
            $stmt = $this->connection->prepare($sql);
            
            if ($stmt === false) {
                throw new Exception("Prepare failed: " . $this->connection->error);
            }

            if (!empty($params)) {
                $types = str_repeat('s', count($params));
                $stmt->bind_param($types, ...$params);
            }

            if (!$stmt->execute()) {
                throw new Exception("Execute failed: " . $stmt->error);
            }

            $affectedRows = $stmt->affected_rows;
            $stmt->close();

            return $affectedRows;
        } catch (Exception $e) {
            error_log("Update error: " . $e->getMessage());
            throw $e;
        }
    }

    public function delete($sql, $params = []) {
        return $this->update($sql, $params);
    }

    public function beginTransaction() {
        $this->connection->begin_transaction();
    }

    public function commit() {
        $this->connection->commit();
    }

    public function rollback() {
        $this->connection->rollback();
    }

    public function escapeString($string) {
        return $this->connection->real_escape_string($string);
    }

    public function __destruct() {
        if ($this->connection) {
            $this->connection->close();
        }
    }
}
?>
