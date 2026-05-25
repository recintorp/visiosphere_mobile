import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class IncidentApiService {
  final Dio _dio = DioClient.instance;

  Future<List<dynamic>> fetchIncidents() async {
    final response = await _dio.get(ApiConstants.incidentBase);
    return response.data as List<dynamic>;
  }

  Future<int> fetchUnreadCount() async {
    final response = await _dio.get('${ApiConstants.incidentBase}/unread-count');
    return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
  }

  Future<List<dynamic>> fetchWeeklyStats({
    required String weekStart,
    required String tz,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.incidentBase}/stats/weekly',
      queryParameters: {'weekStart': weekStart, 'tz': tz},
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> fetchDailyStats() async {
    final response = await _dio.get('${ApiConstants.incidentBase}/stats/daily');
    return response.data as Map<String, dynamic>;
  }

  Future<void> acknowledgeIncident(String id) async {
    await _dio.put('${ApiConstants.incidentBase}/$id/acknowledge');
  }

  Future<void> dismissIncident(String id) async {
    await _dio.put('${ApiConstants.incidentBase}/$id/dismiss');
  }

  Future<void> resolveIncident(String id) async {
    await _dio.put('${ApiConstants.incidentBase}/$id/resolve');
  }
}