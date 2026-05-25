import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class NotificationApiService {
  final Dio _dio = DioClient.instance;

  Future<List<dynamic>> fetchByGuardian(String guardianId) async {
    final response = await _dio.get('${ApiConstants.notificationBase}/guardian/$guardianId');
    return response.data as List<dynamic>;
  }

  Future<int> fetchUnreadCount(String guardianId) async {
    final response = await _dio.get('${ApiConstants.notificationBase}/guardian/$guardianId/unread-count');
    return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
  }

  Future<void> deleteNotification(String notificationId) async {
    await _dio.delete('${ApiConstants.notificationBase}/$notificationId');
  }

  Future<void> markAllRead(String guardianId) async {
    await _dio.put('${ApiConstants.notificationBase}/guardian/$guardianId/read-all');
  }

  Future<void> registerAdminFcmToken(String customId, String fcmToken) async {
    await _dio.post(
      '${ApiConstants.notificationBase}/admin/$customId/fcm-token',
      data: {'fcmToken': fcmToken},
    );
  }

  Future<void> registerNurseFcmToken(String nurseId, String fcmToken) async {
    await _dio.post(
      '${ApiConstants.notificationBase}/nurse/$nurseId/fcm-token',
      data: {'fcmToken': fcmToken},
    );
  }
}