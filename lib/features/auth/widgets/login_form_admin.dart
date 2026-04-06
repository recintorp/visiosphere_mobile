import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/admin_auth_provider.dart';

class LoginFormAdmin extends StatefulWidget {
  const LoginFormAdmin({super.key});

  @override
  State<LoginFormAdmin> createState() => _LoginFormAdminState();
}

class _LoginFormAdminState extends State<LoginFormAdmin> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _pinController;
  bool _obscurePassword = true;
  bool _obscurePin = true;
  bool _agreeToTerms = false;
  bool _agreeToPrivacy = false;

  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutCountdown = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _startLockout() {
    setState(() {
      _isLockedOut = true;
      _lockoutCountdown = 30;
    });
    
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_lockoutCountdown > 0) {
          _lockoutCountdown--;
        } else {
          _isLockedOut = false;
          _failedAttempts = 0;
          timer.cancel();
        }
      });
    });
  }

  void _handleLogin(BuildContext context) async {
    if (_isLockedOut) return;

    final adminId = _usernameController.text.trim();
    final password = _passwordController.text;

    if (adminId.isEmpty) {
      _showErrorDialog(context, 'Please enter your Admin ID');
      return;
    }

    if (password.isEmpty) {
      _showErrorDialog(context, 'Please enter your Password');
      return;
    }

    if (!_agreeToTerms || !_agreeToPrivacy) {
      _showErrorDialog(context, 'Please agree to Terms and Privacy Policy');
      return;
    }

    final authProvider = context.read<AdminAuthProvider>();

    await authProvider.loginWithPassword(adminId, password);

    if (!context.mounted) return;

    if (authProvider.errorMessage != null) {
      _failedAttempts++;
      if (_failedAttempts >= 3) {
        _startLockout();
        _showErrorDialog(context, 'Too many failed attempts. Account locked for 30 seconds.');
        return;
      }
      _showErrorDialog(context, authProvider.errorMessage!);
      return;
    }

    _failedAttempts = 0;

    if (authProvider.requires2FA) {
      return; 
    }

    if (authProvider.isFirstLogin) {
      context.push('/admin-set-password');
    } else {
      context.go('/admin-home');
    }
  }

  void _handleVerify2FA(BuildContext context) async {
    if (_isLockedOut) return;

    final pin = _pinController.text.trim();
    
    if (pin.length < 4) {
      _showErrorDialog(context, 'Please enter a valid PIN.');
      return;
    }

    final authProvider = context.read<AdminAuthProvider>();
    
    await authProvider.verify2FA(authProvider.adminId!, pin);

    if (!context.mounted) return;

    if (authProvider.errorMessage != null) {
      _failedAttempts++;
      if (_failedAttempts >= 3) {
        _startLockout();
        authProvider.cancel2FA();
        _pinController.clear();
        _showErrorDialog(context, 'Too many failed 2FA attempts. Account locked for 30 seconds.');
        return;
      }
      _showErrorDialog(context, '${authProvider.errorMessage!}. $_failedAttempts/3 attempts.');
      return;
    }

    _failedAttempts = 0;
    _pinController.clear();
    context.go('/admin-home');
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAuthProvider>(
      builder: (context, authProvider, child) {
        
        if (authProvider.requires2FA) {
          return Column(
            children: [
              const Text(
                'Two-Factor Authentication',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please enter your secure PIN to continue.',
                style: TextStyle(fontSize: 14, color: AppColors.textHint),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _pinController,
                obscureText: _obscurePin,
                enabled: !authProvider.isLoading && !_isLockedOut,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: '••••••',
                  counterText: "",
                  prefixIcon: const Icon(Icons.security, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePin ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textHint,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePin = !_obscurePin;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_isLockedOut || authProvider.isLoading)
                      ? null
                      : () => _handleVerify2FA(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLockedOut ? Colors.red.shade400 : AppColors.adminColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isLockedOut ? 'Locked. Wait $_lockoutCountdown s' : 'Verify PIN',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: authProvider.isLoading ? null : () {
                  authProvider.cancel2FA();
                  _pinController.clear();
                },
                child: const Text('Cancel', style: TextStyle(color: AppColors.textHint)),
              ),
            ],
          );
        }

        return Column(
          children: [
            TextField(
              controller: _usernameController,
              enabled: !authProvider.isLoading && !_isLockedOut,
              decoration: const InputDecoration(
                hintText: 'Admin ID',
                prefixIcon: Icon(Icons.admin_panel_settings),
                prefixIconColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !authProvider.isLoading && !_isLockedOut,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                prefixIconColor: AppColors.primary,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              value: _agreeToTerms,
              onChanged: (authProvider.isLoading || _isLockedOut)
                  ? null
                  : (value) {
                      setState(() {
                        _agreeToTerms = value ?? false;
                      });
                    },
              title: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'I have read and agree to the ',
                      style: TextStyle(color: AppColors.textDark, fontSize: 13),
                    ),
                    TextSpan(
                      text: 'Community Terms of Service',
                      style: TextStyle(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: '. (Required)',
                      style: TextStyle(color: AppColors.textDark, fontSize: 13),
                    ),
                  ],
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _agreeToPrivacy,
              onChanged: (authProvider.isLoading || _isLockedOut)
                  ? null
                  : (value) {
                      setState(() {
                        _agreeToPrivacy = value ?? false;
                      });
                    },
              title: RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'I consent to the collection and use of my personal data in accordance with ',
                      style: TextStyle(color: AppColors.textDark, fontSize: 13),
                    ),
                    TextSpan(
                      text: 'Community Privacy Policy',
                      style: TextStyle(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: '. (Required)',
                      style: TextStyle(color: AppColors.textDark, fontSize: 13),
                    ),
                  ],
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_agreeToTerms && _agreeToPrivacy && !authProvider.isLoading && !_isLockedOut)
                    ? () {
                        _handleLogin(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLockedOut ? Colors.red.shade400 : AppColors.adminColor,
                  disabledBackgroundColor: AppColors.textHint,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: authProvider.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _isLockedOut ? 'Locked. Wait $_lockoutCountdown s' : 'Login',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}