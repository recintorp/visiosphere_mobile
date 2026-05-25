import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class ResidentApiService {
  final Dio _dio = DioClient.instance;

  Future<List<dynamic>> fetchAllResidents() async {
    final response = await _dio.get('${ApiConstants.residentBase}/all');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> addResident(Map<String, dynamic> data) async {
    final response = await _dio.post('${ApiConstants.residentBase}/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateResident(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.residentBase}/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteResident(String id) async {
    await _dio.delete('${ApiConstants.residentBase}/$id');
  }

  Future<List<dynamic>> fetchArchivedReports() async {
    final response = await _dio.get('${ApiConstants.reportBase}/all');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> saveReport(Map<String, dynamic> data) async {
    final response = await _dio.post('${ApiConstants.reportBase}/save', data: data);
    return response.data as Map<String, dynamic>;
  }
}