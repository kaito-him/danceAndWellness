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

  /// PATCH /api/instructors/{instructorId}
  /// Updates instructor-specific fields + username/email.
  /// Returns the updated instructor map and optionally a new token.
  Future<Map<String, dynamic>> updateInstructorProfile({
    required String instructorId,
    required String currentPassword,
    String? username,
    String? email,
    String? studioName,
    String? linkedIn,
    String? website,
    String? bio,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/instructors/$instructorId',
        data: {
          'currentPassword': currentPassword,
          'instructor': {
            if (username != null) 'username': username,
            if (email != null) 'email': email,
            if (studioName != null) 'studioName': studioName,
            if (linkedIn != null) 'linkedIn': linkedIn,
            if (website != null) 'website': website,
            if (bio != null) 'bio': bio,
          },
        },
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {'instructor': data};
    } on DioException catch (e) {
      final msg = e.response?.data;
      if (msg is Map && msg['error'] != null) {
        throw Exception(msg['error']);
      }
      throw Exception(msg?.toString() ?? 'Failed to update profile');
    }
  }

  /// GET /api/courses/published — all published courses (community feed)
  Future<List<Course>> getAllPublishedCourses() async {
    try {
      final response = await _apiClient.dio.get('/courses/published');
      final list = response.data as List<dynamic>;
      return list.map((e) => Course.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load courses');
    }
  }

  /// GET /api/categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/categories');
      return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load categories');
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

  /// GET /api/instructor/payments/{instructorId}/enrollments
  Future<List<Map<String, dynamic>>> getPaymentEnrollments(String instructorId) async {
    try {
      final response = await _apiClient.dio.get('/instructor/payments/$instructorId/enrollments');
      return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load enrollments');
    }
  }

  /// GET /api/instructor/payments/{instructorId}/status
  Future<Map<String, dynamic>> getStripeStatus(String instructorId) async {
    try {
      final response = await _apiClient.dio.get('/instructor/payments/$instructorId/status');
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load Stripe status');
    }
  }

  /// POST /api/instructor/payments/{instructorId}/onboard
  Future<String?> getStripeOnboardingUrl(String instructorId) async {
    try {
      final response = await _apiClient.dio.post('/instructor/payments/$instructorId/onboard');
      return response.data['url'] as String?;
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to get onboarding link');
    }
  }

  /// DELETE /api/courses/{courseId}
  Future<void> deleteCourse(String courseId) async {
    try {
      await _apiClient.dio.delete('/courses/$courseId');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to delete course');
    }
  }

  /// GET /api/courses/my-archived
  Future<List<Course>> getArchivedCourses() async {
    try {
      final response = await _apiClient.dio.get('/courses/my-archived');
      final list = response.data as List<dynamic>;
      return list.map((e) => Course.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to load archived courses');
    }
  }

  /// PATCH /api/courses/{courseId}/archive-instructor
  Future<void> archiveCourseByInstructor(String courseId) async {
    try {
      await _apiClient.dio.patch('/courses/$courseId/archive-instructor');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to archive course');
    }
  }

  /// PATCH /api/courses/{courseId}/unarchive
  Future<void> unarchiveCourseByInstructor(String courseId) async {
    try {
      await _apiClient.dio.patch('/courses/$courseId/unarchive');
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to unarchive course');
    }
  }

  /// GET /api/courses/{courseId}
  Future<Course> getCourseById(String courseId) async {
    try {
      final response = await _apiClient.dio.get('/courses/$courseId');
      return Course.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load course');
    }
  }

  /// GET /api/categories/{categoryId}
  Future<String> getCategoryName(String categoryId) async {
    try {
      final response = await _apiClient.dio.get('/categories/$categoryId');
      return response.data['name'] ?? 'Category';
    } on DioException catch (_) {
      return 'Category';
    }
  }

  /// GET /api/quizzes/instructor/attempts?courseId=...
  Future<List<Map<String, dynamic>>> getQuizAttempts(String courseId) async {
    try {
      final response = await _apiClient.dio.get(
        '/quizzes/instructor/attempts',
        queryParameters: {'courseId': courseId},
      );
      return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
    } on DioException catch (_) {
      return [];
    }
  }

  /// GET /api/progress/instructor/student-course?studentId=...&courseId=...
  Future<Map<String, dynamic>?> getStudentCourseProgress(
      String studentId, String courseId) async {
    try {
      final response = await _apiClient.dio.get(
        '/progress/instructor/student-course',
        queryParameters: {'studentId': studentId, 'courseId': courseId},
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (_) {
      return null;
    }
  }

  /// GET /api/courses/{courseId}/comments
  Future<List<Map<String, dynamic>>> getComments(String courseId) async {
    try {
      final response =
          await _apiClient.dio.get('/courses/$courseId/comments');
      return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
    } on DioException catch (_) {
      return [];
    }
  }

  /// POST /api/courses/{courseId}/comments
  Future<Map<String, dynamic>> addComment(
      String courseId, String content) async {
    try {
      final response = await _apiClient.dio.post(
        '/courses/$courseId/comments',
        data: {'content': content},
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to add comment');
    }
  }

  /// GET /api/courses/{courseId}/comments/{commentId}/replies
  Future<List<Map<String, dynamic>>> getReplies(
      String courseId, String commentId) async {
    try {
      final response = await _apiClient.dio
          .get('/courses/$courseId/comments/$commentId/replies');
      return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
    } on DioException catch (_) {
      return [];
    }
  }

  /// POST /api/courses/{courseId}/comments/{commentId}/replies
  Future<Map<String, dynamic>> addReply(
      String courseId, String commentId, String content) async {
    try {
      final response = await _apiClient.dio.post(
        '/courses/$courseId/comments/$commentId/replies',
        data: {'content': content},
      );
      return Map<String, dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data?.toString() ?? 'Failed to add reply');
    }
  }
}

