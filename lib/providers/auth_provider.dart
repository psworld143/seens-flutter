import 'package:flutter/foundation.dart';
import '../api/api_service.dart';
import '../models/models.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  AuthProvider({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  // Getters
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _user?['role'] == 'admin';

  // Initialize by checking for existing token
  Future<void> initialize() async {
    final isValid = await _apiService.isTokenValid();
    if (isValid) {
      _isLoggedIn = true;
      notifyListeners();
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> login(String username, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final response = await _apiService.login(username, password);

      if (response.success && response.data != null) {
        _token = response.data!['token'];
        _user = response.data!['user'];
        _isLoggedIn = true;
        notifyListeners();
      } else {
        _error = response.message ?? 'Login failed';
        notifyListeners();
      }

      return response;
    } catch (e) {
      _error = 'Network error: $e';
      notifyListeners();
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        message: 'Network error: $e',
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      // Continue with logout even if API call fails
      if (kDebugMode) {
        print('Logout API call failed: $e');
      }
    }

    _token = null;
    _user = null;
    _isLoggedIn = false;
    _error = null;
    notifyListeners();
  }

  Future<bool> refreshToken() async {
    if (_token == null) return false;

    try {
      final response = await _apiService.login(_user!['username'], 'Seait123');
      
      if (response.success && response.data != null) {
        _token = response.data!['token'];
        _user = response.data!['user'];
        notifyListeners();
        return true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Token refresh failed: $e');
      }
    }

    // If refresh fails, logout
    await logout();
    return false;
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
