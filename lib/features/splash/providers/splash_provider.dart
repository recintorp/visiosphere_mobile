import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/app_preferences.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../auth/providers/auth_provider.dart';

/// What the backend said about the stored token.
///
/// The distinction between [rejected] and [unreachable] is the whole point:
/// only the backend actively refusing the token means the session is over.
/// Anything else — a dropped connection, a timeout, a cold dyno, a 500 — says
/// nothing about whether the token is still good, and must NOT sign the user
/// out. Collapsing both into "invalid" is what made the app appear to log
/// people out on its own.
enum _TokenStatus { valid, rejected, unreachable }

class SplashProvider extends ChangeNotifier {
  Future<void> checkFirstLaunch(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 3));
    if (!context.mounted) return;

    final hasToken = await SecureStorageService.hasToken();
    if (!context.mounted) return;

    if (!hasToken) {
      // The first-run tour is an introduction, not a gate. Once it has been
      // seen — or the user has signed in even once — go straight to sign-in.
      final seenOnboarding = await AppPreferences.hasSeenOnboarding();
      if (!context.mounted) return;
      context.go(seenOnboarding ? '/login' : '/onboarding');
      return;
    }

    final token = await SecureStorageService.getToken();
    final role = await SecureStorageService.getUserRole();
    final status = await _validateToken(token);
    if (!context.mounted) return;

    if (status == _TokenStatus.rejected) {
      // The only path that ends a session without the user asking: the backend
      // refused the token (expired, or minted before facility separation).
      await SecureStorageService.clearAuthData();
      if (!context.mounted) return;
      context.go('/login');
      return;
    }

    // valid OR unreachable: keep the session. If the backend could not be
    // reached, the home screens surface their own error states and can be
    // pulled to refresh — far better than silently signing someone out because
    // their phone was on a bad connection at launch.
    await context.read<AuthProvider>().loadSavedAuth();
    if (!context.mounted) return;

    if (role == 'Nurse') {
      context.go('/nurse-home');
    } else if (role == 'Guardian') {
      context.go('/guardian-home');
    } else if (role == 'Facility Admin') {
      context.go('/admin-home');
    } else {
      // A stored token with no recognisable role is not a rejected session,
      // but there is nowhere to send them — sign-in, without clearing.
      context.go('/login');
    }
  }

  Future<_TokenStatus> _validateToken(String? token) async {
    if (token == null || token.isEmpty) return _TokenStatus.rejected;
    try {
      final response = await DioClient.instance.get(
        ApiConstants.settingsBase,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (s) => s != null && s < 600,
        ),
      );
      final code = response.statusCode;
      if (code == 200) return _TokenStatus.valid;
      // 401/403 is the backend actively refusing this token. Every other code
      // (500s, 502 from a restarting dyno, anything unexpected) is a server
      // problem, not a verdict on the session.
      if (code == 401 || code == 403) return _TokenStatus.rejected;
      return _TokenStatus.unreachable;
    } catch (_) {
      // Timeout, DNS failure, no connectivity, cold backend. Says nothing about
      // the token.
      return _TokenStatus.unreachable;
    }
  }
}
