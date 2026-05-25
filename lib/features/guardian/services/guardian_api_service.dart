import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class GuardianApiService {
  final Dio _dio = DioClient.instance;

  Future<List<dynamic>> fetchAllGuardians() async {
    final response = await _dio.get('${ApiConstants.guardianBase}/all');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> getGuardian(String guardianId) async {
    final response = await _dio.get('${ApiConstants.guardianBase}/$guardianId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addGuardian(Map<String, dynamic> data) async {
    final response = await _dio.post('${ApiConstants.guardianBase}/add', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateGuardian(String guardianId, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.guardianBase}/$guardianId', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteGuardian(String guardianId) async {
    await _dio.delete('${ApiConstants.guardianBase}/$guardianId');
  }

  Future<Map<String, dynamic>> linkElder(String guardianId, String residentId) async {
    final response = await _dio.put(
      '${ApiConstants.guardianBase}/$guardianId/link-elder',
      data: {'residentId': residentId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlinkElder(String guardianId, String residentId) async {
    final response = await _dio.put(
      '${ApiConstants.guardianBase}/$guardianId/unlink-elder',
      data: {'residentId': residentId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> registerFcmToken(String guardianId, String token) async {
    await _dio.post(
      '${ApiConstants.guardianBase}/$guardianId/fcm-token',
      data: {'token': token},
    );
  }

  Future<Map<String, dynamic>> changePassword({
    required String guardianId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await _dio.put(
      ApiConstants.guardianChangePassword,
      data: {
        'guardianId': guardianId,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmPassword': newPassword,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(String guardianId, File imageFile) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(imageFile.path),
    });
    final response = await _dio.post(
      '${ApiConstants.guardianBase}/$guardianId/upload-photo',
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }
}