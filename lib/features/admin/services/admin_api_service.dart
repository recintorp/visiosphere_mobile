import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class AdminApiService {
  final Dio _dio = DioClient.instance;

  Future<Map<String, dynamic>> fetchDashboardStats() async {
    final results = await Future.wait([
      _dio.get('${ApiConstants.residentBase}/stats/comparison'),
      _dio.get('${ApiConstants.nurseBase}/stats/comparison'),
      _dio.get('${ApiConstants.incidentBase}/stats/daily'),
    ]);

    final residentsData = results[0].data as Map<String, dynamic>;
    final nursesData    = results[1].data as Map<String, dynamic>;
    final alertsData    = results[2].data as Map<String, dynamic>;

    return {
      'elders': {
        'current': (residentsData['current'] as num?)?.toInt() ?? 0,
        'delta':   (residentsData['diff']    as num?)?.toInt() ?? 0,
        'trend':    residentsData['direction'] as String? ?? 'neutral',
        'label':    residentsData['label']    as String? ?? 'No changes since last month',
      },
      'nurses': {
        'current': (nursesData['current'] as num?)?.toInt() ?? 0,
        'delta':   (nursesData['diff']    as num?)?.toInt() ?? 0,
        'trend':    nursesData['direction'] as String? ?? 'neutral',
        'label':    nursesData['label']    as String? ?? 'No changes since last month',
      },
      'alerts': {
        'current': (alertsData['current'] as num?)?.toInt() ?? 0,
        'delta':   (alertsData['diff']    as num?)?.toInt() ?? 0,
        'trend':    alertsData['direction'] as String? ?? 'neutral',
        'label':    alertsData['label']    as String? ?? 'No changes since yesterday',
      },
      'cameras': {
        'online': 2,
        'total':  2,
        'label':  '2 / 2 online',
      },
    };
  }

  Future<Map<String, dynamic>> fetchLinkedNurseProfile(String adminId) async {
    final response = await _dio.get('${ApiConstants.nurseBase}/linked-profile/$adminId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchStandaloneNurseProfile(String nurseId) async {
    final response = await _dio.get('${ApiConstants.nurseBase}/$nurseId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAdminProfile(String adminId) async {
    final response = await _dio.get('${ApiConstants.adminBase}/$adminId');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(String adminId, Map<String, dynamic> data) async {
    final response = await _dio.put('${ApiConstants.adminBase}/$adminId/profile', data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> changePassword(String adminId, String oldPassword, String newPassword) async {
    final response = await _dio.put(
      '${ApiConstants.adminBase}/$adminId/change-password',
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> toggle2FA(String adminId, bool enable, {String? pin}) async {
    final response = await _dio.post(
      '${ApiConstants.adminBase}/$adminId/toggle-2fa',
      data: {'enable': enable, 'pin': pin},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> linkNurse(String adminId, String nurseId) async {
    final response = await _dio.post(
      '${ApiConstants.adminBase}/$adminId/link-nurse',
      data: {'nurseId': nurseId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> unlinkNurse(String adminId) async {
    final response = await _dio.post('${ApiConstants.adminBase}/$adminId/unlink-nurse');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deactivateAccount(String adminId) async {
    final response = await _dio.put('${ApiConstants.adminBase}/$adminId/deactivate');
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchSettings() async {
    final response = await _dio.get(ApiConstants.settingsBase);
    return response.data as Map<String, dynamic>;
  }
}