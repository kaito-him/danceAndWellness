import 'package:dio/dio.dart';
import '../models/course.dart';
import 'api_client.dart';

class CourseService {
  final ApiClient _apiClient = ApiClient();

  /// GET /api/courses/published
  Future<List<Course>> getPublishedCourses() async {
    try {
      final response = await _apiClient.dio.get('/courses/published');
      final list = response.data as List<dynamic>;
      return list.map((e) => Course.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load published courses');
    }
  }

  /// GET /api/courses/admin-archived
  Future<List<Course>> getAdminArchivedCourses() async {
    try {
      final response = await _apiClient.dio.get('/courses/admin-archived');
      final list = response.data as List<dynamic>;
      return list.map((e) => Course.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load archived courses');
    }
  }

  /// PATCH /api/courses/{id}/archive
  /// Requires { "message": "Reason..." }
  Future<void> archiveCourse(String courseId, String reason) async {
    try {
      await _apiClient.dio.patch(
        '/courses/$courseId/archive',
        data: {'message': reason},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to archive course');
    }
  }

  /// PATCH /api/courses/{id}/unarchive-admin
  Future<void> unarchiveCourse(String courseId) async {
    try {
      await _apiClient.dio.patch('/courses/$courseId/unarchive-admin');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to unarchive course');
    }
  }

  /// GET /api/courses/{id}
  Future<Course> getCourseById(String id) async {
    try {
      final response = await _apiClient.dio.get('/courses/$id');
      return Course.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load course details');
    }
  }

  /// GET /api/courses/{id}/enrollments/count
  Future<int> getEnrollmentCount(String courseId) async {
    try {
      final response = await _apiClient.dio.get('/courses/$courseId/enrollments/count');
      return (response.data as num).toInt();
    } on DioException catch (_) {
      return 0;
    }
  }

  /// GET /api/categories/{id}  — returns category name
  Future<String> getCategoryName(String categoryId) async {
    try {
      final response = await _apiClient.dio.get('/categories/$categoryId');
      return response.data['name'] as String? ?? '';
    } on DioException catch (_) {
      return '';
    }
  }
}
