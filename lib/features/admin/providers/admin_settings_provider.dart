import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/secure_storage_service.dart';
import '../services/admin_api_service.dart';
import '../../nurse/services/nurse_api_service.dart';
import '../../guardian/services/guardian_api_service.dart';

class AdminSettingsProvider extends ChangeNotifier {
  final _adminService = AdminApiService();
  final _nurseService = NurseApiService();
  final _guardianService = GuardianApiService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _saveMessage;

  String _displayName = '';
  String _theme = 'default';
  bool _is2FAEnabled = false;
  String _linkedNurseId = '';
  bool _enableSidebarToggle = false;

  int _videoRetentionDays = 30;
  int _auditArchiveDays = 30;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get saveMessage => _saveMessage;

  String get displayName => _displayName;
  String get theme => _theme;
  bool get is2FAEnabled => _is2FAEnabled;
  String get linkedNurseId => _linkedNurseId;
  bool get enableSidebarToggle => _enableSidebarToggle;

  int get videoRetentionDays => _videoRetentionDays;
  int get auditArchiveDays => _auditArchiveDays;

  AdminSettingsProvider() {
    _loadLocalSettings();
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _enableSidebarToggle = prefs.getBool('enableSidebarToggle') ?? false;
    notifyListeners();
  }

  void _clearMessageLater() {
    Future.delayed(const Duration(seconds: 3), () {
      _saveMessage = null;
      notifyListeners();
    });
  }

  Future<void> resetState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('appTheme');
    await prefs.remove('enableSidebarToggle');

    _displayName = '';
    _theme = 'default';
    _is2FAEnabled = false;
    _linkedNurseId = '';
    _enableSidebarToggle = false;
    _errorMessage = null;
    _saveMessage = null;

    notifyListeners();
  }

  Future<void> fetchSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final settingsData = await _adminService.fetchSettings();
      if (settingsData['dataPrivacy'] != null) {
        final privacy = settingsData['dataPrivacy'];
        _videoRetentionDays = privacy['videoRetentionDays'] ?? 30;
        _auditArchiveDays = privacy['auditTrailRetentionDays'] ?? 30;
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = await SecureStorageService.getUserId();

      if (userId != null && userId.isNotEmpty) {
        Map<String, dynamic> profileData;

        if (userId.startsWith('N-')) {
          profileData = await _nurseService.getNurseProfile(userId);
        } else if (userId.startsWith('G-')) {
          profileData = await _guardianService.getGuardian(userId);
        } else {
          profileData = await _adminService.getAdminProfile(userId);
        }

        final userData = profileData['admin'] ?? profileData['nurse'] ?? profileData['guardian'] ?? profileData;

        if (userData['firstName'] != null && userData['lastName'] != null) {
          _displayName = '${userData['firstName']} ${userData['lastName']}';
        } else {
          _displayName = userData['name'] ?? '';
        }

        _theme = userData['theme'] ?? prefs.getString('appTheme_$userId') ?? prefs.getString('appTheme') ?? 'default';
        _is2FAEnabled = userData['is2FAEnabled'] ?? false;
        _linkedNurseId = userData['linkedNurseId'] ?? '';

        await prefs.setString('appTheme', _theme);
        await prefs.setString('appTheme_$userId', _theme);
      }
    } catch (e) {
      _errorMessage = 'Failed to load settings';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAdminProfile(String name, String themeSelection) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await SecureStorageService.getUserId() ?? '';
      final prefs = await SharedPreferences.getInstance();

      if (userId.startsWith('N-')) {
        await _nurseService.updateProfile(userId, {'name': name, 'theme': themeSelection});
      } else if (userId.startsWith('G-')) {
        await _guardianService.updateGuardian(userId, {'name': name, 'theme': themeSelection});
      } else {
        await _adminService.updateProfile(userId, {'name': name, 'theme': themeSelection});
      }

      _displayName = name;
      _theme = themeSelection;

      await prefs.setString('adminName', name);
      await prefs.setString('appTheme', themeSelection);
      await prefs.setString('appTheme_$userId', themeSelection);

      _saveMessage = 'Profile settings updated successfully!';
      _isLoading = false;
      notifyListeners();
      _clearMessageLater();
      return true;
    } catch (e) {
      _saveMessage = 'Error updating profile.';
    }
    _isLoading = false;
    notifyListeners();
    _clearMessageLater();
    return false;
  }

  Future<bool> changeAdminPassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await SecureStorageService.getUserId() ?? '';

      if (userId.startsWith('N-')) {
        await _nurseService.changePassword(userId, oldPassword, newPassword);
      } else if (userId.startsWith('G-')) {
        await _guardianService.changePassword(
          guardianId: userId,
          oldPassword: oldPassword,
          newPassword: newPassword,
        );
      } else {
        await _adminService.changePassword(userId, oldPassword, newPassword);
      }

      _saveMessage = 'Password changed successfully!';
      _isLoading = false;
      notifyListeners();
      _clearMessageLater();
      return true;
    } catch (e) {
      _saveMessage = 'Network error changing password.';
    }
    _isLoading = false;
    notifyListeners();
    _clearMessageLater();
    return false;
  }

  Future<bool> toggle2FA(bool enable, {String? pin}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await SecureStorageService.getUserId() ?? '';

      if (userId.startsWith('N-')) {
        _saveMessage = '2FA is managed globally by Administration.';
        _isLoading = false;
        notifyListeners();
        _clearMessageLater();
        return false;
      }

      await _adminService.toggle2FA(userId, enable, pin: pin);
      _is2FAEnabled = enable;
      _saveMessage = enable ? '2FA Enabled Successfully!' : '2FA Disabled Successfully.';
      _isLoading = false;
      notifyListeners();
      _clearMessageLater();
      return true;
    } catch (e) {
      _saveMessage = 'Error toggling 2FA.';
    }
    _isLoading = false;
    notifyListeners();
    _clearMessageLater();
    return false;
  }

  Future<bool> linkNurseAccount(String nurseId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await SecureStorageService.getUserId() ?? '';

      if (userId.startsWith('N-')) {
        _saveMessage = 'Not authorized to link accounts.';
        _isLoading = false;
        notifyListeners();
        _clearMessageLater();
        return false;
      }

      final result = await _adminService.linkNurse(userId, nurseId);
      _linkedNurseId = result['linkedNurseId'] ?? nurseId;
      _saveMessage = 'Nurse account linked successfully!';
      _isLoading = false;
      notifyListeners();
      _clearMessageLater();
      return true;
    } catch (e) {
      _saveMessage = 'Network error linking nurse.';
    }
    _isLoading = false;
    notifyListeners();
    _clearMessageLater();
    return false;
  }

  Future<bool> unlinkNurseAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await SecureStorageService.getUserId() ?? '';

      if (userId.startsWith('N-')) {
        _saveMessage = 'Not authorized to unlink accounts.';
        _isLoading = false;
        notifyListeners();
        _clearMessageLater();
        return false;
      }

      await _adminService.unlinkNurse(userId);
      _linkedNurseId = '';
      _enableSidebarToggle = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('enableSidebarToggle', false);

      _saveMessage = 'Nurse account unlinked.';
      _isLoading = false;
      notifyListeners();
      _clearMessageLater();
      return true;
    } catch (e) {
      _saveMessage = 'Network error.';
    }
    _isLoading = false;
    notifyListeners();
    _clearMessageLater();
    return false;
  }

  Future<bool> toggleSidebarFeature(bool value) async {
    _enableSidebarToggle = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableSidebarToggle', value);
    return true;
  }

  Future<bool> deactivateAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await SecureStorageService.getUserId() ?? '';

      if (userId.startsWith('N-')) {
        _saveMessage = 'Account deactivation requires Administrator approval.';
        _isLoading = false;
        notifyListeners();
        _clearMessageLater();
        return false;
      }

      await _adminService.deactivateAccount(userId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _saveMessage = 'Network error.';
    }
    _isLoading = false;
    notifyListeners();
    _clearMessageLater();
    return false;
  }
}