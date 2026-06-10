<?php
/**
 * Simple JWT Implementation for PHP
 * No external dependencies required
 */
class JWT {
    private static $secretKey = 'seens_flutter_secret_key_2024';
    private static $algorithm = 'HS256';
    private static $expiry = 3600; // 1 hour

    /**
     * Generate JWT Token
     */
    public static function encode($payload) {
        $header = json_encode(['typ' => 'JWT', 'alg' => self::$algorithm]);
        $payload = json_encode(array_merge($payload, [
            'iat' => time(),
            'exp' => time() + self::$expiry
        ]));
        
        $headerEncoded = self::base64UrlEncode($header);
        $payloadEncoded = self::base64UrlEncode($payload);
        
        $signature = hash_hmac('sha256', "$headerEncoded.$payloadEncoded", self::$secretKey, true);
        $signatureEncoded = self::base64UrlEncode($signature);
        
        return "$headerEncoded.$payloadEncoded.$signatureEncoded";
    }

    /**
     * Decode and validate JWT Token
     */
    public static function decode($token) {
        if (empty($token)) {
            return null;
        }

        $parts = explode('.', $token);
        if (count($parts) !== 3) {
            return null;
        }

        list($headerEncoded, $payloadEncoded, $signatureEncoded) = $parts;

        // Verify signature
        $signature = hash_hmac('sha256', "$headerEncoded.$payloadEncoded", self::$secretKey, true);
        $expectedSignature = self::base64UrlDecode($signatureEncoded);

        if (!hash_equals($signature, $expectedSignature)) {
            return null;
        }

        // Decode payload
        $payload = json_decode(self::base64UrlDecode($payloadEncoded), true);
        
        // Check expiration
        if (isset($payload['exp']) && $payload['exp'] < time()) {
            return null;
        }

        return $payload;
    }

    /**
     * Validate token from request headers
     */
    public static function validateFromRequest() {
        $headers = getallheaders();
        $authHeader = $headers['Authorization'] ?? $headers['authorization'] ?? '';
        
        if (empty($authHeader) || !preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
            return null;
        }

        $token = $matches[1];
        return self::decode($token);
    }

    /**
     * Send JSON response
     */
    public static function jsonResponse($success, $data = null, $message = '', $statusCode = 200) {
        http_response_code($statusCode);
        header('Content-Type: application/json');
        
        $response = ['success' => $success];
        
        if ($data !== null) {
            $response['data'] = $data;
        }
        
        if (!empty($message)) {
            $response['message'] = $message;
        }
        
        echo json_encode($response);
        exit;
    }

    /**
     * Base64 URL safe encode
     */
    private static function base64UrlEncode($data) {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }

    /**
     * Base64 URL safe decode
     */
    private static function base64UrlDecode($data) {
        return base64_decode(str_pad(strtr($data, '-_', '+/'), strlen($data) % 4, '=', STR_PAD_RIGHT));
    }

    /**
     * Generate random secret key
     */
    public static function generateSecretKey() {
        return bin2hex(random_bytes(32));
    }
}
?>
