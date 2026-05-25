class ApiConstants {
  ApiConstants._();

  static const String _host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'http://10.0.2.2:5000', 
  );

  static const String baseUrl    = '$_host/api';
  static const String socketUrl  = _host;
  static const String uploadsUrl = '$_host/uploads';

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

  static const String socketEventAlert     = 'dashboard_alert';
  static const String socketEventAlertClip = 'dashboard_alert_clip';
  static const String socketEmitAlert      = 'cctv_alert';

  static const String statusEndpoint = '/status';
  static const String healthEndpoint = '/health';
}