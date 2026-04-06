import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AdminSettingsProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _saveMessage;

  List<Map<String, dynamic>> _zones = [];
  String _morningShift = '06:00';
  String _afternoonShift = '14:00';
  String _nightShift = '22:00';

  int _fallSensitivity = 75;
  double _thermalThreshold = 38.0;
  int _inactivityTimer = 15;

  bool _smsEnabled = true;
  bool _emergencyBroadcast = false;
  int _guardianDelay = 2;

  int _videoRetentionDays = 30;
  int _auditArchiveDays = 90;

  bool _enableSidebarToggle = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get saveMessage => _saveMessage;

  List<Map<String, dynamic>> get zones => _zones;
  String get morningShift => _morningShift;
  String get afternoonShift => _afternoonShift;
  String get nightShift => _nightShift;

  int get fallSensitivity => _fallSensitivity;
  double get thermalThreshold => _thermalThreshold;
  int get inactivityTimer => _inactivityTimer;

  bool get smsEnabled => _smsEnabled;
  bool get emergencyBroadcast => _emergencyBroadcast;
  int get guardianDelay => _guardianDelay;

  int get videoRetentionDays => _videoRetentionDays;
  int get auditArchiveDays => _auditArchiveDays;

  bool get enableSidebarToggle => _enableSidebarToggle;

  AdminSettingsProvider() {
    _loadLocalSettings();
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _enableSidebarToggle = prefs.getBool('enableSidebarToggle') ?? false;
    notifyListeners();
  }

  String _parseTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    try {
      final parts = timeStr.split(' ');
      final timeParts = parts[0].split(':');
      int hours = int.parse(timeParts[0]);
      final minutes = timeParts[1];
      if (parts.length > 1) {
        final modifier = parts[1].toUpperCase();
        if (hours == 12) hours = 0;
        if (modifier == 'PM') hours += 12;
      }
      return '${hours.toString().padLeft(2, '0')}:$minutes';
    } catch (e) {
      return timeStr;
    }
  }

  String _formatTime(String time24) {
    if (time24.isEmpty) return '';
    try {
      final parts = time24.split(':');
      int hours = int.parse(parts[0]);
      final minutes = parts[1];
      final modifier = hours >= 12 ? 'PM' : 'AM';
      int hours12 = hours % 12;
      if (hours12 == 0) hours12 = 12;
      return '${hours12.toString().padLeft(2, '0')}:$minutes $modifier';
    } catch (e) {
      return time24;
    }
  }

  Future<void> fetchSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ApiService.fetchSettings();
      if (result['success']) {
        final data = result['data'];

        if (data['facilityConfiguration'] != null) {
          final facility = data['facilityConfiguration'];
          if (facility['zones'] != null) {
            _zones = List<Map<String, dynamic>>.from(facility['zones']);
          }
          if (facility['shiftTimings'] != null) {
            final timings = facility['shiftTimings'];
            _morningShift = _parseTime(timings['morningStart'] ?? '06:00 AM');
            _afternoonShift = _parseTime(timings['afternoonStart'] ?? '02:00 PM');
            _nightShift = _parseTime(timings['nightStart'] ?? '10:00 PM');
          }
        }

        if (data['aiThresholds'] != null) {
          final ai = data['aiThresholds'];
          _fallSensitivity = ai['fallSensitivity'] ?? 75;
          _thermalThreshold = (ai['thermalThreshold'] ?? 38.0).toDouble();
          _inactivityTimer = ai['inactivityTimerMinutes'] ?? 15;
        }

        if (data['notifications'] != null) {
          final notifs = data['notifications'];
          _smsEnabled = notifs['smsEnabled'] ?? true;
          _emergencyBroadcast = notifs['emergencyBroadcastActive'] ?? false;
          _guardianDelay = notifs['guardianNotificationDelayMinutes'] ?? 2;
        }

        if (data['dataPrivacy'] != null) {
          final privacy = data['dataPrivacy'];
          _videoRetentionDays = privacy['videoRetentionDays'] ?? 30;
          _auditArchiveDays = privacy['auditTrailRetentionDays'] ?? 90;
        }
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = 'Failed to load settings';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveSettings() async {
    _isLoading = true;
    _saveMessage = null;
    notifyListeners();

    final payload = {
      'facilityConfiguration': {
        'zones': _zones,
        'shiftTimings': {
          'morningStart': _formatTime(_morningShift),
          'afternoonStart': _formatTime(_afternoonShift),
          'nightStart': _formatTime(_nightShift),
        }
      },
      'aiThresholds': {
        'fallSensitivity': _fallSensitivity,
        'thermalThreshold': _thermalThreshold,
        'inactivityTimerMinutes': _inactivityTimer,
      },
      'notifications': {
        'smsEnabled': _smsEnabled,
        'emergencyBroadcastActive': _emergencyBroadcast,
        'guardianNotificationDelayMinutes': _guardianDelay,
      },
      'dataPrivacy': {
        'videoRetentionDays': _videoRetentionDays,
        'auditTrailRetentionDays': _auditArchiveDays,
      }
    };

    try {
      final result = await ApiService.updateSettings(payload);
      if (result['success']) {
        _saveMessage = 'Settings saved successfully!';
        _isLoading = false;
        notifyListeners();
        Future.delayed(const Duration(seconds: 3), () {
          _saveMessage = null;
          notifyListeners();
        });
        return true;
      } else {
        _saveMessage = 'Error saving settings: ${result['message']}';
      }
    } catch (e) {
      _saveMessage = 'Error saving settings. Please try again.';
    }
    
    _isLoading = false;
    notifyListeners();
    Future.delayed(const Duration(seconds: 3), () {
      _saveMessage = null;
      notifyListeners();
    });
    return false;
  }

  void addZone(String name) {
    if (name.trim().isEmpty) return;
    _zones.add({
      'name': name.trim(),
      'description': '${name.trim()} Area',
    });
    notifyListeners();
  }

  void removeZone(int index) {
    if (index >= 0 && index < _zones.length) {
      _zones.removeAt(index);
      notifyListeners();
    }
  }

  void updateShift(String shift, String time24) {
    if (shift == 'morning') _morningShift = time24;
    if (shift == 'afternoon') _afternoonShift = time24;
    if (shift == 'night') _nightShift = time24;
    notifyListeners();
  }

  void updateAiSetting(String setting, dynamic value) {
    if (setting == 'fallSensitivity') _fallSensitivity = value as int;
    if (setting == 'thermalThreshold') _thermalThreshold = (value as num).toDouble();
    if (setting == 'inactivityTimer') _inactivityTimer = value as int;
    notifyListeners();
  }

  void updateNotificationSetting(String setting, dynamic value) {
    if (setting == 'smsEnabled') _smsEnabled = value as bool;
    if (setting == 'emergencyBroadcast') _emergencyBroadcast = value as bool;
    if (setting == 'guardianDelay') _guardianDelay = value as int;
    notifyListeners();
  }

  void updateDataSetting(String setting, int value) {
    if (setting == 'videoRetentionDays') _videoRetentionDays = value;
    if (setting == 'auditArchiveDays') _auditArchiveDays = value;
    notifyListeners();
  }

  Future<void> toggleSidebarFeature(bool value) async {
    _enableSidebarToggle = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableSidebarToggle', value);
  }
}