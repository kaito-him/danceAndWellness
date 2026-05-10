import 'package:dio/dio.dart';
import '../models/overall_stats.dart';
import 'api_client.dart';

class AdminDashboardService {
  final ApiClient _apiClient = ApiClient();

  /// GET /api/statistics/overall
  Future<OverallStats> getOverallStats() async {
    try {
      final response = await _apiClient.dio.get('/statistics/overall');
      return OverallStats.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to load stats');
    }
  }

  /// GET /api/admin/applications
  Future<List<PendingInstructor>> getPendingApplications() async {
    try {
      final response = await _apiClient.dio.get('/admin/applications');
      final list = response.data as List<dynamic>;
      return list.map((e) => PendingInstructor.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to load applications');
    }
  }

  /// PATCH /api/admin/applications/{userId}/approve
  Future<void> approveApplication(String userId) async {
    try {
      await _apiClient.dio.patch('/admin/applications/$userId/approve');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to approve application');
    }
  }

  /// PATCH /api/admin/applications/{userId}/decline
  Future<void> declineApplication(String userId) async {
    try {
      await _apiClient.dio.patch('/admin/applications/$userId/decline');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to decline application');
    }
  }

  /// GET /api/courses/pending
  Future<List<Map<String, dynamic>>> getPendingCourses() async {
    try {
      final response = await _apiClient.dio.get('/courses/pending');
      final list = response.data as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to load pending courses');
    }
  }

  /// PATCH /api/courses/{courseId}/approve  (admin approves a pending course)
  Future<void> approveCourse(String courseId) async {
    try {
      await _apiClient.dio.patch('/courses/$courseId/approve');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to approve course');
    }
  }
}
