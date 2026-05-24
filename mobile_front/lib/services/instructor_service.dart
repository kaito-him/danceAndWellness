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

  /// POST /api/files/upload — upload a file and return its URL
  Future<String> uploadFile(String filePath, String fileName) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await _apiClient.dio.post(
        '/files/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return response.data['url'] as String;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to upload file');
    }
  }

  /// GET /api/instructor/payments/{instructorId}/status
  Future<Map<String, dynamic>?> getStripeStatus(String instructorId) async {
    try {
      final response = await _apiClient.dio
          .get('/instructor/payments/$instructorId/status');
      return response.data as Map<String, dynamic>;
    } on DioException catch (_) {
      return null;
    }
  }

  /// POST /api/courses — publish a course
  Future<void> publishCourse(Map<String, dynamic> payload) async {
    try {
      await _apiClient.dio.post('/courses', data: payload);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to publish course');
    }
  }

  /// POST /api/courses/draft — save a draft
  Future<void> saveDraft(Map<String, dynamic> payload) async {
    try {
      await _apiClient.dio.post('/courses/draft', data: payload);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to save draft');
    }
  }
}
