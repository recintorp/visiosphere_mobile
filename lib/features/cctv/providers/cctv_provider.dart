import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:audioplayers/audioplayers.dart';
import '../../../core/constants/api_constants.dart';
import '../../incident/services/incident_api_service.dart';

class CctvCamera {
  final String cameraId;
  final String name;
  final String location;
  final String status;
  final String? url;

  CctvCamera({
    required this.cameraId,
    required this.name,
    required this.location,
    required this.status,
    this.url,
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
  static const String _streamBaseUrl = 'http://10.0.2.2:5001';

  io.Socket? _socket;
  final _incidentService = IncidentApiService();

  final AudioPlayer _emergencyPlayer = AudioPlayer();
  final AudioPlayer _warningPlayer   = AudioPlayer();
  AudioPlayer? _activePlayer;
  Timer? _cutoffTimer;
  bool   _isPlaying = false;
  double _volume    = 1.0;

  final List<CctvCamera> _cameras = [
    CctvCamera(
      cameraId: 'CAM-001',
      name:     'House of Charbel',
      location: 'Webcam · Cam 0',
      status:   'Active',
      url:      '$_streamBaseUrl/video_feed/House%20of%20Charbel',
    ),
    CctvCamera(
      cameraId: 'CAM-002',
      name:     'House of Gabriel',
      location: 'IP Camera · Phone Stream',
      status:   'Active',
      url:      '$_streamBaseUrl/video_feed/House%20of%20Gabriel',
    ),
    CctvCamera(
      cameraId: 'CAM-003',
      name:     'Future CCTV 1',
      location: 'Pending Installation',
      status:   'Inactive',
    ),
    CctvCamera(
      cameraId: 'CAM-004',
      name:     'Future CCTV 2',
      location: 'Pending Installation',
      status:   'Inactive',
    ),
  ];

  String             _selectedCameraId = 'OVERALL';
  String             _filterModule     = 'All';
  List<CctvAlert>    _alerts           = [];
  final Map<String, String> _realTimeStatuses = {};
  CctvAlert?         _activeToast;

  int                          _unreadCount  = 0;
  List<Map<String, dynamic>>   _weeklyStats  = [];
  bool                         _isLoading    = true;
  String?                      _errorMessage;

  List<CctvCamera>           get cameras           => _cameras;
  String                     get selectedCameraId  => _selectedCameraId;
  String                     get filterModule      => _filterModule;
  List<CctvAlert>            get alerts            => _alerts;
  Map<String, String>        get realTimeStatuses  => _realTimeStatuses;
  CctvAlert?                 get activeToast       => _activeToast;
  int                        get unreadCount       => _unreadCount;
  List<Map<String, dynamic>> get weeklyStats       => _weeklyStats;
  bool                       get isLoading         => _isLoading;
  String?                    get errorMessage      => _errorMessage;
  bool                       get isPlaying         => _isPlaying;
  double                     get volume            => _volume;

  CctvCamera? get selectedCamera => _selectedCameraId == 'OVERALL'
      ? null
      : _cameras.firstWhere((c) => c.cameraId == _selectedCameraId,
            orElse: () => _cameras.first);

  List<CctvAlert> get filteredAlerts {
    if (_filterModule == 'All')         return _alerts;
    if (_filterModule == 'Unresolved')  return _alerts.where((a) => a.status == 'Unresolved').toList();
    return _alerts.where((a) => a.module == _filterModule).toList();
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
    _isPlaying    = false;
    _cutoffTimer?.cancel();
    notifyListeners();
  }

  String _currentWeekStart() {
    final now    = DateTime.now();
    final sunday = now.subtract(Duration(days: now.weekday % 7));
    return '${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}';
  }

  Future<void> fetchInitialData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _incidentService.fetchIncidents(),
        _incidentService.fetchUnreadCount(),
        _incidentService.fetchWeeklyStats(
          weekStart: _currentWeekStart(),
          tz:        DateTime.now().timeZoneName,
        ),
      ]);

      _alerts = (results[0] as List<dynamic>)
          .map((data) => _parseServerIncident(data))
          .toList();

      _unreadCount = results[1] as int;

      _weeklyStats = List<Map<String, dynamic>>.from(
          results[2] as List<dynamic>? ?? []);

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load CCTV data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void initSocket() {
    if (_socket != null) return;

    _socket = io.io(
      ApiConstants.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket?.onConnect((_) {
      debugPrint('Connected to VisioSphere Event Socket');
    });

    _socket?.on(ApiConstants.socketEventAlert, (data) {
      if (data != null) _handleIncomingAlert(data);
    });

    _socket?.connect();
  }

  void disposeSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
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
    final message  = data['message'] ?? data['rawMessage'] ?? data['description'] ?? 'Alert';
    final rawType  = data['type'] ?? data['severity'] ?? 'INFO';

    _realTimeStatuses[location] = message;

    final newAlert      = _parseServerIncident(data);
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
    final message  = data['message'] ?? data['rawMessage'] ?? data['description'] ?? 'Alert';
    final rawType  = data['type'] ??
        (data['severity'] == 'Emergency'
            ? 'EMERGENCY'
            : data['severity'] == 'Warning'
                ? 'WARNING'
                : 'INFO');
    final combined = '$message $rawType'.toUpperCase();

    String module   = '?';
    String label    = 'Alert';
    String severity = 'Low';

    if      (combined.contains('FALL DETECTED'))                                          { module = 'Fall';       label = 'Fall Detected';    severity = 'High'; }
    else if (combined.contains('PROLONGED FALL'))                                         { module = 'Fall';       label = 'Prolonged Fall';   severity = 'High'; }
    else if (combined.contains('AGITATION_RISK') || combined.contains('AGITATION'))      { module = 'Agitation';  label = 'Agitation Risk';   severity = 'Medium'; }
    else if (combined.contains('PACING'))                                                 { module = 'Pacing';     label = 'Pacing Detected';  severity = 'Medium'; }
    else if (combined.contains('INACTIVE') || combined.contains('INACTIVITY'))           { module = 'Inactivity'; label = 'Inactivity';        severity = 'Medium'; }
    else if (combined.contains('LYING DOWN'))                                             { module = 'Lying Down'; label = 'Lying Down';        severity = 'Low'; }
    else if (combined.contains('STUMBLE'))                                                { module = 'Fall';       label = 'Stumble Detected'; severity = 'Low'; }

    return CctvAlert(
      id:        data['_id'] ?? data['id'] ?? data['incidentId'] ?? 'local-${DateTime.now().millisecondsSinceEpoch}',
      rawType:   rawType,
      module:    module,
      label:     label,
      severity:  severity,
      camera:    data['location'] ?? 'Unknown',
      message:   message,
      timestamp: data['timestamp'] ??
          (data['createdAt'] != null
              ? _formatDate(data['createdAt'])
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
    if (!id.startsWith('local-')) {
      await _incidentService.acknowledgeIncident(id);
    }
  }

  Future<void> dismissAlert(String id, String? userId) async {
    final alert = _alerts.firstWhere((a) => a.id == id, orElse: () => _alerts.first);
    if (alert.status == 'Unresolved' && _unreadCount > 0) _unreadCount--;
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
    if (!id.startsWith('local-')) {
      await _incidentService.dismissIncident(id);
    }
  }

  void clearActiveToast() {
    _activeToast = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cutoffTimer?.cancel();
    _emergencyPlayer.dispose();
    _warningPlayer.dispose();
    disposeSocket();
    super.dispose();
  }
}