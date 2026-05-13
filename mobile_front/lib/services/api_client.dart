import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // IMPORTANT: Update this based on your setup!
  //
  // For Android Emulator: http://10.0.2.2:8080/api
  // For Physical Device: http://192.168.1.248:8080/api
  // For iOS Simulator: http://localhost:8080/api
  //
  // To find your computer's IP on Windows:
  // 1. Open Command Prompt
  // 2. Run: ipconfig
  // 3. Look for "IPv4 Address" (e.g., 192.168.1.100)
  // 4. Replace below with: http://192.168.1.100:8080/api
  //
  // MAKE SURE: Your phone and computer are on the SAME WiFi network!

  static const String baseUrl = 'http://192.168.1.120:8080/api';

  /// Helper to convert backend paths (like /api/files/...) to full URLs
  static String formatMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;

    // Get the base without /api
    final base = baseUrl.replaceFirst('/api', '');
    return '$base$path';
  }

  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Add interceptor to attach JWT token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle errors globally if needed
          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<String> uploadFile(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post('/files/upload', data: formData);
      return response.data['id'] as String;
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }
}
