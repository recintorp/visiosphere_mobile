import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../auth/providers/auth_provider.dart';

class SplashProvider extends ChangeNotifier {
  Future<void> checkFirstLaunch(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 3));
    if (!context.mounted) return;

    final hasToken = await SecureStorageService.hasToken();
    if (!context.mounted) return;

    if (hasToken) {
      final token = await SecureStorageService.getToken();
      final role  = await SecureStorageService.getUserRole();

      final tokenValid = await _validateToken(token);
      if (!context.mounted) return;

      if (tokenValid) {
        await context.read<AuthProvider>().loadSavedAuth();
        if (!context.mounted) return;

        if (role == 'Nurse') {
          context.go('/nurse-home');
        } else if (role == 'Guardian') {
          context.go('/guardian-home');
        } else if (role == 'Facility Admin') {
          context.go('/admin-home');
        } else {
          context.go('/onboarding');
        }
      } else {
        await SecureStorageService.clearAuthData();
        if (!context.mounted) return;
        context.go('/onboarding');
      }
    } else {
      context.go('/onboarding');
    }
  }

  Future<bool> _validateToken(String? token) async {
    if (token == null || token.isEmpty) return false;
    try {
      final response = await DioClient.instance.get(
        ApiConstants.settingsBase,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (s) => s != null && s < 600,
        ),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}