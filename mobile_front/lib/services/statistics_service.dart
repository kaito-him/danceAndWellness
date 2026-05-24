import '../models/overall_stats.dart';
import '../models/today_stats.dart';
import 'api_client.dart';

class StatisticsService {
  final ApiClient _apiClient;

  StatisticsService(this._apiClient);

  Future<OverallStats> getOverallStats() async {
    try {
      final response = await _apiClient.dio.get('/statistics/overall');
      return OverallStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load overall statistics: $e');
    }
  }

  Future<TodayStats> getTodayStats() async {
    try {
      final response = await _apiClient.dio.get('/statistics/today');
      return TodayStats.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load today\'s statistics: $e');
    }
  }
}
