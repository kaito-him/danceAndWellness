import 'package:dio/dio.dart';
import '../models/badge.dart';
import 'api_client.dart';

class BadgeService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Badge>> getAllBadges() async {
    try {
      final response = await _apiClient.dio.get('/badges');
      final list = response.data as List<dynamic>;
      return list.map((e) => Badge.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load badges');
    }
  }

  Future<Map<String, int>> getEarnerCounts() async {
    try {
      final response = await _apiClient.dio.get('/badges/earner-counts');
      final data = response.data as Map<String, dynamic>;
      return data.map((key, value) => MapEntry(key, value as int));
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load earner counts');
    }
  }

  Future<Badge> createBadge(Badge badge) async {
    try {
      final response = await _apiClient.dio.post('/badges', data: badge.toJson());
      return Badge.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to create badge');
    }
  }

  Future<Badge> updateBadge(String id, Badge badge) async {
    try {
      final response = await _apiClient.dio.put('/badges/$id', data: badge.toJson());
      return Badge.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to update badge');
    }
  }

  Future<void> deleteBadge(String id) async {
    try {
      await _apiClient.dio.delete('/badges/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to delete badge');
    }
  }
}
