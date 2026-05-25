import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class AssessmentApiService {
  final Dio _dio = DioClient.instance;

  Future<List<dynamic>> fetchByResident(String residentId) async {
    final response = await _dio.get('${ApiConstants.assessmentBase}/resident/$residentId');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> addAssessment(Map<String, dynamic> data) async {
    final response = await _dio.post('${ApiConstants.assessmentBase}/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAssessment(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.assessmentBase}/$id', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteAssessment(String id) async {
    await _dio.delete('${ApiConstants.assessmentBase}/$id');
  }

  Future<Map<String, dynamic>> addComment(String assessmentId, Map<String, dynamic> data) async {
    final response = await _dio.post(
      '${ApiConstants.assessmentBase}/$assessmentId/comments',
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateReactions(String assessmentId, Map<String, dynamic> reactions) async {
    final response = await _dio.put(
      '${ApiConstants.assessmentBase}/$assessmentId/reactions',
      data: reactions,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadFile(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post(
      '${ApiConstants.assessmentBase}/upload-file',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }
}