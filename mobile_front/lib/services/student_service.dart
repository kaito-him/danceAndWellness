import 'package:dio/dio.dart';
import '../models/course.dart';
import 'api_client.dart';

class StudentService {
  final ApiClient _apiClient = ApiClient();

  /// GET /api/students/stats/{userId}
  Future<Map<String, dynamic>> getStudentStats(String userId) async {
    try {
      final response =
          await _apiClient.dio.get('/students/stats/$userId');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load stats');
    }
  }

  /// GET /api/students/{id}/courses
  Future<List<Course>> getStudentCourses(String studentId) async {
    try {
      final response =
          await _apiClient.dio.get('/students/$studentId/courses');
      final list = response.data as List<dynamic>;
      return list.map((e) => Course.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to load courses');
    }
  }

  /// GET /api/users/me
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to load profile');
    }
  }

  /// GET /api/badges/my-status
  Future<List<Map<String, dynamic>>> getMyBadgeStatus() async {
    try {
      final response = await _apiClient.dio.get('/badges/my-status');
      final list = response.data as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e)).toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to load badges');
    }
  }

  /// GET /api/recommendations/student/{studentId}
  Future<List<Course>> getRecommendations(String studentId, {int topN = 10}) async {
    try {
      final response = await _apiClient.dio.get(
        '/recommendations/student/$studentId',
        queryParameters: {'topN': topN},
      );
      final list = response.data as List<dynamic>;
      return list.map((e) {
        return Course(
          courseId: (e['course_id'] ?? e['courseId'] ?? '').toString(),
          title: e['title'] ?? '',
          isFree: e['is_free'] ?? e['isFree'] ?? false,
          price: (e['price'] as num?)?.toDouble(),
          level: e['level'],
          categoryId: e['category'],
          lessonCount: e['lesson_count'] ?? e['lessonCount'] ?? 0,
        );
      }).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load recommendations');
    }
  }
}

