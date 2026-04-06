import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class GuardianProvider extends ChangeNotifier {
  Map<String, dynamic>? _guardianData;
  List<dynamic> _assignedElders = [];
  List<dynamic> _assessments = [];
  int _selectedElderIndex = 0;
  bool _isLoading = false;
  bool _isSynced = false;
  String? _errorMessage;

  Map<String, dynamic>? get guardianData => _guardianData;
  List<dynamic> get assignedElders => _assignedElders;
  List<dynamic> get assessments => _assessments;
  int get selectedElderIndex => _selectedElderIndex;
  bool get isLoading => _isLoading;
  bool get isSynced => _isSynced;
  String? get errorMessage => _errorMessage;

  Future<void> fetchGuardianData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      const String currentGuardianId = "G-202601"; 

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/guardians/$currentGuardianId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _guardianData = data;
        _assignedElders = data['assignedElders'] ?? [];
        
        if (_assignedElders.isNotEmpty) {
          if (_selectedElderIndex >= _assignedElders.length) {
            _selectedElderIndex = 0;
          }
          await fetchElderAssessments(_assignedElders[_selectedElderIndex]['_id']);
        }
      } else {
        _errorMessage = 'Failed to load profile. Status: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Network error occurred while fetching data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchElderAssessments(String residentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/assessments/resident/$residentId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _assessments = json.decode(response.body);
      } else {
        _assessments = [];
      }
    } catch (e) {
      _assessments = [];
    }
    notifyListeners();
  }

  void setSelectedElder(int index) {
    if (index >= 0 && index < _assignedElders.length) {
      _selectedElderIndex = index;
      notifyListeners();
      fetchElderAssessments(_assignedElders[index]['_id']);
    }
  }

  void setSynced(bool status) {
    _isSynced = status;
    notifyListeners();
  }

  Future<bool> updateProfileInfo(String email, String phone) async {
    if (_guardianData == null) return false;
    
    try {
      final String guardianId = _guardianData!['guardianId'];
      
      final Map<String, dynamic> updateData = {
        'firstName': _guardianData!['firstName'],
        'middleName': _guardianData!['middleName'],
        'lastName': _guardianData!['lastName'],
        'email': email,
        'phone': phone,
        'birthday': _guardianData!['birthday'],
        'gender': _guardianData!['gender'],
        'status': _guardianData!['status'],
        'profilePhoto': _guardianData!['profilePhoto'],
      };

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/guardians/$guardianId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _guardianData!['email'] = email;
        _guardianData!['phone'] = phone;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_guardianData == null) return false;
    
    try {
      final String guardianId = _guardianData!['guardianId'];

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/guardians/auth/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'guardianId': guardianId,
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'confirmPassword': newPassword,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendComment(String assessmentId, String text) async {
    if (_guardianData == null) return false;
    
    try {
      final String senderId = _guardianData!['guardianId'];
      final String senderName = '${_guardianData!['firstName']} ${_guardianData!['lastName']}';

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/assessments/$assessmentId/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'senderId': senderId,
          'senderName': senderName,
          'senderRole': 'Guardian',
          'text': text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (_assignedElders.isNotEmpty) {
          await fetchElderAssessments(_assignedElders[_selectedElderIndex]['_id']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendReaction(String assessmentId, String reactionKey, bool isActive) async {
    if (_guardianData == null) return false;
    
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/assessments/$assessmentId/reactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          reactionKey: isActive
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (_assignedElders.isNotEmpty) {
          await fetchElderAssessments(_assignedElders[_selectedElderIndex]['_id']);
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void clearData() {
    _guardianData = null;
    _assignedElders = [];
    _assessments = [];
    _selectedElderIndex = 0;
    _isSynced = false;
    notifyListeners();
  }
}