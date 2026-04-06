import 'package:go_router/go_router.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/set_password_screen.dart';
import '../../features/auth/screens/admin_set_password_screen.dart';
import '../../features/auth/screens/nurse_set_password_screen.dart';
import '../../features/admin/admin_main_wrapper.dart';
import '../../features/nurse/nurse_main_wrapper.dart';
import '../../features/guardian/guardian_main_wrapper.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/admin-login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/guardian-login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/nurse-login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/guardian-set-password',
      name: 'guardian-set-password',
      builder: (context, state) => const SetPasswordScreen(),
    ),
    GoRoute(
      path: '/admin-set-password',
      name: 'admin-set-password',
      builder: (context, state) => const AdminSetPasswordScreen(),
    ),
    GoRoute(
      path: '/nurse-set-password',
      name: 'nurse-set-password',
      builder: (context, state) => const NurseSetPasswordScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminMainWrapper(),
    ),
    GoRoute(
      path: '/admin-home',
      builder: (context, state) => const AdminMainWrapper(),
    ),
    GoRoute(
      path: '/nurse',
      builder: (context, state) => const NurseMainWrapper(),
    ),
    GoRoute(
      path: '/nurse-home',
      builder: (context, state) => const NurseMainWrapper(),
    ),
    GoRoute(
      path: '/guardian-home',
      builder: (context, state) => const GuardianMainWrapper(),
    ),
  ],
);