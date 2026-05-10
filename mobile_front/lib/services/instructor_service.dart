import 'package:dio/dio.dart';
import '../models/course.dart';
import '../models/instructor_profile.dart';
import 'api_client.dart';

class InstructorDashboardService {
  final ApiClient _apiClient = ApiClient();

  /// GET /api/instructors/by-user/{userId}
  Future<InstructorProfile> getProfileByUserId(String userId) async {
    try {
      final response =
          await _apiClient.dio.get('/instructors/by-user/$userId');
      return InstructorProfile.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to load profile');
    }
  }

  /// GET /api/courses/my-published
  Future<List<Course>> getPublishedCourses() async {
    try {
      final response = await _apiClient.dio.get('/courses/my-published');
      final list = response.data as List<dynamic>;
      return list.map((e) => Course.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to load courses');
    }
  }

  /// GET /api/courses/my-drafts
  Future<List<Course>> getDraftCourses() async {
    try {
      final response = await _apiClient.dio.get('/courses/my-drafts');
      final list = response.data as List<dynamic>;
      return list.map((e) => Course.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to load drafts');
    }
  }

  /// GET /api/courses/{courseId}/enrollments/count
  Future<int> getEnrollmentCount(String courseId) async {
    try {
      final response =
          await _apiClient.dio.get('/courses/$courseId/enrollments/count');
      return (response.data as num).toInt();
    } on DioException catch (_) {
      return 0;
    }
  }
}
