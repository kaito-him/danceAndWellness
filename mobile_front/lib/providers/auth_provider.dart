import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_role.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/student_registration_request.dart';
import '../models/instructor_application_request.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  UserRole? _role;
  String? _userId;
  String? _username;
  bool _isLoading = false;
  String? _errorMessage;

  String? get token => _token;
  UserRole? get role => _role;
  String? get userId => _userId;
  String? get username => _username;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;

  // Initialize auth state from secure storage
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      print('🔵 Initializing auth from secure storage...');
      _token = await _storage.read(key: 'jwt_token');
      final roleString = await _storage.read(key: 'user_role');
      _userId = await _storage.read(key: 'user_id');
      _username = await _storage.read(key: 'username');

      if (_token != null) {
        print('🟢 Token found: ${_token!.substring(0, 20)}...');
      } else {
        print('🟡 No token found in storage');
      }

      if (roleString != null) {
        _role = UserRole.fromString(roleString);
        print('🟢 Role found: ${_role?.value}');
      }
    } catch (e) {
      print('🔴 Error initializing auth: $e');
      _token = null;
      _role = null;
      _userId = null;
      _username = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Login
  Future<LoginResponse> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔵 AuthProvider: Starting login for $username');
      final request = LoginRequest(username: username, password: password);
      final response = await _authService.login(request);

      print('🔵 AuthProvider: Login response - success: ${response.success}');

      if (response.success && response.token != null) {
        _token = response.token;
        _role = UserRole.fromString(response.role!);
        _userId = response.userId;
        _username = username;
        _loginError = null;

        print('🟢 AuthProvider: Saving token to secure storage');
        await _storage.write(key: 'jwt_token', value: _token);
        await _storage.write(key: 'user_role', value: response.role);
        await _storage.write(key: 'user_id', value: _userId);
        await _storage.write(key: 'username', value: _username);
        print('🟢 AuthProvider: Token saved successfully');
      } else {
        _errorMessage = response.message;
        // Map the raw message to a user-friendly string
        final msg = response.message.toUpperCase().trim();
        if (msg == 'PENDING') {
          _loginError = 'Your account is waiting for review. We will notify you as soon as we can.';
        } else if (msg == 'INACTIVE') {
          _loginError = 'Your account has been banned. Please contact support.';
        } else if (msg.isEmpty) {
          _loginError = 'Incorrect username or password. Please try again.';
        } else {
          _loginError = response.message;
        }
        print('🔴 AuthProvider: Login failed - ${response.message}');
      }

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      print('🔴 AuthProvider: Exception during login - $e');
      _isLoading = false;
      _errorMessage = e.toString();
      final err = e.toString();
      if (err.contains('connectionTimeout') ||
          err.contains('SocketException') ||
          err.contains('Connection refused') ||
          err.contains('Failed host lookup') ||
          err.contains('Network error')) {
        _loginError = 'Cannot connect to the server. Please check your connection and try again.';
      } else {
        _loginError = 'An internal error occurred. Please try again later.';
      }
      notifyListeners();
      rethrow;
    }
  }

  // Register Student
  Future<String> registerStudent(StudentRegistrationRequest request) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await _authService.registerStudent(request);
      _isLoading = false;
      notifyListeners();
      return message;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Apply as Instructor
  Future<String> applyAsInstructor(
    InstructorApplicationRequest request,
    String certFilePath,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final message = await _authService.applyAsInstructor(request, certFilePath);
      _isLoading = false;
      notifyListeners();
      return message;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Update auth data (e.g., after profile update)
  Future<void> updateAuthData({String? token, String? username}) async {
    if (token != null) {
      _token = token;
      await _storage.write(key: 'jwt_token', value: token);
    }
    if (username != null) {
      _username = username;
      await _storage.write(key: 'username', value: username);
    }
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    _token = null;
    _role = null;
    _userId = null;

    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'username');

    notifyListeners();
  }

  // Login error message — survives router-triggered rebuilds
  String? _loginError;
  String? get loginError => _loginError;

  void clearLoginError() {
    _loginError = null;
    // Don't notifyListeners here — called from onChanged, no rebuild needed
  }
}
