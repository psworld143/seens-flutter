import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import '../models/models.dart';

class ApiService {
  static const String baseUrl = 'http://localhost/seens';
  static const String token = 'Seait123';
  final Logger _logger = Logger();

  Future<http.Response> _postRequest(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    _logger.i('POST Request: $url');
    _logger.d('Data: $data');

    try {
      final response = await http.post(
        url,
        body: data,
      ).timeout(const Duration(seconds: 30));

      _logger.i('Response Status: ${response.statusCode}');
      _logger.d('Response Body: ${response.body}');
      
      return response;
    } catch (e) {
      _logger.e('Request failed: $e');
      rethrow;
    }
  }

  Future<http.Response> _getRequest(String endpoint) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    _logger.i('GET Request: $url');

    try {
      final response = await http.get(
        url,
      ).timeout(const Duration(seconds: 30));

      _logger.i('Response Status: ${response.statusCode}');
      _logger.d('Response Body: ${response.body}');
      
      return response;
    } catch (e) {
      _logger.e('Request failed: $e');
      rethrow;
    }
  }

  Future<ApiResponse<List<Student>>> getUsers() async {
    try {
      final response = await _getRequest('backend_scripts/get_users.php');
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == 1) {
          final List<dynamic> usersData = jsonData['data'];
          final List<Student> users = usersData.map((user) => Student.fromJson(user)).toList();
          
          return ApiResponse<List<Student>>(
            success: true,
            data: users,
          );
        } else {
          return ApiResponse<List<Student>>(
            success: false,
            message: jsonData['message'] ?? 'Unknown error',
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

  Future<ApiResponse<String>> checkId(String qrCode) async {
    try {
      final response = await _postRequest('backend_scripts/check_id.php', {
        'token': token,
        'qr': qrCode,
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['message'] != 0 && jsonData['message'] != null) {
          return ApiResponse<String>(
            success: true,
            data: jsonData['message'],
          );
        } else {
          return ApiResponse<String>(
            success: false,
            message: 'Student not found',
          );
        }
      } else {
        return ApiResponse<String>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Check ID failed: $e');
      return ApiResponse<String>(
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
      final response = await _postRequest('backend_scripts/add_user.php', {
        'token': token,
        'qr': qrCode,
        'picture': picture,
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ApiResponse<String>(
          success: jsonData['message']?.contains('successfully') ?? false,
          message: jsonData['message'] ?? 'Unknown response',
        );
      } else {
        return ApiResponse<String>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Add student failed: $e');
      return ApiResponse<String>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  Future<ApiResponse<String>> saveLogs({
    required String qrCode,
    required String action,
    String? details,
  }) async {
    try {
      final response = await _postRequest('backend_scripts/save_logs.php', {
        'token': token,
        'qr': qrCode,
        'action': action,
        'details': details ?? '',
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ApiResponse<String>(
          success: true,
          message: jsonData['message'] ?? 'Logs saved successfully',
        );
      } else {
        return ApiResponse<String>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Save logs failed: $e');
      return ApiResponse<String>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  Future<ApiResponse<String>> deleteStudent(String idNo) async {
    try {
      final response = await _postRequest('backend_scripts/delete_user.php', {
        'token': token,
        'id_no': idNo,
      });

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ApiResponse<String>(
          success: jsonData['message']?.contains('successfully') ?? false,
          message: jsonData['message'] ?? 'Unknown response',
        );
      } else {
        return ApiResponse<String>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      _logger.e('Delete student failed: $e');
      return ApiResponse<String>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}
