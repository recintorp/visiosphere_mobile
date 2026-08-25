import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/api_constants.dart';
import '../../incident/services/incident_api_service.dart';
import '../services/stream_api_service.dart';

class CctvCamera {
  final String cameraId;
  final String name;
  final String location;
  final String status;
  /// URL-encoded path segment on the AI core (e.g. 'House%20of%20Charbel').
  /// Null for cameras with no live feed. The full URL (base + signed token) is
  /// built on demand by CctvProvider.streamUrlFor().
  final String? streamPath;
  CctvCamera({
    required this.cameraId,
    required this.name,
    required this.location,
    required this.status,
    this.streamPath,
  });
}

class CctvAlert {
  final String id;
  final String rawType;
  final String module;
  final String label;
  final String severity;
  final String camera;
  final String message;
  final String timestamp;
  String status;
  CctvAlert({
    required this.id,
    required this.rawType,
    required this.module,
    required this.label,
    required this.severity,
    required this.camera,
    required this.message,
    required this.timestamp,
    this.status = 'Unresolved',
  });
}

class CctvProvider extends ChangeNotifier {
  io.Socket? _socket;
  bool _socketListenersAttached = false;
  final _incidentService = IncidentApiService();
  final _streamService = StreamApiService();

  // Signed stream token + resolved base, refreshed before expiry.
  StreamToken? _streamToken;
  String _streamBase = ApiConstants.streamBaseUrl;
  Timer? _streamRefreshTimer;
  bool _fetchingToken = false;

  final AudioPlayer _emergencyPlayer = AudioPlayer();
  final AudioPlayer _warningPlayer = AudioPlayer();
  AudioPlayer? _activePlayer;
  Timer? _cutoffTimer;
  bool _isPlaying = false;
  double _volume = 1.0;

  final List<CctvCamera> _cameras = [
    CctvCamera(
      cameraId: 'CAM-001',
      name: 'House of Charbel',
      location: 'Webcam · Cam 0',
      status: 'Active',
      streamPath: 'House%20of%20Charbel',
    ),
    CctvCamera(
      cameraId: 'CAM-002',
      name: 'House of Gabriel',
      location: 'IP Camera · Phone Stream',
      status: 'Active',
      streamPath: 'House%20of%20Gabriel',
    ),
    CctvCamera(
      cameraId: 'CAM-003',
      name: 'Future CCTV 1',
      location: 'Pending Installation',
      status: 'Inactive',
    ),
    CctvCamera(
      cameraId: 'CAM-004',
      name: 'Future CCTV 2',
      location: 'Pending Installation',
      status: 'Inactive',
    ),
  ];

  String _selectedCameraId = 'OVERALL';
  String _filterModule = 'All';
  List<CctvAlert> _alerts = [];
  final Map<String, String> _realTimeStatuses = {};
  CctvAlert? _activeToast;

  int _unreadCount = 0;
  List<Map<String, dynamic>> _weeklyStats = [];
  bool _isLoading = true;
  String? _errorMessage;

  List<CctvCamera> get cameras => _cameras;
  String get selectedCameraId => _selectedCameraId;
  String get filterModule => _filterModule;
  List<CctvAlert> get alerts => _alerts;
  Map<String, String> get realTimeStatuses => _realTimeStatuses;
  CctvAlert? get activeToast => _activeToast;
  int get unreadCount => _unreadCount;
  List<Map<String, dynamic>> get weeklyStats => _weeklyStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  CctvCamera? get selectedCamera => _selectedCameraId == 'OVERALL'
      ? null
      : _cameras.firstWhere(
          (c) => c.cameraId == _selectedCameraId,
          orElse: () => _cameras.first,
        );

  List<CctvAlert> get filteredAlerts {
    if (_filterModule == 'All') return _alerts;
    if (_filterModule == 'Unresolved') {
      return _alerts.where((a) => a.status == 'Unresolved').toList();
    }
    return _alerts.where((a) => a.module == _filterModule).toList();
  }

  /// True once a valid stream token exists and feeds can be rendered.
  bool get streamReady =>
      _streamToken != null || ApiConstants.streamDebugKey.isNotEmpty;

  /// Full MJPEG URL for a camera.
  /// - Normal: appends the backend-minted ?token=.
  /// - Debug (STREAM_DEBUG_KEY set): appends the AI core's legacy ?key= and
  ///   skips the token requirement, to isolate token vs transport issues.
  /// Returns null when the camera has no feed or no token is available yet.
  String? streamUrlFor(CctvCamera camera) {
    final path = camera.streamPath;
    if (path == null) return null;
    if (ApiConstants.streamDebugKey.isNotEmpty) {
      return '$_streamBase/$path?key=${ApiConstants.streamDebugKey}';
    }
    if (_streamToken == null) return null;
    return '$_streamBase/$path?token=${_streamToken!.token}';
  }

  /// Ensure a non-expired stream token exists. Fetches one if missing/expiring
  /// and (re)arms a proactive refresh timer. Safe to call repeatedly.
  Future<void> ensureStreamToken({bool force = false}) async {
    if (_fetchingToken) return;
    final current = _streamToken;
    if (!force && current != null && !current.isExpiring) return;

    _fetchingToken = true;
    try {
      final token = await _streamService.fetchStreamToken();
      _streamToken = token;
      if (token.streamBase != null && token.streamBase!.isNotEmpty) {
        _streamBase = token.streamBase!.replaceAll(RegExp(r'/$'), '');
      }
      _scheduleStreamRefresh(token.expiresIn);
      debugPrint('[Stream] token OK — base=$_streamBase, expiresIn=${token.expiresIn}s, token=${token.token}');
      notifyListeners();
    } catch (e) {
      debugPrint('[Stream] Failed to fetch stream token: $e');
    } finally {
      _fetchingToken = false;
    }
  }

  void _scheduleStreamRefresh(int expiresIn) {
    _streamRefreshTimer?.cancel();
    // Refresh ~30s before expiry so an active feed never drops on a stale token.
    final lead = (expiresIn - 30).clamp(15, 86400);
    _streamRefreshTimer = Timer(Duration(seconds: lead), () {
      ensureStreamToken(force: true);
    });
  }

  CctvProvider() {
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _emergencyPlayer.setSource(AssetSource('sounds/emergency.mp3'));
    await _warningPlayer.setSource(AssetSource('sounds/warning.mp3'));
    _emergencyPlayer.onPlayerComplete.listen((_) => _clearAudioLock());
    _warningPlayer.onPlayerComplete.listen((_) => _clearAudioLock());
  }

  void setVolume(double newVolume) {
    _volume = newVolume.clamp(0.0, 1.0);
    _emergencyPlayer.setVolume(_volume);
    _warningPlayer.setVolume(_volume);
    notifyListeners();
  }

  void _playAlertSound(String severity) {
    if (_activePlayer != null) return;
    _activePlayer = severity == 'Emergency' ? _emergencyPlayer : _warningPlayer;
    _activePlayer!.setVolume(_volume);
    _activePlayer!.resume();
    _isPlaying = true;
    notifyListeners();
    _cutoffTimer = Timer(const Duration(seconds: 5), () {
      _activePlayer?.pause();
      _activePlayer?.seek(Duration.zero);
      _clearAudioLock();
    });
  }

  void _clearAudioLock() {
    _activePlayer = null;
    _isPlaying = false;
    _cutoffTimer?.cancel();
    notifyListeners();
  }

  String _currentWeekStart() {
    final now = DateTime.now();
    final sunday = now.subtract(Duration(days: now.weekday % 7));
    return '${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}';
  }

  Future<void> fetchInitialData() async {
    _isLoading = true;
    notifyListeners();
    // Mint the stream token in parallel; feeds render as soon as it lands.
    unawaited(ensureStreamToken());
    try {
      final results = await Future.wait([
        _incidentService.fetchIncidents(),
        _incidentService.fetchUnreadCount(),
        _incidentService.fetchWeeklyStats(
          weekStart: _currentWeekStart(),
          tz: 'UTC',
        ),
      ]);
      _alerts = (results[0] as List<dynamic>)
          .map((d) => _parseServerIncident(d))
          .toList();
      _unreadCount = results[1] as int;
      _weeklyStats = List<Map<String, dynamic>>.from(
        results[2] as List<dynamic>? ?? [],
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load CCTV data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void initSocket() {
    _socket ??= io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(99999)
          .setReconnectionDelay(2000)
          .build(),
    );

    if (!_socketListenersAttached) {
      _socketListenersAttached = true;
      _socket!.onConnect(
        (_) => debugPrint('[Socket] Connected to VisioSphere Event Socket'),
      );
      _socket!.onDisconnect(
        (_) => debugPrint('[Socket] Disconnected — will auto-reconnect'),
      );
      _socket!.onReconnect(
        (_) => debugPrint('[Socket] Reconnected to VisioSphere Event Socket'),
      );
      _socket!.on(ApiConstants.socketEventAlert, (data) {
        if (data != null) _handleIncomingAlert(data);
      });
    }

    if (!(_socket!.connected)) _socket!.connect();
  }

  void disposeSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _socketListenersAttached = false;
  }

  void setFilterModule(String module) {
    _filterModule = module;
    notifyListeners();
  }

  void selectCamera(String cameraId) {
    _selectedCameraId = cameraId;
    notifyListeners();
  }

  void handleFcmAlert(Map<String, dynamic> payload) {
    _handleIncomingAlert(payload);
  }

  void _handleIncomingAlert(dynamic data) {
    final location = data['location'] as String? ?? 'Unknown';
    final message = data['message'] ?? data['rawMessage'] ?? data['description'] ?? 'Alert';
    final rawType = data['type'] ?? data['severity'] ?? 'INFO';

    _realTimeStatuses[location] = message as String;

    final newAlert = _parseServerIncident(data);
    final existingIndex = _alerts.indexWhere((a) => a.id == newAlert.id);

    if (existingIndex >= 0) {
      _alerts[existingIndex] = newAlert;
    } else {
      _alerts.insert(0, newAlert);
      if (newAlert.status == 'Unresolved') _unreadCount++;
    }

    if (rawType != 'INFO' && rawType != 'Info') {
      _activeToast = newAlert;
      Future.delayed(const Duration(seconds: 6), () {
        if (_activeToast?.id == newAlert.id) clearActiveToast();
      });
      _playAlertSound(newAlert.severity);
    }

    notifyListeners();
  }

  CctvAlert _parseServerIncident(dynamic data) {
    final message = data['message'] ?? data['rawMessage'] ?? data['description'] ?? 'Alert';
    final rawType = data['type'] ??
        (data['severity'] == 'Emergency'
            ? 'EMERGENCY'
            : data['severity'] == 'Warning'
                ? 'WARNING'
                : 'INFO');
    final combined = '$message $rawType'.toUpperCase();

    String module = '?', label = 'Alert', severity = 'Low';

    if (combined.contains('FALL DETECTED')) {
      module = 'Fall';
      label = 'Fall Detected';
      severity = 'High';
    } else if (combined.contains('PROLONGED FALL')) {
      module = 'Fall';
      label = 'Prolonged Fall';
      severity = 'High';
    } else if (combined.contains('AGITATION_RISK') || combined.contains('AGITATION')) {
      module = 'Agitation';
      label = 'Agitation Risk';
      severity = 'Medium';
    } else if (combined.contains('PACING')) {
      module = 'Pacing';
      label = 'Pacing Detected';
      severity = 'Medium';
    } else if (combined.contains('INACTIVE') || combined.contains('INACTIVITY')) {
      module = 'Inactivity';
      label = 'Inactivity';
      severity = 'Medium';
    } else if (combined.contains('LYING DOWN')) {
      module = 'Lying Down';
      label = 'Lying Down';
      severity = 'Low';
    } else if (combined.contains('STUMBLE')) {
      module = 'Fall';
      label = 'Stumble Detected';
      severity = 'Low';
    }

    return CctvAlert(
      id: data['_id'] ?? data['id'] ?? data['incidentId'] ?? 'local-${DateTime.now().millisecondsSinceEpoch}',
      rawType: rawType as String,
      module: module,
      label: label,
      severity: severity,
      camera: data['location'] ?? 'Unknown',
      message: message as String,
      timestamp: data['timestamp'] ??
          (data['createdAt'] != null
              ? _formatDate(data['createdAt'] as String)
              : DateTime.now().toIso8601String()),
      status: data['acknowledged'] == true ? 'Resolved' : 'Unresolved',
    );
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
  }

  Future<void> acknowledgeAlert(String id, String? userId) async {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index >= 0) {
      _alerts[index].status = 'Resolved';
      if (_unreadCount > 0) _unreadCount--;
      notifyListeners();
    }
    if (!id.startsWith('local-')) await _incidentService.acknowledgeIncident(id);
  }

  Future<void> dismissAlert(String id, String? userId) async {
    final index = _alerts.indexWhere((a) => a.id == id);
    if (index >= 0) {
      if (_alerts[index].status == 'Unresolved' && _unreadCount > 0) {
        _unreadCount--;
      }
    }
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
    if (!id.startsWith('local-')) await _incidentService.dismissIncident(id);
  }

  void clearActiveToast() {
    _activeToast = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cutoffTimer?.cancel();
    _streamRefreshTimer?.cancel();
    _emergencyPlayer.dispose();
    _warningPlayer.dispose();
    disposeSocket();
    super.dispose();
  }
}