import 'package:dio/dio.dart';
import '../models/app_user.dart';
import 'api_client.dart';

class AdminUserService {
  final ApiClient _apiClient = ApiClient();

  Future<List<AppUser>> getAllUsers() async {
    try {
      final responses = await Future.wait([
        _apiClient.dio.get('/instructors'),
        _apiClient.dio.get('/students'),
      ]);

      final List<AppUser> allUsers = [];

      // Process Instructors
      final instructorData = responses[0].data as List<dynamic>;
      allUsers.addAll(instructorData.map((e) => AppUser.fromJson(e, 'INSTRUCTOR')));

      // Process Students
      final studentData = responses[1].data as List<dynamic>;
      allUsers.addAll(studentData.map((e) => AppUser.fromJson(e, 'STUDENT')));

      return allUsers;
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load users');
    }
  }

  Future<void> banUser(String userId) async {
    try {
      await _apiClient.dio.patch('/admin/users/$userId/ban');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to ban user');
    }
  }

  Future<void> unbanUser(String userId) async {
    try {
      await _apiClient.dio.patch('/admin/users/$userId/unban');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to unban user');
    }
  }

  Future<void> highlightInstructor(String instructorId) async {
    try {
      await _apiClient.dio.patch('/admin/instructors/$instructorId/highlight');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to highlight instructor');
    }
  }

  Future<void> unhighlightInstructor(String instructorId) async {
    try {
      await _apiClient.dio.patch('/admin/instructors/$instructorId/unhighlight');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to unhighlight instructor');
    }
  }

  Future<List<dynamic>> getInstructorCourses(String instructorId) async {
    try {
      final response = await _apiClient.dio.get('/instructors/$instructorId/courses');
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load instructor courses');
    }
  }
}
