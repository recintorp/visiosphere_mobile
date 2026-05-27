import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/network/dio_client.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/admin/providers/admin_assessments_provider.dart';
import 'features/admin/providers/admin_audit_provider.dart';
import 'features/admin/providers/admin_dashboard_provider.dart';
import 'features/admin/providers/admin_elders_provider.dart';
import 'features/admin/providers/admin_guardians_provider.dart';
import 'features/admin/providers/admin_nurses_provider.dart';
import 'features/admin/providers/admin_settings_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/cctv/providers/cctv_provider.dart';
import 'features/guardian/providers/guardian_provider.dart';
import 'features/guardian/providers/guardian_settings_provider.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/splash/providers/splash_provider.dart';
import 'core/services/foreground_service.dart';

const AndroidNotificationChannel _alertChannel = AndroidNotificationChannel(
  'visiosphere_alerts',
  'VisionSphere Alerts',
  description: 'CCTV incident alerts for admin and nurse',
  importance: Importance.max,
  playSound: true,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_alertChannel);

  final data = message.data;
  final title = data['title'] ?? 'VisionSphere Alert';
  final body = data['body'] ?? data['location'] ?? 'New incident detected';
  final severity = data['severity'] ?? 'Warning';

  await flutterLocalNotificationsPlugin.show(
    data['incidentId']?.hashCode ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _alertChannel.id,
        _alertChannel.name,
        channelDescription: _alertChannel.description,
        importance: Importance.max,
        priority: severity == 'Emergency' ? Priority.max : Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: severity == 'Emergency',
      ),
    ),
    payload: data['incidentId'],
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterForegroundTask.initCommunicationPort();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    criticalAlert: true,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    badge: false,
    sound: false,
  );

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings),
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload != null) {
        appRouter.go('/admin');
      }
    },
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_alertChannel);

  VisionSphereForegroundService.init();
  await VisionSphereForegroundService.requestPermissions();

  DioClient.setUnauthorizedCallback(() {
    appRouter.go('/login');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GuardianProvider()),
        ChangeNotifierProvider(create: (_) => GuardianSettingsProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => AdminNursesProvider()),
        ChangeNotifierProvider(create: (_) => AdminEldersProvider()),
        ChangeNotifierProvider(create: (_) => AdminGuardiansProvider()),
        ChangeNotifierProvider(create: (_) => AdminAssessmentsProvider()),
        ChangeNotifierProvider(create: (_) => AdminAuditProvider()),
        ChangeNotifierProvider(create: (_) => AdminSettingsProvider()),
        ChangeNotifierProvider(create: (_) => CctvProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'Visiosphere',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}