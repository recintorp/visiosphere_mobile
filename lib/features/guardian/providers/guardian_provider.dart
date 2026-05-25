import 'dart:io';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/secure_storage_service.dart';
import '../services/guardian_api_service.dart';
import '../../notification/services/notification_api_service.dart';
import '../../assessment/services/assessment_api_service.dart';

class GuardianProvider extends ChangeNotifier {
  final _guardianService = GuardianApiService();
  final _notificationService = NotificationApiService();
  final _assessmentService = AssessmentApiService();

  Map<String, dynamic>? _guardianData;
  List<dynamic> _assignedElders = [];
  List<dynamic> _assessments = [];

  List<dynamic> _notifications = [];
  int _unreadNotificationCount = 0;
  DateTime? _targetReportDate;

  int _selectedElderIndex = 0;
  bool _isLoading = false;
  bool _isSynced = false;
  String? _errorMessage;
  io.Socket? _socket;

  Map<String, dynamic>? get guardianData => _guardianData;
  List<dynamic> get assignedElders => _assignedElders;
  List<dynamic> get assessments => _assessments;
  List<dynamic> get notifications => _notifications;
  int get unreadNotificationCount => _unreadNotificationCount;
  DateTime? get targetReportDate => _targetReportDate;
  int get selectedElderIndex => _selectedElderIndex;
  bool get isLoading => _isLoading;
  bool get isSynced => _isSynced;
  String? get errorMessage => _errorMessage;
  String get appTheme => _guardianData?['appTheme'] ?? 'Auto';

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _initSocket() {
    if (_socket != null && _socket!.connected) return;

    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.on('new_assessment_comment', (data) {
      if (data == null) return;
      final assessmentId = data['assessmentId'];
      final comment = data['comment'];

      final index = _assessments.indexWhere((a) => a['_id'] == assessmentId);
      if (index != -1) {
        final existingComments = _assessments[index]['comments'] as List<dynamic>? ?? [];
        final isDuplicate = existingComments.any((c) =>
            c['_id'] == comment['_id'] ||
            (c['text'] == comment['text'] && c['senderName'] == comment['senderName']));

        if (!isDuplicate) {
          _assessments[index]['comments'] = [...existingComments, comment];
          notifyListeners();
        }
      }
    });

    _socket!.on('new_assessment_reaction', (data) {
      if (data == null) return;
      final index = _assessments.indexWhere((a) => a['_id'] == data['assessmentId']);
      if (index != -1) {
        _assessments[index]['reactions'] = data['reactions'];
        notifyListeners();
      }
    });

    _socket!.on('new_notification', (data) {
      if (data == null || data['notification'] == null) return;
      final notif = data['notification'];
      final guardianIdStr = _guardianData?['guardianId'] ?? _guardianData?['_id'];
      if (notif['guardianId'] == guardianIdStr) {
        _notifications.insert(0, notif);
        _unreadNotificationCount++;
        notifyListeners();
      }
    });
  }

  Future<void> _registerFCMToken(String guardianId) async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _guardianService.registerFcmToken(guardianId, token);
        }
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  Future<void> fetchGuardianData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final currentGuardianId = await SecureStorageService.getUserId();

      if (currentGuardianId == null) {
        _errorMessage = 'Session expired. Please log in again.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = await _guardianService.getGuardian(currentGuardianId);
      _guardianData = data;
      _assignedElders = data['assignedElders'] ?? [];
      _isSynced = true;

      _registerFCMToken(currentGuardianId);
      _initSocket();
      fetchUnreadNotificationCount();
      fetchNotifications();

      if (_assignedElders.isNotEmpty) {
        if (_selectedElderIndex >= _assignedElders.length) {
          _selectedElderIndex = 0;
        }
        await fetchElderAssessments(_assignedElders[_selectedElderIndex]['_id']);
      }
    } catch (e) {
      _errorMessage = 'Network error occurred while fetching data.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadNotificationCount() async {
    if (_guardianData == null) return;
    final guardianIdStr = _guardianData!['guardianId'] ?? _guardianData!['_id'];
    try {
      _unreadNotificationCount = await _notificationService.fetchUnreadCount(guardianIdStr);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  Future<void> fetchNotifications() async {
    if (_guardianData == null) return;
    final guardianIdStr = _guardianData!['guardianId'] ?? _guardianData!['_id'];
    try {
      _notifications = await _notificationService.fetchByGuardian(guardianIdStr);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n['_id'] == notificationId);
      if (index != -1) {
        if (_notifications[index]['isRead'] == false && _unreadNotificationCount > 0) {
          _unreadNotificationCount--;
        }
        _notifications.removeAt(index);
        notifyListeners();
      }
      await _notificationService.deleteNotification(notificationId);
    } catch (e) {
      debugPrint('Error processing notification read/delete: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n['_id'] == notificationId);
      if (index != -1) {
        if (_notifications[index]['isRead'] == false && _unreadNotificationCount > 0) {
          _unreadNotificationCount--;
        }
        _notifications.removeAt(index);
        notifyListeners();
      }
      await _notificationService.deleteNotification(notificationId);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    if (_guardianData == null) return;
    final guardianIdStr = _guardianData!['guardianId'] ?? _guardianData!['_id'];

    try {
      bool hasChanges = false;
      for (var notif in _notifications) {
        if (notif['isRead'] == false) {
          notif['isRead'] = true;
          hasChanges = true;
        }
      }
      if (hasChanges) {
        _unreadNotificationCount = 0;
        notifyListeners();
      }
      await _notificationService.markAllRead(guardianIdStr);
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  void navigateToReport(DateTime date, String residentId) {
    _targetReportDate = date;
    final elderIndex = _assignedElders.indexWhere((e) => e['_id'] == residentId);
    if (elderIndex != -1) {
      _selectedElderIndex = elderIndex;
      fetchElderAssessments(residentId);
    }
    notifyListeners();
  }

  void clearTargetReportDate() {
    _targetReportDate = null;
  }

  Future<void> fetchElderAssessments(String residentId) async {
    try {
      _assessments = await _assessmentService.fetchByResident(residentId);
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

  Future<bool> updateProfileInfo({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    String? birthday,
  }) async {
    if (_guardianData == null) return false;
    try {
      final String guardianId = _guardianData!['guardianId'];
      final Map<String, dynamic> updateData = {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        if (birthday != null && birthday.isNotEmpty) 'birthday': birthday,
      };
      final result = await _guardianService.updateGuardian(guardianId, updateData);
      _guardianData = result['guardian'] ?? result;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateEmergencyContact({
    required String name,
    required String phone,
    required String relationship,
  }) async {
    if (_guardianData == null) return false;
    try {
      final String guardianId = _guardianData!['guardianId'];
      final result = await _guardianService.updateGuardian(guardianId, {
        'emergencyContact': {'name': name, 'phone': phone, 'relationship': relationship},
      });
      _guardianData = result['guardian'] ?? result;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAppTheme(String theme) async {
    if (_guardianData == null) return false;
    try {
      final String guardianId = _guardianData!['guardianId'];
      final result = await _guardianService.updateGuardian(guardianId, {
        'firstName': _guardianData!['firstName'],
        'lastName': _guardianData!['lastName'],
        'email': _guardianData!['email'],
        'phone': _guardianData!['phone'] ?? '',
        'appTheme': theme,
      });
      _guardianData = result['guardian'] ?? result;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> uploadProfilePhoto(File imageFile) async {
    if (_guardianData == null) return false;
    try {
      final String guardianId = _guardianData!['guardianId'];
      final result = await _guardianService.uploadProfilePhoto(guardianId, imageFile);
      _guardianData!['profilePhoto'] = result['profilePhoto'];
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_guardianData == null) return false;
    try {
      await _guardianService.changePassword(
        guardianId: _guardianData!['guardianId'],
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendComment(String assessmentId, String text) async {
    if (_guardianData == null) return false;
    try {
      final String senderId = _guardianData!['guardianId'];
      final String senderName = '${_guardianData!['firstName']} ${_guardianData!['lastName']}';

      final int index = _assessments.indexWhere((a) => a['_id'] == assessmentId);
      if (index != -1) {
        _assessments[index]['comments'] ??= [];
        _assessments[index]['comments'].add({
          'senderId': senderId,
          'senderName': senderName,
          'senderRole': 'Guardian',
          'text': text,
          'createdAt': DateTime.now().toIso8601String(),
        });
        notifyListeners();
      }

      final result = await _assessmentService.addComment(assessmentId, {
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': 'Guardian',
        'text': text,
      });

      if (index != -1 && result['assessment'] != null) {
        _assessments[index] = result['assessment'];
        notifyListeners();
      }
      return true;
    } catch (e) {
      if (_assignedElders.isNotEmpty) {
        await fetchElderAssessments(_assignedElders[_selectedElderIndex]['_id']);
      }
      return false;
    }
  }

  Future<bool> sendReaction(String assessmentId, String reactionKey, bool isActive) async {
    if (_guardianData == null) return false;
    try {
      final int index = _assessments.indexWhere((a) => a['_id'] == assessmentId);
      if (index != -1) {
        _assessments[index]['reactions'] ??= {};
        _assessments[index]['reactions'][reactionKey] = isActive ? 1 : 0;
        notifyListeners();
      }

      final result = await _assessmentService.updateReactions(assessmentId, {reactionKey: isActive});

      if (index != -1 && result['assessment'] != null) {
        _assessments[index] = result['assessment'];
        notifyListeners();
      }
      return true;
    } catch (e) {
      if (_assignedElders.isNotEmpty) {
        await fetchElderAssessments(_assignedElders[_selectedElderIndex]['_id']);
      }
      return false;
    }
  }

  void clearData() {
    _guardianData = null;
    _assignedElders = [];
    _assessments = [];
    _notifications = [];
    _unreadNotificationCount = 0;
    _targetReportDate = null;
    _selectedElderIndex = 0;
    _isSynced = false;
    _errorMessage = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}