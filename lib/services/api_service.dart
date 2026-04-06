import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../core/constants/api_constants.dart';

class ApiService {
  static const String baseUrl = ApiConstants.baseUrl;
  
  static const String guardianLogin = '$baseUrl/guardians/auth/login';
  static const String setPasswordEndpoint = '$baseUrl/guardians/auth/set-password';
  static const String getGuardianById = '$baseUrl/guardians';
  static const String getAllGuardiansEndpoint = '$baseUrl/guardians/all';
  static const String addGuardianEndpoint = '$baseUrl/guardians/add';
  static const String linkElderEndpoint = '$baseUrl/guardians/link-elder';

  static const String adminLogin = '$baseUrl/admin/login';
  static const String setAdminPasswordEndpoint = '$baseUrl/admin/set-password';
  static const String verifyAdmin2FAEndpoint = '$baseUrl/admin/verify-2fa';
  static const String toggleAdmin2FAEndpoint = '$baseUrl/admin/toggle-2fa';

  static const String nurseLogin = '$baseUrl/nurses/auth/login';
  static const String setNursePasswordEndpoint = '$baseUrl/nurses/auth/set-password';

  static const String getAllResidentsEndpoint = '$baseUrl/residents/all';
  static const String addResidentEndpoint = '$baseUrl/residents/add';
  static const String batchResidentsEndpoint = '$baseUrl/residents/batch';
  static const String residentBaseEndpoint = '$baseUrl/residents';

  static const String assessmentsBaseEndpoint = '$baseUrl/assessments';
  static const String auditLogsEndpoint = '$baseUrl/audit-logs';
  static const String settingsEndpoint = '$baseUrl/settings';

  static const Duration timeout = Duration(seconds: 10);

  static String _handleError(http.Response response) {
    try {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['message'] ?? 'An error occurred';
    } catch (e) {
      return 'Error: ${response.statusCode}';
    }
  }

  static Future<Map<String, dynamic>> testConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/status'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException('Connection test timeout');
      });

      return {'success': true, 'message': 'Connected', 'data': response.body};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> loginGuardian({
    required String guardianId,
    String? password,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {'guardianId': guardianId};
      
      if (password != null && password.isNotEmpty) {
        requestBody['password'] = password;
      }

      final response = await http
          .post(
            Uri.parse(guardianLogin),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> setPassword({
    required String guardianId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(setPasswordEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'guardianId': guardianId,
              'newPassword': newPassword,
              'confirmPassword': confirmPassword,
            }),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> loginAdmin({
    required String adminId,
    String? password,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {'customId': adminId};
      
      if (password != null && password.isNotEmpty) {
        requestBody['password'] = password;
      }

      final response = await http
          .post(
            Uri.parse(adminLogin),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> verifyAdmin2FA({
    required String adminId,
    required String pin,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(verifyAdmin2FAEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'customId': adminId,
              'pin': pin,
            }),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> toggleAdmin2FA({
    required String adminId,
    required bool enable,
    String? pin,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(toggleAdmin2FAEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'customId': adminId,
              'enable': enable,
              'pin': pin,
            }),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> setAdminPassword({
    required String adminId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(setAdminPasswordEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'customId': adminId,
              'newPassword': newPassword,
              'confirmPassword': confirmPassword,
            }),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> loginNurse({
    required String nurseId,
    String? password,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {'nurseId': nurseId};
      
      if (password != null && password.isNotEmpty) {
        requestBody['password'] = password;
      }

      final response = await http
          .post(
            Uri.parse(nurseLogin),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> setNursePassword({
    required String nurseId,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(setNursePasswordEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'nurseId': nurseId,
              'newPassword': newPassword,
              'confirmPassword': confirmPassword,
            }),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> getGuardian(String guardianId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$getGuardianById/$guardianId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateGuardian(String guardianId, Map<String, dynamic> updateData) async {
    try {
      final response = await http
          .put(
            Uri.parse('$getGuardianById/$guardianId'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updateData),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> uploadProfilePhoto(String guardianId, File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$getGuardianById/$guardianId/upload-photo'));
      request.files.add(await http.MultipartFile.fromPath('profileImage', imageFile.path));
      var streamedResponse = await request.send().timeout(timeout);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> fetchAllResidents() async {
    try {
      final response = await http
          .get(
            Uri.parse(getAllResidentsEndpoint),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> addResident(Map<String, dynamic> residentData) async {
    try {
      final response = await http
          .post(
            Uri.parse(addResidentEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(residentData),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateResident(String id, Map<String, dynamic> updateData) async {
    try {
      final response = await http
          .put(
            Uri.parse('$residentBaseEndpoint/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updateData),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteResident(String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$residentBaseEndpoint/$id'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> batchImportResidents(List<Map<String, dynamic>> residents) async {
    try {
      final response = await http
          .post(
            Uri.parse(batchResidentsEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'residents': residents}),
          )
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw TimeoutException('Batch request timeout. Processing may take longer.');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> fetchAllGuardians() async {
    try {
      final response = await http
          .get(
            Uri.parse(getAllGuardiansEndpoint),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> addGuardianAccount(Map<String, dynamic> guardianData) async {
    try {
      final response = await http
          .post(
            Uri.parse(addGuardianEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(guardianData),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateGuardianDetails(String id, Map<String, dynamic> updateData) async {
    try {
      final response = await http
          .put(
            Uri.parse('$getGuardianById/$id'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(updateData),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteGuardianAccount(String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$getGuardianById/$id'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> linkElderToGuardian(String guardianId, String residentId) async {
    try {
      final response = await http
          .put(
            Uri.parse(linkElderEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'guardianId': guardianId,
              'residentId': residentId,
            }),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> fetchAssessments(String residentId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$assessmentsBaseEndpoint/resident/$residentId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> addAssessment(Map<String, dynamic> assessmentData) async {
    try {
      final response = await http
          .post(
            Uri.parse('$assessmentsBaseEndpoint/add'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(assessmentData),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteAssessment(String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$assessmentsBaseEndpoint/$id'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> uploadAssessmentFile(File file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$assessmentsBaseEndpoint/upload'));
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
      
      var streamedResponse = await request.send().timeout(timeout);
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> fetchAuditLogs() async {
    try {
      final response = await http
          .get(
            Uri.parse(auditLogsEndpoint),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> fetchSettings() async {
    try {
      final response = await http
          .get(
            Uri.parse(settingsEndpoint),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settingsData) async {
    try {
      final response = await http
          .put(
            Uri.parse(settingsEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(settingsData),
          )
          .timeout(timeout, onTimeout: () {
        throw TimeoutException('Request timeout');
      });

      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      } else {
        return {'success': false, 'message': _handleError(response)};
      }
    } on TimeoutException catch (_) {
      return {'success': false, 'message': 'Request timed out. Server not responding.'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}