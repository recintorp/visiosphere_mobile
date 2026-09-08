import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/network/dio_client.dart';
import 'core/routes/app_router.dart';
import 'core/services/secure_storage_service.dart';
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
import 'features/video_clips/providers/video_clips_provider.dart';
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
  final data = message.data;

  // THIS HANDLER DRAWS CCTV INCIDENTS AND NOTHING ELSE.
  //
  // It used to draw every push that reached the device. The two incident
  // dispatches (backend/services/notificationService.js) are data-only
  // messages — no `notification` block — so Android shows nothing for them and
  // this handler has to build the notification itself. The assessment
  // dispatches (backend/services/assessmentNotificationHelper.js) are the
  // opposite: they carry a `notification` block that Android displays on its
  // own, plus data holding only `_id`/`type`/`residentId`/`assessmentId`.
  //
  // So a posted Daily Journal arrived here with no `title` and no `body`, fell
  // through to the fallbacks below, and was drawn a SECOND time as
  // "VisionSphere Alert — New incident detected" beside the real journal
  // notification. A phantom emergency, every time a nurse filed a journal.
  //
  // `incidentId` is the field that separates them: both incident dispatches
  // set it, neither assessment dispatch does. Without it there is no incident
  // to announce, and Android has already shown whatever the message carried.
  final incidentId = data['incidentId']?.toString() ?? '';
  if (incidentId.isEmpty) return;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_alertChannel);

  final title = data['title'] ?? 'VisionSphere Alert';
  final body = data['body'] ?? data['location'] ?? 'New incident detected';
  final severity = data['severity'] ?? 'Warning';

  await flutterLocalNotificationsPlugin.show(
    incidentId.hashCode,
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
    payload: incidentId,
  );
}

/// Where a tapped incident notification lands.
///
/// This was `appRouter.go('/admin')` — a location the router has never
/// defined. core/routes/app_router.dart declares `/admin-home`, `/nurse-home`,
/// `/guardian-home`, `/admin/alert-history` and `/nurse/alert-history`; there
/// is no `/admin`. So every staff member who tapped an alert from the tray
/// landed on "Page Not Found — GoException: no routes for location: /admin".
///
/// Only staff are sent incident pushes (notificationService.js dispatches to
/// admin and nurse tokens), and each role has its own alert history route, so
/// the destination has to be chosen from the signed-in role rather than
/// hardcoded. The role's home goes down first and alert history on top of it:
/// AlertHistoryScreen's back button calls context.pop(), which needs something
/// underneath it or a tap that cold-starts the app strands the user on a
/// screen they cannot leave.
Future<void> _openAlertHistoryForSignedInRole() async {
  final role = await SecureStorageService.getUserRole();

  switch (role) {
    case 'Facility Admin':
      appRouter.go('/admin-home');
      appRouter.push('/admin/alert-history');
      break;
    case 'Nurse':
      appRouter.go('/nurse-home');
      appRouter.push('/nurse/alert-history');
      break;
    case 'Guardian':
      // Guardians are not sent incident pushes; if one ever reaches a guardian
      // handset there is no alert history for them to open.
      appRouter.go('/guardian-home');
      break;
    default:
      // No stored role means no live session to return to.
      appRouter.go('/login');
  }
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
      final incidentId = response.payload;
      if (incidentId == null || incidentId.isEmpty) return;
      _openAlertHistoryForSignedInRole();
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
        ChangeNotifierProvider(create: (_) => VideoClipsProvider()),
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