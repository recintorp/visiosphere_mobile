import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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