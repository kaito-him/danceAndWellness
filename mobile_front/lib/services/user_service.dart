import 'package:dio/dio.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getMe() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to load profile.');
    }
  }

  Future<Map<String, dynamic>> updateMe({
    required String currentPassword,
    String? username,
    String? email,
    String? newPassword,
  }) async {
    try {
      final payload = <String, dynamic>{
        'currentPassword': currentPassword,
        if (username != null) 'username': username,
        if (email != null) 'email': email,
        if (newPassword != null && newPassword.isNotEmpty) 'newPassword': newPassword,
      };
      final response = await _apiClient.dio.put('/users/me', data: payload);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Failed to update profile.';
      throw Exception(msg);
    }
  }

  Future<String?> uploadPhoto(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _apiClient.dio.post('/files/upload', data: formData);
      return response.data['id'] as String?;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to upload photo.');
    }
  }

  Future<void> updatePhoto(String fileId) async {
    try {
      await _apiClient.dio.patch('/users/me/photo', data: {'photo': fileId});
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to update photo.');
    }
  }

  Future<void> removePhoto() async {
    try {
      await _apiClient.dio.delete('/users/me/photo');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Failed to remove photo.');
    }
  }

  Future<List<int>?> getPhotoBytes(String fileId) async {
    try {
      final response = await _apiClient.dio.get(
        '/files/$fileId',
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>?;
    } on DioException catch (_) {
      return null;
    }
  }
}
