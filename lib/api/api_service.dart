import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost/seens_flutter/api/index.php';
  static const String legacyBaseUrl = 'http://localhost/seens_flutter/api';

  // Fallback URLs for web connectivity issues
  static const List<String> fallbackUrls = [
    'http://localhost/seens_flutter/api/index.php',
    'http://127.0.0.1/seens_flutter/api/index.php',
  ];

  final Logger _logger = Logger();

  // Get base URL based on platform
  List<String> get _urls {
    if (kIsWeb) {
      // For web, try absolute URLs first for development server
      return [
        'http://localhost/seens_flutter/api/index.php',
        'http://127.0.0.1/seens_flutter/api/index.php',
        '/seens_flutter/api/index.php', // Fallback for same-domain deployment
      ];
    }
    return fallbackUrls;
  }

  // JWT Token management
  String? _jwtToken;
  static const String _tokenKey = 'jwt_token';

  Future<String?> _getToken() async {
    if (_jwtToken == null) {
      final prefs = await SharedPreferences.getInstance();
      _jwtToken = prefs.getString(_tokenKey);
    }
    return _jwtToken;
  }

  Future<void> _setToken(String? token) async {
    _jwtToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString(_tokenKey, token);
    } else {
      await prefs.remove(_tokenKey);
    }
  }

  Future<void> _clearToken() async {
    await _setToken(null);
  }

  Future<Map<String, String>> _getHeaders({bool useLegacy = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (!useLegacy) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<http.Response> _postRequest(String endpoint, Map<String, dynamic> data,
      {bool useLegacy = false}) async {
    // Try primary URL first, then fallback URLs
    final urls = useLegacy ? [legacyBaseUrl] : _urls;

    for (String urlBase in urls) {
      final url = Uri.parse('$urlBase/$endpoint');
      final headers = await _getHeaders(useLegacy: useLegacy);

      _logger.i('POST Request: $url');
      _logger.d('Headers: $headers');
      _logger.d('Data: $data');

      try {
        final response = await http
            .post(
              url,
              headers: headers,
              body: useLegacy ? data : json.encode(data),
            )
            .timeout(const Duration(seconds: 30));

        _logger.i('Response Status: ${response.statusCode}');
        _logger.d('Response Body: ${response.body}');

        return response;
      } catch (e) {
        _logger.e('Request failed for $urlBase: $e');
        _logger.e('Error type: ${e.runtimeType}');

        if (e.toString().contains('Failed to fetch')) {
          _logger.e('This is likely a CORS or network connectivity issue');
        }

        if (urlBase == urls.last) {
          // Last URL failed, rethrow the exception
          _logger.e('All URLs failed');
          rethrow;
        }
        // Continue to next URL
        continue;
      }
    }

    throw Exception('No URLs available');
  }

  Future<http.Response> _getRequest(String endpoint,
      {bool useLegacy = false}) async {
    // Try primary URL first, then fallback URLs
    final urls = useLegacy ? [legacyBaseUrl] : _urls;

    for (String urlBase in urls) {
      final url = Uri.parse('$urlBase/$endpoint');
      final headers = await _getHeaders(useLegacy: useLegacy);

      _logger.i('GET Request: $url');
      _logger.d('Headers: $headers');

      try {
        final response = await http
            .get(url, headers: headers)
            .timeout(const Duration(seconds: 30));

        _logger.i('Response Status: ${response.statusCode}');
        _logger.d('Response Body: ${response.body}');

        return response;
      } catch (e) {
        _logger.e('Request failed for $urlBase: $e');

        if (urlBase == urls.last) {
          // Last URL failed, rethrow the exception
          _logger.e('All URLs failed');
          rethrow;
        }
        // Continue to next URL
        continue;
      }
    }

    throw Exception('No URLs available');
  }

  Future<http.Response> _deleteRequest(String endpoint,
      {bool useLegacy = false}) async {
    final url = Uri.parse('${useLegacy ? legacyBaseUrl : baseUrl}/$endpoint');
    final headers = await _getHeaders(useLegacy: useLegacy);

    _logger.i('DELETE Request: $url');
    _logger.d('Headers: $headers');

    try {
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 30));

      _logger.i('Response Status: ${response.statusCode}');
      _logger.d('Response Body: ${response.body}');

      return response;
    } catch (e) {
      _logger.e('Request failed: $e');
      rethrow;
    }
  }

  // Authentication methods
  Future<ApiResponse<Map<String, dynamic>>> login(
      String username, String password) async {
    try {
      final response = await _postRequest('auth/login', {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          final token = jsonData['data']['token'];
          await _setToken(token);

          return ApiResponse<Map<String, dynamic>>(
            success: true,
            data: jsonData['data'],
            message: jsonData['message'],
          );
        } else {
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: jsonData['message'] ?? 'Login failed',
          );
        }
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Login failed: $e');
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  Future<void> logout() async {
    await _clearToken();
  }

  Future<bool> isTokenValid() async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await _getRequest('auth/validate');
      return response.statusCode == 200;
    } catch (e) {
      _logger.e('Token validation failed: $e');
      return false;
    }
  }

  // Student methods (using new JWT endpoints)
  Future<ApiResponse<List<Student>>> getUsers() async {
    try {
      final response = await _getRequest('students');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          final studentsList = jsonData['data'] as List;
          final students =
              studentsList.map((json) => Student.fromJson(json)).toList();

          return ApiResponse<List<Student>>(
            success: true,
            data: students,
            message: jsonData['message'],
          );
        } else {
          return ApiResponse<List<Student>>(
            success: false,
            message: jsonData['message'] ?? 'Failed to get users',
          );
        }
      } else {
        return ApiResponse<List<Student>>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Get users failed: $e');
      await _clearToken();
      return ApiResponse<List<Student>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> checkStudentId(
      String qrCode) async {
    try {
      final response = await _getRequest('students/check/$qrCode');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          return ApiResponse<Map<String, dynamic>>(
            success: true,
            data: jsonData['data'],
            message: jsonData['message'],
          );
        } else {
          return ApiResponse<Map<String, dynamic>>(
            success: false,
            message: jsonData['message'] ?? 'Student not found',
          );
        }
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Check student ID failed: $e');
      await _clearToken();
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  Future<ApiResponse<String>> addStudent({
    required String qrCode,
    required String picture,
  }) async {
    try {
      final response = await _postRequest('students', {
        'qr_code': qrCode,
        'picture': picture,
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          return ApiResponse<String>(
            success: true,
            data: jsonData['message'],
            message: jsonData['message'],
          );
        } else {
          return ApiResponse<String>(
            success: false,
            message: jsonData['message'] ?? 'Failed to add student',
          );
        }
      } else {
        return ApiResponse<String>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Add student failed: $e');
      await _clearToken();
      return ApiResponse<String>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  Future<ApiResponse<String>> deleteStudent(String idNo) async {
    try {
      final response = await _deleteRequest('students/$idNo');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          return ApiResponse<String>(
            success: true,
            data: jsonData['message'],
            message: jsonData['message'],
          );
        } else {
          return ApiResponse<String>(
            success: false,
            message: jsonData['message'] ?? 'Failed to delete student',
          );
        }
      } else {
        return ApiResponse<String>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Delete student failed: $e');
      await _clearToken();
      return ApiResponse<String>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  Future<ApiResponse<String>> saveLogEntry({
    required String idNo,
    required String action,
    required String timestamp,
  }) async {
    try {
      final response = await _postRequest('logs', {
        'id_no': idNo,
        'action': action,
        'timestamp': timestamp,
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          return ApiResponse<String>(
            success: true,
            data: jsonData['message'],
            message: jsonData['message'],
          );
        } else {
          return ApiResponse<String>(
            success: false,
            message: jsonData['message'] ?? 'Failed to save log entry',
          );
        }
      } else {
        return ApiResponse<String>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Save log entry failed: $e');
      await _clearToken();
      return ApiResponse<String>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // Legacy methods (for backward compatibility)
  Future<ApiResponse<List<Student>>> getUsersLegacy() async {
    try {
      final response = await _getRequest('get_users.php', useLegacy: true);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true) {
          final studentsList = jsonData['data'] as List;
          final students =
              studentsList.map((json) => Student.fromJson(json)).toList();

          return ApiResponse<List<Student>>(
            success: true,
            data: students,
            message: jsonData['message'],
          );
        } else {
          return ApiResponse<List<Student>>(
            success: false,
            message: jsonData['message'] ?? 'Failed to get users',
          );
        }
      } else {
        return ApiResponse<List<Student>>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Get users failed: $e');
      return ApiResponse<List<Student>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}
