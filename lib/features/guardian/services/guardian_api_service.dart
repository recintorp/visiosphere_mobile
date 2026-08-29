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

  // THE ROUTE IS /guardians/link-elder, NOT /guardians/<id>/link-elder.
  //
  // These two called a path that does not exist on the backend. Express matches
  // `PUT /guardians/:guardianId` against ONE segment, so `/guardians/G-2026
  // 01/link-elder` fell through every route and came back 404 — which the
  // provider caught, logged to debugPrint, and turned into "Failed to assign
  // elder." Assigning a resident to a guardian has therefore never worked from
  // the phone, and a guardian account with no resident linked to it is an
  // account that does nothing.
  //
  // The real route (backend/routes/guardianRoutes.js) takes both ids in the
  // BODY, which is also what the web client sends.
  Future<Map<String, dynamic>> linkElder(String guardianId, String residentId) async {
    final response = await _dio.put(
      '${ApiConstants.guardianBase}/link-elder',
      data: {'guardianId': guardianId, 'residentId': residentId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlinkElder(String guardianId, String residentId) async {
    final response = await _dio.put(
      '${ApiConstants.guardianBase}/unlink-elder',
      data: {'guardianId': guardianId, 'residentId': residentId},
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