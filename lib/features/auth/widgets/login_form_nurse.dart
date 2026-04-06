import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/nurse_auth_provider.dart';

class LoginFormNurse extends StatefulWidget {
  const LoginFormNurse({super.key});

  @override
  State<LoginFormNurse> createState() => _LoginFormNurseState();
}

class _LoginFormNurseState extends State<LoginFormNurse> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
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
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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

    final nurseId = _usernameController.text.trim();
    final password = _passwordController.text;

    if (nurseId.isEmpty) {
      _showErrorDialog(context, 'Please enter your Nurse ID');
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

    final authProvider = context.read<NurseAuthProvider>();

    await authProvider.loginWithPassword(nurseId, password);

    if (!mounted) return;

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

    if (authProvider.isFirstLogin) {
      context.push('/nurse-set-password'); 
    } else {
      context.go('/nurse-home');
    }
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
    return Consumer<NurseAuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          children: [
            TextField(
              controller: _usernameController,
              enabled: !authProvider.isLoading && !_isLockedOut,
              decoration: const InputDecoration(
                hintText: 'Nurse ID',
                prefixIcon: Icon(Icons.badge),
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
                  backgroundColor: _isLockedOut ? Colors.red.shade400 : AppColors.nurseColor,
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