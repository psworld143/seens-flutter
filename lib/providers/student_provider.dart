import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_service.dart';
import '../models/models.dart';
import '../utils/sound_service.dart';
import '../providers/auth_provider.dart';

class StudentProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Student> _students = [];
  bool _isLoading = false;
  String? _error;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStudents(BuildContext context) async {
    _setLoading(true);
    _error = null;

    try {
      // Check if user is authenticated
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.isLoggedIn) {
        // Try JWT endpoints for authenticated users
        final response = await _apiService.getUsers();

        if (response.success && response.data != null) {
          _students = response.data!;
          notifyListeners();
        } else if (response.message != null &&
            response.message!.contains('Authentication expired')) {
          // Clear token and let user login again
          await _apiService.logout();
          _error = 'Authentication expired. Please login again.';
          notifyListeners();
        } else {
          _error = response.message ?? 'Failed to load students';
          notifyListeners();
        }
      } else {
        // Use legacy endpoints for unauthenticated users
        final legacyResponse = await _apiService.getUsersLegacy();
        if (legacyResponse.success && legacyResponse.data != null) {
          _students = legacyResponse.data!;
          notifyListeners();
        } else {
          _error = legacyResponse.message ?? 'Failed to load students';
          notifyListeners();
        }
      }
    } catch (e) {
      // Try legacy endpoints as fallback
      try {
        final legacyResponse = await _apiService.getUsersLegacy();
        if (legacyResponse.success && legacyResponse.data != null) {
          _students = legacyResponse.data!;
          notifyListeners();
        } else {
          _error = legacyResponse.message ?? 'Failed to load students';
          notifyListeners();
        }
      } catch (legacyError) {
        _error = 'Network error: $e';
        notifyListeners();
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<ApiResponse<String>> addStudent({
    required String qrCode,
    required String picture,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.addStudent(
        qrCode: qrCode,
        picture: picture,
      );

      if (response.success) {
        // Don't call loadStudents here since we don't have context
        // The UI will refresh automatically through notifyListeners
      } else {
        _error = response.message;
      }

      notifyListeners();
      return response;
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return ApiResponse<String>(success: false, message: 'Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<ApiResponse<String>> deleteStudent(String idNo) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.deleteStudent(idNo);

      if (response.success) {
        _students.removeWhere((student) => student.idNo == idNo);
        notifyListeners();
      } else {
        _error = response.message;
      }

      notifyListeners();
      return response;
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return ApiResponse<String>(success: false, message: 'Network error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> checkStudentId(
      String qrCode) async {
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.checkStudentId(qrCode);

      if (response.success) {
        await SoundService.instance.playGranted();
      } else {
        await SoundService.instance.playDenied();
        _error = response.message;
        notifyListeners();
      }

      return response;
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      await SoundService.instance.playDenied();
      return ApiResponse<Map<String, dynamic>>(
          success: false, message: 'Network error: $e');
    }
  }

  Future<ApiResponse<String>> saveLogEntry({
    required String idNo,
    required String action,
    required String timestamp,
  }) async {
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.saveLogEntry(
        idNo: idNo,
        action: action,
        timestamp: timestamp,
      );

      if (!response.success) {
        _error = response.message;
        notifyListeners();
      }

      return response;
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return ApiResponse<String>(success: false, message: 'Network error: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
