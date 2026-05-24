import 'package:dio/dio.dart';
import 'api_client.dart';

class EnrollmentRow {
  final String enrollmentId;
  final String studentId;
  final String studentName;
  final String? studentEmail;
  final String? studentPhoto;
  final String enrollmentType;
  final String? enrolledAt;

  EnrollmentRow({
    required this.enrollmentId,
    required this.studentId,
    required this.studentName,
    this.studentEmail,
    this.studentPhoto,
    required this.enrollmentType,
    this.enrolledAt,
  });

  factory EnrollmentRow.fromJson(Map<String, dynamic> json) {
    return EnrollmentRow(
      enrollmentId: json['enrollmentId'] ?? '',
      studentId: json['studentId'] ?? '',
      studentName: json['studentName'] ?? 'Unknown',
      studentEmail: json['studentEmail'],
      studentPhoto: json['studentPhoto'],
      enrollmentType: json['enrollmentType'] ?? 'FREE',
      enrolledAt: json['enrolledAt']?.toString(),
    );
  }
}

class StudentProgress {
  final double completionPercent;
  final int completedLessons;
  final int totalLessons;
  final String? lastUpdated;
  final List<LessonProgress> lessonProgress;

  StudentProgress({
    required this.completionPercent,
    required this.completedLessons,
    required this.totalLessons,
    this.lastUpdated,
    this.lessonProgress = const [],
  });

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    final cp = json['courseProgress'] as Map<String, dynamic>? ?? {};
    final lp = json['lessonProgress'] as List<dynamic>? ?? [];
    return StudentProgress(
      completionPercent: (cp['completionPercent'] as num?)?.toDouble() ?? 0,
      completedLessons: cp['completedLessons'] as int? ?? 0,
      totalLessons: cp['totalLessons'] as int? ?? 0,
      lastUpdated: cp['lastUpdated']?.toString(),
      lessonProgress: lp.map((e) => LessonProgress.fromJson(e)).toList(),
    );
  }
}

class LessonProgress {
  final String lessonId;
  final String? lessonTitle;
  final double completionPercent;
  final String? lastUpdated;

  LessonProgress({
    required this.lessonId,
    this.lessonTitle,
    required this.completionPercent,
    this.lastUpdated,
  });

  factory LessonProgress.fromJson(Map<String, dynamic> json) {
    return LessonProgress(
      lessonId: json['lessonId'] ?? '',
      lessonTitle: json['lessonTitle'],
      completionPercent: (json['completionPercent'] as num?)?.toDouble() ?? 0,
      lastUpdated: json['lastUpdated']?.toString(),
    );
  }
}

class EnrollmentService {
  final ApiClient _apiClient = ApiClient();

  /// GET /api/instructor/payments/course/{courseId}/enrollments
  Future<List<EnrollmentRow>> getCourseEnrollments(String courseId) async {
    try {
      final response = await _apiClient.dio
          .get('/instructor/payments/course/$courseId/enrollments');
      final list = response.data as List<dynamic>;
      return list.map((e) => EnrollmentRow.fromJson(e)).toList();
    } on DioException catch (_) {
      return [];
    }
  }

  /// GET /api/progress/instructor/student-course?studentId=&courseId=
  Future<StudentProgress?> getStudentProgress(
      String studentId, String courseId) async {
    try {
      final response = await _apiClient.dio.get(
        '/progress/instructor/student-course',
        queryParameters: {'studentId': studentId, 'courseId': courseId},
      );
      return StudentProgress.fromJson(response.data);
    } on DioException catch (_) {
      return null;
    }
  }

  /// POST /api/enrollment/free
  Future<void> enrollFree(String studentId, String courseId) async {
    try {
      await _apiClient.dio.post(
        '/enrollment/free',
        queryParameters: {
          'studentId': studentId,
          'courseId': courseId,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to enroll');
    }
  }

  /// GET /api/enrollment/is-enrolled
  Future<bool> isEnrolled(String studentId, String courseId) async {
    try {
      final response = await _apiClient.dio.get(
        '/enrollment/is-enrolled',
        queryParameters: {
          'studentId': studentId,
          'courseId': courseId,
        },
      );
      return response.data['enrolled'] ?? false;
    } on DioException catch (_) {
      return false;
    }
  }

  /// DELETE /api/enrollment/cancel-free
  Future<void> cancelFreeEnrollment(String studentId, String courseId) async {
    try {
      await _apiClient.dio.delete(
        '/enrollment/cancel-free',
        queryParameters: {
          'studentId': studentId,
          'courseId': courseId,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to cancel enrollment');
    }
  }

  /// POST /api/progress/update
  Future<void> updateProgress({
    required String studentId,
    required String courseId,
    required String lessonId,
    required int watchedSeconds,
    required int totalSeconds,
  }) async {
    try {
      await _apiClient.dio.post(
        '/progress/update',
        data: {
          'studentId': studentId,
          'courseId': courseId,
          'lessonId': lessonId,
          'watchedSeconds': watchedSeconds,
          'totalSeconds': totalSeconds,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to update progress');
    }
  }
}

