import 'package:dio/dio.dart';
import 'dart:convert';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/student_registration_request.dart';
import '../models/instructor_application_request.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      print('🔵 Attempting login for user: ${request.username}');
      print('🔵 API URL: ${_apiClient.dio.options.baseUrl}/auth/login');
      
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: request.toJson(),
      );

      print('🟢 Login response status: ${response.statusCode}');
      print('🟢 Login response data: ${response.data}');
      
      return LoginResponse.fromJson(response.data);
    } on DioException catch (e) {
      print('🔴 DioException during login: ${e.type}');
      print('🔴 Error message: ${e.message}');
      print('🔴 Response: ${e.response?.data}');
      
      if (e.response != null) {
        // data can be a Map (JSON) or a String (plain text) — fromJson handles both
        return LoginResponse.fromJson(e.response!.data);
      }
      // Pure network failure — return a failure response instead of throwing
      return LoginResponse(
        success: false,
        message: 'Network error: ${e.message ?? e.type.name}',
      );
    } catch (e) {
      print('🔴 Unexpected error during login: $e');
      rethrow;
    }
  }

  Future<String> registerStudent(StudentRegistrationRequest request) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register/student',
        data: request.toJson(),
      );

      // Backend returns plain text message
      return response.data.toString();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data.toString());
      }
      throw Exception('Network error: ${e.message}');
    }
  }

  // ── Availability Checks ──────────────────────────────────────────────────

  /// Returns true if the username is available (not taken).
  Future<bool> checkUsernameAvailable(String username) async {
    try {
      final response = await _apiClient.dio.get(
        '/auth/check-username',
        queryParameters: {'username': username},
      );
      return response.data['available'] == true;
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? 'Could not check username.';
      throw Exception(msg);
    }
  }

  /// Returns true if the email is available (not taken).
  Future<bool> checkEmailAvailable(String email) async {
    try {
      final response = await _apiClient.dio.get(
        '/auth/check-email',
        queryParameters: {'email': email},
      );
      return response.data['available'] == true;
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? 'Could not check email.';
      throw Exception(msg);
    }
  }

  // ── Forgot Password ──────────────────────────────────────────────────────

  Future<void> requestPasswordReset(String usernameOrEmail) async {
    try {
      await _apiClient.dio.post(
        '/auth/forgot-password/request',
        data: {'usernameOrEmail': usernameOrEmail},
      );
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? 'Failed to send reset code.';
      throw Exception(msg);
    }
  }

  /// Returns the userId needed for the reset step.
  Future<String> verifyResetCode(String usernameOrEmail, String code) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/forgot-password/verify',
        data: {'usernameOrEmail': usernameOrEmail, 'code': code},
      );
      final data = response.data;
      if (data is Map && data['userId'] != null) {
        return data['userId'].toString();
      }
      throw Exception('Unexpected response from server.');
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? 'Verification failed.';
      throw Exception(msg);
    }
  }

  Future<void> resetPassword(
    String userId,
    String newPassword,
    String confirmPassword,
  ) async {
    try {
      await _apiClient.dio.post(
        '/auth/forgot-password/reset',
        data: {
          'userId': userId,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
    } on DioException catch (e) {
      final msg = e.response?.data?.toString() ?? 'Password reset failed.';
      throw Exception(msg);
    }
  }

  Future<String> applyAsInstructor(
    InstructorApplicationRequest request,
    String certFilePath,
  ) async {
    try {
      // The backend uses @RequestPart("data") which requires the JSON part
      // to carry application/json content-type so Spring can deserialize it.
      final formData = FormData.fromMap({
        'data': MultipartFile.fromString(
          jsonEncode(request.toJson()),
          contentType: DioMediaType('application', 'json'),
        ),
        'certFile': await MultipartFile.fromFile(
          certFilePath,
          filename: certFilePath.split('/').last,
        ),
      });

      final response = await _apiClient.dio.post(
        '/auth/register/instructor',
        data: formData,
      );

      return response.data.toString();
    } on DioException catch (e) {
      // Always surface a readable message — never an empty string
      String msg;
      if (e.response?.data != null) {
        final body = e.response!.data;
        msg = (body is String && body.trim().isNotEmpty)
            ? body.trim()
            : 'Server error (${e.response!.statusCode})';
      } else {
        msg = 'Network error: ${e.message ?? e.type.name}';
      }
      throw Exception(msg);
    }
  }
}
