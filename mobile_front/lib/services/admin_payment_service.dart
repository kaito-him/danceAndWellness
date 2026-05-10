import 'package:dio/dio.dart';
import '../models/admin_payment.dart';
import 'api_client.dart';

class AdminPaymentService {
  final ApiClient _apiClient = ApiClient();

  Future<AdminRevenueSummary> getSummary() async {
    try {
      final response = await _apiClient.dio.get('/admin/payments/summary');
      return AdminRevenueSummary.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load summary');
    }
  }

  Future<List<AdminTransaction>> getTransactions() async {
    try {
      final response = await _apiClient.dio.get('/admin/payments/transactions');
      final list = response.data as List<dynamic>;
      return list.map((e) => AdminTransaction.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load transactions');
    }
  }
}
