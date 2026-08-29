class ApiConstants {
  ApiConstants._();

  // Production defaults so the app works on physical devices out of the box.
  // Override for local dev, e.g.:
  //   flutter run --dart-define=API_HOST=http://10.0.2.2:5000 \
  //               --dart-define=STREAM_BASE=http://10.0.2.2:5001/video_feed
  static const String _host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'https://visiosphere-backend.onrender.com',
  );

  static const String baseUrl    = '$_host/api';
  static const String socketUrl  = _host;
  static const String uploadsUrl = '$_host/uploads';

  // Public MJPEG stream base (AI core fronted by the Cloudflare Tunnel).
  // The per-session ?token= is appended at request time by CctvProvider.
  static const String streamBaseUrl = String.fromEnvironment(
    'STREAM_BASE',
    defaultValue: 'https://cctv.visiosphere.live/video_feed',
  );

  // DEBUG ONLY: if set, the app streams with ?key=<this> (the AI core's legacy
  // static STREAM_TOKEN) and skips the backend token fetch entirely. Used to
  // isolate "is it the Render token?" vs "is it flutter_mjpeg?". Leave empty in
  // production. Pass via: --dart-define=STREAM_DEBUG_KEY=<static key>
  static const String streamDebugKey = String.fromEnvironment(
    'STREAM_DEBUG_KEY',
    defaultValue: '',
  );

  /// The device's UTC offset as `+HH:MM`, for the `tz` query parameter on the
  /// incident stats endpoints.
  ///
  /// WHY THIS EXISTS
  ///
  /// The backend feeds `tz` straight into MongoDB's `$dateToString`, which
  /// accepts an Olson name ("Asia/Manila") or a UTC offset ("+08:00") and
  /// REJECTS anything else — an unrecognised value makes the aggregation throw,
  /// so the request 500s and the caller sees nothing at all.
  ///
  /// Dart cannot produce an Olson name. `DateTime.now().timeZoneName` returns a
  /// platform abbreviation — "PST", "GMT+08:00", "Philippine Standard Time" —
  /// and none of them are valid to Mongo. Sending it is what made Alert History
  /// open to an empty list: all five week requests failed, the catch emptied the
  /// list, and the screen reported "no records" for data that was there.
  ///
  /// The offset is the one form Dart can produce that Mongo accepts. For the
  /// Philippines, which has no daylight saving, `+08:00` is exactly equivalent
  /// to the `Asia/Manila` the web dashboard sends — so mobile and web now bucket
  /// days identically instead of disagreeing by eight hours.
  static String get deviceTimeZone {
    final offset  = DateTime.now().timeZoneOffset;
    final sign    = offset.isNegative ? '-' : '+';
    final abs     = offset.abs();
    final hours   = abs.inHours.toString().padLeft(2, '0');
    final minutes = (abs.inMinutes % 60).toString().padLeft(2, '0');
    return '$sign$hours:$minutes';
  }

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout    = Duration(seconds: 15);
  static const Duration batchTimeout   = Duration(seconds: 30);

  static const String adminLogin         = '/admin/login';
  static const String adminVerify2FA     = '/admin/verify-2fa';
  static const String adminRequestOtp    = '/admin/request-otp';
  static const String adminVerifyOtp     = '/admin/verify-otp';
  static const String adminResetPassword = '/admin/reset-password';
  static const String adminBase          = '/admin';

  static const String guardianLogin          = '/guardians/auth/login';
  static const String guardianRequestOtp     = '/guardians/auth/request-otp';
  static const String guardianVerifyOtp      = '/guardians/auth/verify-otp';
  static const String guardianResetPassword  = '/guardians/auth/reset-password';
  static const String guardianSetPassword    = '/guardians/auth/set-password';
  static const String guardianChangePassword = '/guardians/auth/change-password';
  static const String guardianBase           = '/guardians';

  static const String nurseLogin         = '/nurses/auth/login';
  static const String nurseRequestOtp    = '/nurses/auth/request-otp';
  static const String nurseVerifyOtp     = '/nurses/auth/verify-otp';
  static const String nurseResetPassword = '/nurses/auth/reset-password';
  static const String nurseSetPassword   = '/nurses/auth/set-password';
  static const String nurseBase          = '/nurses';

  static const String residentBase   = '/residents';
  static const String assessmentBase = '/assessments';
  static const String incidentBase   = '/incidents';
  static const String notificationBase = '/notifications';
  static const String auditBase      = '/audit-logs';
  static const String auditArchiveBase = '/audit-archive';
  static const String settingsBase   = '/settings';
  static const String reportBase     = '/reports';
  static const String streamTokenEndpoint = '/stream/token';

  static const String socketEventAlert     = 'dashboard_alert';
  static const String socketEventAlertClip = 'dashboard_alert_clip';
  static const String socketEmitAlert      = 'cctv_alert';

  static const String statusEndpoint = '/status';
  static const String healthEndpoint = '/health';
}