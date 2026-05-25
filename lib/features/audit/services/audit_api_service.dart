import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class AuditApiService {
  final Dio _dio = DioClient.instance;

  Future<List<dynamic>> fetchAuditLogs() async {
    final response = await _dio.get(ApiConstants.auditBase);
    final data = response.data;
    if (data is List) return data;
    return (data as Map<String, dynamic>)['logs'] as List<dynamic>? ?? [];
  }
}