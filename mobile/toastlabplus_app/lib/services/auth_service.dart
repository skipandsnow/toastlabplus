import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../config/api_config.dart';

class AuthService extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _memberKey = 'auth_member';

  String? _token;
  Map<String, dynamic>? _member;
  bool _isLoading = false;
  String? _sessionExpiredMessage; // Message to show when session expires

  String? get token => _token;
  Map<String, dynamic>? get member => _member;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _token != null;

  /// Returns the session expired message and clears it (one-time read)
  String? consumeSessionExpiredMessage() {
    final msg = _sessionExpiredMessage;
    _sessionExpiredMessage = null;
    return msg;
  }

  // Initialize - check for existing token and refresh member data
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
    final memberJson = prefs.getString(_memberKey);
    if (memberJson != null) {
      _member = json.decode(memberJson) as Map<String, dynamic>;
    }
    notifyListeners();

    // If logged in, refresh member data from backend to get latest info (e.g., role changes)
    if (_token != null) {
      await _refreshMemberData();
    }
  }

  /// Refresh member data from backend silently
  Future<void> _refreshMemberData() async {
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

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _member = data;

        // Update cached member data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_memberKey, json.encode(data));

        notifyListeners();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Token expired - force logout and notify
        await _handleSessionExpired();
      }
    } catch (e) {
      // Silently fail - use cached data if refresh fails
      debugPrint('Failed to refresh member data: $e');
    }
  }

  /// Handle session expiration - logout and set message
  Future<void> _handleSessionExpired() async {
    _sessionExpiredMessage = '登入已逾期，請重新登入';
    await logout();
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

  /// Upload avatar image to server
  Future<Map<String, dynamic>> uploadAvatar(XFile file) async {
    if (_token == null || _member == null) {
      return {'success': false, 'error': 'Not logged in'};
    }

    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${ApiConfig.mcpServerBaseUrl}/api/members/${_member!['id']}/avatar',
      );
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $_token';

      // Handle both web and mobile platforms
      if (kIsWeb) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            await file.readAsBytes(),
            filename: file.name,
          ),
        );
      } else {
        request.files.add(await http.MultipartFile.fromPath('file', file.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Update local member data with new avatar URL
        final updatedMember = Map<String, dynamic>.from(_member!);
        updatedMember['avatarUrl'] = data['avatarUrl'];
        _member = updatedMember;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_memberKey, json.encode(_member));

        notifyListeners();
        return {'success': true, 'avatarUrl': data['avatarUrl']};
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        return {'success': false, 'error': errorData['error'] ?? response.body};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Change password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    if (_token == null) {
      throw Exception('Not logged in');
    }

    final response = await http
        .post(
          Uri.parse('${ApiConfig.mcpServerBaseUrl}/api/auth/change-password'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
          body: json.encode({
            'currentPassword': currentPassword,
            'newPassword': newPassword,
          }),
        )
        .timeout(ApiConfig.connectionTimeout);

    final data = json.decode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to change password');
    }
  }

  /// Sign in with Google using Firebase Auth
  Future<Map<String, dynamic>> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Trigger Google Sign In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return {'success': false, 'error': 'Google sign in cancelled'};
      }

      // 2. Get Google Auth credentials
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Sign in to Firebase with Google credentials
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential = await firebase_auth
          .FirebaseAuth
          .instance
          .signInWithCredential(credential);

      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return {'success': false, 'error': 'Firebase authentication failed'};
      }

      // 4. Call backend to create/update member and get JWT token
      final response = await http
          .post(
            Uri.parse('${ApiConfig.mcpServerBaseUrl}/api/auth/firebase'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'firebaseUid': firebaseUser.uid,
              'email': firebaseUser.email,
              'name': firebaseUser.displayName ?? 'User',
              'provider': 'GOOGLE',
            }),
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
      debugPrint('Google Sign In Error: $e');
      return {'success': false, 'error': e.toString()};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
