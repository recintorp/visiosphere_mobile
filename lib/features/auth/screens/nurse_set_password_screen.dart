import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../../providers/nurse_auth_provider.dart';

class NurseSetPasswordScreen extends StatefulWidget {
  const NurseSetPasswordScreen({super.key});

  @override
  State<NurseSetPasswordScreen> createState() => _NurseSetPasswordScreenState();
}

class _NurseSetPasswordScreenState extends State<NurseSetPasswordScreen> {
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Listeners so the UI rebuilds in real-time as the user types
    _newPasswordController.addListener(_updateUI);
    _confirmPasswordController.addListener(_updateUI);
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_updateUI);
    _confirmPasswordController.removeListener(_updateUI);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Validate password
  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Handle set password
  void _handleSetPassword(BuildContext context) async {
    final authProvider = context.read<NurseAuthProvider>();
    final nurseId = authProvider.nurseId;

    if (nurseId == null) {
      _showErrorDialog(context, 'Session expired. Please start over.');
      return;
    }

    // Validate inputs
    final newPasswordError = _validatePassword(_newPasswordController.text);
    if (newPasswordError != null) {
      _showErrorDialog(context, newPasswordError);
      return;
    }

    final confirmPasswordError = _validatePassword(_confirmPasswordController.text);
    if (confirmPasswordError != null) {
      _showErrorDialog(context, confirmPasswordError);
      return;
    }

    // Check if passwords match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorDialog(context, 'Passwords do not match');
      return;
    }

    // Call set password
    final success = await authProvider.setPassword(
      nurseId,
      _newPasswordController.text,
      _confirmPasswordController.text,
    );

    if (success) {
      // Password set successfully
      if (mounted) {
        _showSuccessDialog(context, authProvider);
      }
    } else {
      // Error occurred
      if (mounted) {
        _showErrorDialog(context, authProvider.errorMessage ?? 'Failed to set password');
      }
    }
  }

  // Show error dialog
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

  // Show success dialog
  void _showSuccessDialog(BuildContext context, NurseAuthProvider authProvider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Success'),
          content: const Text(
            'Password set successfully! You can now login with your new password.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                
                // Clear the auth state so the login screen is perfectly fresh
                authProvider.logout(); 
                
                // Navigate back to the unified login screen
                context.go('/nurse-login'); 
              },
              child: const Text('Go to Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Nurse Password'),
        backgroundColor: AppColors.nurseColor, // Themed for Nurse
        elevation: 0,
      ),
      body: Consumer<NurseAuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const Text(
                    'Create Your Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nurse ID: ${authProvider.nurseId ?? "Unknown"}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.nurseColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.nurseColor),
                    ),
                    child: Text(
                      'This is your first login. Please set a secure password that you will use to access the facility system.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.nurseColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // New Password Input
                  TextField(
                    controller: _newPasswordController,
                    enabled: !authProvider.isLoading,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Enter a secure password (min 6 characters)',
                      prefixIcon: const Icon(Icons.lock),
                      prefixIconColor: AppColors.nurseColor,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.nurseColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Input
                  TextField(
                    controller: _confirmPasswordController,
                    enabled: !authProvider.isLoading,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter your password',
                      prefixIcon: const Icon(Icons.lock),
                      prefixIconColor: AppColors.nurseColor,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.nurseColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Password Requirements (Updates in real-time)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Password Requirements:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildRequirement(
                          'At least 6 characters',
                          _newPasswordController.text.length >= 6,
                        ),
                        _buildRequirement(
                          'Passwords match',
                          _newPasswordController.text ==
                                  _confirmPasswordController.text &&
                              _newPasswordController.text.isNotEmpty,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Set Password Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: !authProvider.isLoading
                          ? () {
                              _handleSetPassword(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.nurseColor,
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
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Set Password',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: !authProvider.isLoading
                          ? () {
                              // Clear state if they cancel out of the screen
                              authProvider.logout(); 
                              context.go('/nurse-login'); 
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper widget for password requirement indicator
  Widget _buildRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? Colors.green : Colors.grey,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isMet ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}