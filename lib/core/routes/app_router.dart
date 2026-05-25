import 'package:go_router/go_router.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/admin/widgets/admin_main_wrapper.dart';
import '../../features/nurse/widgets/nurse_main_wrapper.dart';
import '../../features/guardian/widgets/guardian_main_wrapper.dart';
import '../../features/admin/screens/admin_nurse_details_screen.dart';
import '../../features/admin/screens/admin_elder_details_screen.dart';
import '../../features/incident/screens/alert_history_screen.dart';

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
      path: '/admin-home',
      builder: (context, state) => const AdminMainWrapper(),
    ),
    GoRoute(
      path: '/nurse-home',
      builder: (context, state) => const NurseMainWrapper(),
    ),
    GoRoute(
      path: '/guardian-home',
      builder: (context, state) => const GuardianMainWrapper(),
    ),
    GoRoute(
      path: '/admin-nurse-details',
      builder: (context, state) {
        final nurse = state.extra;
        return AdminNurseDetailsScreen(nurse: nurse);
      },
    ),
    GoRoute(
      path: '/admin-elder-details',
      builder: (context, state) {
        final resident = state.extra;
        return AdminElderDetailsScreen(resident: resident);
      },
    ),
    GoRoute(
      path: '/admin/alert-history',
      builder: (context, state) {
        final initialWeek = state.extra as String?;
        return AlertHistoryScreen(initialWeekISO: initialWeek);
      },
    ),
    GoRoute(
      path: '/nurse/alert-history',
      builder: (context, state) {
        final initialWeek = state.extra as String?;
        return AlertHistoryScreen(initialWeekISO: initialWeek);
      },
    ),
  ],
);