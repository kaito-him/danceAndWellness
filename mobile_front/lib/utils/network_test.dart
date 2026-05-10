import 'package:dio/dio.dart';

class NetworkTest {
  static Future<void> testConnection() async {
    final dio = Dio();
    
    // Test different URLs
    final urls = [
      'http://10.0.2.2:8080/api/categories',
      'http://localhost:8080/api/categories',
      'http://192.168.1.1:8080/api/categories', // Replace with your IP
    ];
    
    for (final url in urls) {
      try {
        print('🔵 Testing connection to: $url');
        final response = await dio.get(
          url,
          options: Options(
            receiveTimeout: const Duration(seconds: 5),
            sendTimeout: const Duration(seconds: 5),
          ),
        );
        print('🟢 SUCCESS! Status: ${response.statusCode}');
        print('🟢 Response: ${response.data}');
        break;
      } catch (e) {
        print('🔴 FAILED: $e');
      }
    }
  }
}
