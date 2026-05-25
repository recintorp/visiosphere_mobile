import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class NurseApiService {
  final Dio _dio = DioClient.instance;

  Future<List<dynamic>> fetchAllNurses() async {
    final response = await _dio.get('${ApiConstants.nurseBase}/all');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> provisionNurse(Map<String, dynamic> data) async {
    final response = await _dio.post(
      '${ApiConstants.nurseBase}/add',
      data: {...data, 'isFirstLogin': true},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getNurseProfile(String nurseId) async {
    final response = await _dio.get('${ApiConstants.nurseBase}/$nurseId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateNurse(String nurseId, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.nurseBase}/$nurseId', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteNurse(String nurseId) async {
    await _dio.delete('${ApiConstants.nurseBase}/$nurseId');
  }

  Future<Map<String, dynamic>> assignElder(String nurseId, String elderId) async {
    final response = await _dio.put(
      '${ApiConstants.nurseBase}/$nurseId/assign-elder',
      data: {'elderId': elderId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unassignElder(String nurseId, String elderId) async {
    final response = await _dio.put(
      '${ApiConstants.nurseBase}/$nurseId/unassign-elder',
      data: {'elderId': elderId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(String nurseId, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.nurseBase}/$nurseId/profile', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changePassword(String nurseId, String oldPassword, String newPassword) async {
    final response = await _dio.put(
      '${ApiConstants.nurseBase}/$nurseId/change-password',
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(String nurseId, File imageFile) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(imageFile.path),
    });
    final response = await _dio.post(
      '${ApiConstants.nurseBase}/$nurseId/upload-photo',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }
}