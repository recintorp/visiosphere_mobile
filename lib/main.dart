import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_router.dart';
import 'features/splash/providers/splash_provider.dart';
import 'features/onboarding/providers/onboarding_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/guardian/providers/guardian_provider.dart';
import 'providers/guardian_auth_provider.dart';
import 'providers/admin_auth_provider.dart';
import 'providers/nurse_auth_provider.dart';
import 'providers/admin_dashboard_provider.dart';
import 'providers/admin_nurses_provider.dart';
import 'providers/admin_elders_provider.dart';
import 'providers/admin_guardians_provider.dart';
import 'providers/admin_assessments_provider.dart';
import 'providers/admin_audit_provider.dart';
import 'providers/admin_settings_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => GuardianProvider()),
        ChangeNotifierProvider(create: (_) => GuardianAuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminAuthProvider()),
        ChangeNotifierProvider(create: (_) => NurseAuthProvider()),
        ChangeNotifierProvider(create: (_) => AdminDashboardProvider()),
        ChangeNotifierProvider(create: (_) => AdminNursesProvider()),
        ChangeNotifierProvider(create: (_) => AdminEldersProvider()),
        ChangeNotifierProvider(create: (_) => AdminGuardiansProvider()),
        ChangeNotifierProvider(create: (_) => AdminAssessmentsProvider()),
        ChangeNotifierProvider(create: (_) => AdminAuditProvider()),
        ChangeNotifierProvider(create: (_) => AdminSettingsProvider()),
      ],
      child: MaterialApp.router(
        title: 'Visiosphere',
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}