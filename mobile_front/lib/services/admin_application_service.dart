import 'package:dio/dio.dart';
import '../models/instructor_profile.dart';
import 'api_client.dart';

class AdminApplicationService {
  final ApiClient _apiClient = ApiClient();

  Future<List<InstructorProfile>> getPendingApplications() async {
    try {
      final response = await _apiClient.dio.get('/admin/applications');
      final data = response.data as List<dynamic>;
      return data.map((e) => InstructorProfile.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load applications');
    }
  }

  Future<List<InstructorProfile>> searchApplications({
    String? username,
    String? specialization,
    String? experience,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (username != null && username.isNotEmpty) queryParams['username'] = username;
      if (specialization != null && specialization.isNotEmpty) queryParams['specialization'] = specialization;
      if (experience != null && experience.isNotEmpty) queryParams['experience'] = experience;

      final response = await _apiClient.dio.get(
        '/admin/applications/search',
        queryParameters: queryParams,
      );
      final data = response.data as List<dynamic>;
      return data.map((e) => InstructorProfile.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to search applications');
    }
  }

  Future<void> approveApplication(String userId) async {
    try {
      await _apiClient.dio.patch('/admin/applications/$userId/approve');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to approve application');
    }
  }

  Future<void> declineApplication(String userId) async {
    try {
      await _apiClient.dio.patch('/admin/applications/$userId/decline');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to decline application');
    }
  }
}
