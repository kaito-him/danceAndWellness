import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationApiService {
  final ApiClient _apiClient = ApiClient();

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _apiClient.dio.get('/notifications');
      final list = response.data as List<dynamic>;
      return list.map((e) => NotificationModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to load notifications');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await _apiClient.dio.get('/notifications/unread-count');
      return (response.data['count'] ?? 0) as int;
    } on DioException catch (_) {
      return 0;
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _apiClient.dio.patch('/notifications/$id/read');
    } on DioException catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _apiClient.dio.patch('/notifications/read-all');
    } on DioException catch (_) {}
  }
}
