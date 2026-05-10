import 'package:dio/dio.dart';
import '../models/category.dart';
import 'api_client.dart';

class CategoryService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/categories');

      if (response.data is List) {
        return (response.data as List)
            .map((json) => Category.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception('Failed to load categories: ${e.message}');
    }
  }
}
