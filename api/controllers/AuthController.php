<?php
require_once __DIR__ . '/../middleware/Auth.php';

/**
 * Authentication Controller
 */
class AuthController {
    /**
     * Login endpoint
     * POST /api/auth/login
     */
    public function login() {
        try {
            $input = json_decode(file_get_contents('php://input'), true);
            
            if (!isset($input['username']) || !isset($input['password'])) {
                JWT::jsonResponse(false, null, 'Username and password are required', 400);
            }

            $username = trim($input['username']);
            $password = $input['password'];

            if (empty($username) || empty($password)) {
                JWT::jsonResponse(false, null, 'Username and password cannot be empty', 400);
            }

            // For demo purposes, accept any username with password 'Seait123'
            // In production, implement proper user authentication with database
            $result = Auth::login($username, $password);
            
            if ($result === null) {
                JWT::jsonResponse(false, null, 'Invalid credentials', 401);
            }

            JWT::jsonResponse(true, $result, 'Login successful');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Login failed: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Refresh token endpoint
     * POST /api/auth/refresh
     */
    public function refresh() {
        try {
            $payload = Auth::requireAuth();
            
            // Generate new token with same user data
            $newToken = Auth::generateToken(
                $payload['user_id'], 
                $payload['username'], 
                $payload['role']
            );
            
            JWT::jsonResponse(true, ['token' => $newToken], 'Token refreshed successfully');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Token refresh failed: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Get current user info
     * GET /api/auth/me
     */
    public function me() {
        try {
            $payload = Auth::requireAuth();
            
            $user = [
                'id' => $payload['user_id'],
                'username' => $payload['username'],
                'role' => $payload['role'],
                'iat' => $payload['iat'],
                'exp' => $payload['exp']
            ];
            
            JWT::jsonResponse(true, $user, 'User info retrieved successfully');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Failed to get user info: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Logout endpoint (client-side token removal)
     * POST /api/auth/logout
     */
    public function logout() {
        try {
            Auth::requireAuth();
            
            // In a stateless JWT system, logout is typically handled client-side
            // by removing the token from storage
            JWT::jsonResponse(true, null, 'Logout successful');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Logout failed: ' . $e->getMessage(), 500);
        }
    }

    /**
     * Validate token endpoint
     * GET /api/auth/validate
     */
    public function validate() {
        try {
            $payload = Auth::requireAuth();
            
            JWT::jsonResponse(true, [
                'valid' => true,
                'user_id' => $payload['user_id'],
                'username' => $payload['username'],
                'role' => $payload['role']
            ], 'Token is valid');
        } catch (Exception $e) {
            JWT::jsonResponse(false, null, 'Token validation failed', 401);
        }
    }
}
?>
