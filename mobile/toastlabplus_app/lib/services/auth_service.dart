import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _memberKey = 'auth_member';

  String? _token;
  Map<String, dynamic>? _member;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get member => _member;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  // Initialize - check for existing token
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final memberJson = prefs.getString(_memberKey);
    if (memberJson != null) {
      _member = json.decode(memberJson) as Map<String, dynamic>;
    }
    notifyListeners();
  }

  // Register new platform member
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.mcpServerBaseUrl}${ApiConfig.authRegisterEndpoint}',
            ),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(ApiConfig.connectionTimeout);

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse(
              '${ApiConfig.mcpServerBaseUrl}${ApiConfig.authLoginEndpoint}',
            ),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'email': email, 'password': password}),
          )
          .timeout(ApiConfig.connectionTimeout);

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // Save token and member info
        _token = data['token'] as String;
        _member = data['member'] as Map<String, dynamic>;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, _token!);
        await prefs.setString(_memberKey, json.encode(_member));

        notifyListeners();
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Logout
  Future<void> logout() async {
    _token = null;
    _member = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_memberKey);

    notifyListeners();
  }

  // Get current user info
  Future<Map<String, dynamic>> getCurrentUser() async {
    if (_token == null) {
      return {'success': false, 'error': 'Not logged in'};
    }

    try {
      final response = await http
          .get(
            Uri.parse(
              '${ApiConfig.mcpServerBaseUrl}${ApiConfig.authMeEndpoint}',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_token',
            },
          )
          .timeout(ApiConfig.connectionTimeout);

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        _member = data;
        notifyListeners();
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to get user info',
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Helper to get Authorization header
  Map<String, String> get authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
}
