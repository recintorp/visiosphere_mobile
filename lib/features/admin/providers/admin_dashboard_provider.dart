import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../admin/services/admin_api_service.dart';
import '../../audit/services/audit_api_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cctv/providers/cctv_provider.dart';
import '../../incident/services/incident_api_service.dart';
import '../../notification/services/notification_api_service.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final _adminService        = AdminApiService();
  final _auditService        = AuditApiService();
  final _incidentService     = IncidentApiService();
  final _notificationService = NotificationApiService();

  int _totalElders   = 0;
  int _activeNurses  = 0;
  int _alertsToday   = 0;
  // Nullable, and it starts null. This was `int _camerasOnline = 2` with a
  // `?? 2` fallback on the parse below, so the app claimed both cameras were
  // online before it had asked anything, and again whenever the answer was
  // missing. "I don't know" and "everything is fine" are different states and
  // a monitoring product must never round the first into the second.
  int? _camerasOnline;

  int? _eldersDelta;
  int? _nursesDelta;
  int? _alertsDelta;
  String? _eldersTrend;
  String? _nursesTrend;
  String? _alertsTrend;

  List<dynamic> _weeklyStats   = [];
  bool          _weeklyLoading = false;
  String?       _weeklyError;

  String? _nurseName;
  String? _nurseId;
  String? _nurseRole;
  String? _nurseProfilePic;

  List<dynamic> _recentActivities = [];
  bool    _isLoading    = true;
  String? _errorMessage;

  int  get totalElders   => _totalElders;
  int  get activeNurses  => _activeNurses;
  int  get alertsToday   => _alertsToday;
  /// Cameras confirmed to be delivering frames, or null when the AI core
  /// could not be reached. Null means UNKNOWN — never render it as a number.
  int? get camerasOnline => _camerasOnline;

  int?    get eldersDelta  => _eldersDelta;
  int?    get nursesDelta  => _nursesDelta;
  int?    get alertsDelta  => _alertsDelta;
  String? get eldersTrend  => _eldersTrend;
  String? get nursesTrend  => _nursesTrend;
  String? get alertsTrend  => _alertsTrend;

  List<dynamic> get weeklyStats      => _weeklyStats;
  bool          get weeklyLoading    => _weeklyLoading;
  String?       get weeklyError      => _weeklyError;
  List<dynamic> get recentActivities => _recentActivities;
  bool          get isLoading        => _isLoading;
  String?       get errorMessage     => _errorMessage;
  String?       get nurseName        => _nurseName;

  /// Adopt a display name the nurse just saved in System Settings.
  ///
  /// The nurse dashboard greets with [nurseName] in preference to
  /// AuthProvider.userName, so updating AuthProvider alone would still leave a
  /// nurse looking at the old name. The server is the source of truth and
  /// refetches on the next dashboard load — this only closes the gap in
  /// between, which is exactly where the bug was visible.
  void setNurseName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed == _nurseName) return;
    _nurseName = trimmed;
    notifyListeners();
  }
  String?       get nurseId          => _nurseId;
  String?       get nurseRole        => _nurseRole;
  String?       get nurseProfilePic  => _nurseProfilePic;

  void incrementAlertsToday() { _alertsToday++; notifyListeners(); }

  String _currentWeekStart() {
    final now    = DateTime.now();
    final sunday = now.subtract(Duration(days: now.weekday % 7));
    return '${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}';
  }

  Future<void> _registerAdminFcmToken(String customId) async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) await _notificationService.registerAdminFcmToken(customId, token);
      }
    } catch (e) { debugPrint('Error registering admin FCM token: $e'); }
  }

  Future<void> _registerNurseFcmToken(String nurseId) async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) await _notificationService.registerNurseFcmToken(nurseId, token);
      }
    } catch (e) { debugPrint('Error registering nurse FCM token: $e'); }
  }

  Future<void> fetchDashboardData({
    bool isNurseView = false,
    String? userId,
    String? userRole,
    CctvProvider? cctvProvider,
  }) async {
    _isLoading       = true;
    _errorMessage    = null;
    _nurseName       = null;
    _nurseId         = null;
    _nurseRole       = null;
    _nurseProfilePic = null;
    notifyListeners();

    if (cctvProvider != null) {
      cctvProvider.fetchInitialData();
      cctvProvider.initSocket();
    }

    final isStandaloneNurse = isNurseView && userRole == 'Nurse';
    final isLinkedNurse     = isNurseView && userRole == 'Facility Admin' && userId != null;

    try {
      final futures = <Future>[
        _adminService.fetchDashboardStats(),
        _auditService.fetchAuditLogs(),
        if (isLinkedNurse)   _adminService.fetchLinkedNurseProfile(userId),
        if (isStandaloneNurse && userId != null) _adminService.fetchStandaloneNurseProfile(userId),
      ];

      final results = await Future.wait(futures);

      final statsData   = results[0] as Map<String, dynamic>;
      final eldersData  = statsData['elders']  as Map<String, dynamic>? ?? {};
      final nursesData  = statsData['nurses']  as Map<String, dynamic>? ?? {};
      final alertsData  = statsData['alerts']  as Map<String, dynamic>? ?? {};
      final camerasData = statsData['cameras'] as Map<String, dynamic>? ?? {};

      _totalElders   = (eldersData['current']  as num?)?.toInt() ?? 0;
      _activeNurses  = (nursesData['current']  as num?)?.toInt() ?? 0;
      _alertsToday   = (alertsData['current']  as num?)?.toInt() ?? 0;
      _camerasOnline = (camerasData['online']  as num?)?.toInt();

      _eldersDelta = (eldersData['delta'] as num?)?.toInt();
      _nursesDelta = (nursesData['delta'] as num?)?.toInt();
      _alertsDelta = (alertsData['delta'] as num?)?.toInt();
      _eldersTrend = eldersData['trend'] as String?;
      _nursesTrend = nursesData['trend'] as String?;
      _alertsTrend = alertsData['trend'] as String?;

      _recentActivities = (results[1] as List<dynamic>).take(4).toList();

      if (isLinkedNurse && results.length > 2) {
        final nd = results[2] as Map<String, dynamic>;
        // Not firstName + lastName: that ignored the name the nurse saved
        // in System Settings, so the dashboard greeted her by her old one
        // forever. One rule, shared with the server — see
        // AuthProvider.resolveName and backend/models/Nurse.js.
        //
        // Only ACCEPT a real answer: an unexpected response shape resolves to
        // '' and would replace a good name with a blank header.
        final resolved = AuthProvider.resolveName(nd);
        if (resolved.isNotEmpty) _nurseName = resolved;
        _nurseId = nd['nurseId']; _nurseRole = 'Nurse'; _nurseProfilePic = nd['profilePic'];
        _registerNurseFcmToken(_nurseId!);
      }

      if (isStandaloneNurse && results.length > 2) {
        final nd = results[2] as Map<String, dynamic>;
        // Not firstName + lastName: that ignored the name the nurse saved
        // in System Settings, so the dashboard greeted her by her old one
        // forever. One rule, shared with the server — see
        // AuthProvider.resolveName and backend/models/Nurse.js.
        //
        // Only ACCEPT a real answer: an unexpected response shape resolves to
        // '' and would replace a good name with a blank header.
        final resolved = AuthProvider.resolveName(nd);
        if (resolved.isNotEmpty) _nurseName = resolved;
        _nurseId = nd['nurseId']; _nurseRole = 'Nurse'; _nurseProfilePic = nd['profilePic'];
        _registerNurseFcmToken(_nurseId!);
      }

      if (!isNurseView && userId != null) _registerAdminFcmToken(userId);

      _errorMessage = null;
    } catch (e) {
      debugPrint('Dashboard Error: $e');
      _errorMessage  = 'Secure connection timeout. Verify network status.';
      _totalElders   = 0; _activeNurses = 0; _alertsToday = 0;
      // Null, not 0. The request failed, so we know nothing about the
      // cameras — reporting zero online would be as wrong as reporting two.
      _camerasOnline = null; _recentActivities = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    await fetchWeeklyStats();
  }

  Future<void> fetchWeeklyStats() async {
    _weeklyLoading = true;
    _weeklyError   = null;
    notifyListeners();
    try {
      _weeklyStats = await _incidentService.fetchWeeklyStats(
        weekStart: _currentWeekStart(),
        // Was DateTime.now().timeZoneName (invalid to Mongo, 500s), then 'UTC'
        // (valid, but buckets by UTC days — so an 07:00 Manila alert counted on
        // the previous day and this chart disagreed with the web dashboard by
        // eight hours). The device offset is what the web already sends.
        tz: ApiConstants.deviceTimeZone,
      );
      _weeklyError = null;
    } catch (e) {
      debugPrint('Weekly stats error: $e');
      _weeklyError = 'Could not load chart data.';
      _weeklyStats = [];
    } finally {
      _weeklyLoading = false;
      notifyListeners();
    }
  }

  void retry({bool isNurseView = false, String? userId, String? userRole, CctvProvider? cctvProvider}) {
    fetchDashboardData(isNurseView: isNurseView, userId: userId, userRole: userRole, cctvProvider: cctvProvider);
  }
}