<?php
require_once __DIR__ . '/../vendor/JWT.php';

/**
 * Authentication Middleware
 */
class Auth {
    /**
     * Require JWT authentication
     */
    public static function requireAuth() {
        $payload = JWT::validateFromRequest();
        
        if ($payload === null) {
            JWT::jsonResponse(false, null, 'Unauthorized - Invalid or missing token', 401);
        }

        return $payload;
    }

    /**
     * Generate JWT token for user
     */
    public static function generateToken($userId, $username, $role = 'user') {
        $payload = [
            'user_id' => $userId,
            'username' => $username,
            'role' => $role
        ];

        return JWT::encode($payload);
    }

    /**
     * Validate admin role
     */
    public static function requireAdmin() {
        $payload = self::requireAuth();
        
        if (!isset($payload['role']) || $payload['role'] !== 'admin') {
            JWT::jsonResponse(false, null, 'Forbidden - Admin access required', 403);
        }

        return $payload;
    }

    /**
     * Get current user from token
     */
    public static function getCurrentUser() {
        return self::requireAuth();
    }

    /**
     * Check if user has specific role
     */
    public static function hasRole($requiredRole) {
        $payload = self::requireAuth();
        
        return isset($payload['role']) && $payload['role'] === $requiredRole;
    }

    /**
     * Simple login for demo purposes (replace with proper user authentication)
     */
    public static function login($username, $password) {
        // For demo purposes, accept any username with password 'admin123'
        // In production, implement proper user authentication with database
        
        if ($password === 'Seait123') {
            $userId = 1;
            $role = 'admin';
            
            $token = self::generateToken($userId, $username, $role);
            
            return [
                'token' => $token,
                'user' => [
                    'id' => $userId,
                    'username' => $username,
                    'role' => $role
                ]
            ];
        }

        return null;
    }
}
?>
