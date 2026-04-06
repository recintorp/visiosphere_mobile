import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashProvider extends ChangeNotifier {
  Future<void> checkFirstLaunch(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 3));
    
    // TODO: Check SharedPreferences for first launch
    // For now, always go to onboarding
    if (context.mounted) {
      context.go('/onboarding');
    }
  }
}