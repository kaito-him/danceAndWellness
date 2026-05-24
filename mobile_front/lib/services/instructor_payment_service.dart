import 'api_client.dart';
import '../models/instructor_payment.dart';

class InstructorPaymentService {
  final ApiClient _api = ApiClient();

  Future<StripeStatus> getStatus(String instructorId) async {
    final response = await _api.dio.get('/instructor/payments/$instructorId/status');
    return StripeStatus.fromJson(response.data);
  }

  Future<String> getOnboardingLink(String instructorId) async {
    final response = await _api.dio.post('/instructor/payments/$instructorId/onboard');
    return response.data['url'] as String;
  }

  Future<List<InstructorEnrollmentRow>> getEnrollments(String instructorId) async {
    final response = await _api.dio.get('/instructor/payments/$instructorId/enrollments');
    if (response.data is List) {
      return (response.data as List).map((e) => InstructorEnrollmentRow.fromJson(e)).toList();
    }
    return [];
  }

  Future<String> getDashboardLink(String instructorId) async {
    final response = await _api.dio.get('/instructor/payments/$instructorId/dashboard');
    return response.data['url'] as String;
  }
}
