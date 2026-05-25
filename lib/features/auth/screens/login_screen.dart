import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/auth_provider.dart';
import '../../admin/providers/admin_settings_provider.dart';
import '../../../core/theme/theme_provider.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  String _currentView = 'login';
  String _otpStep = 'request';

  final TextEditingController _idController             = TextEditingController();
  final TextEditingController _passwordController       = TextEditingController();
  final TextEditingController _emailController          = TextEditingController();
  final TextEditingController _otpController            = TextEditingController();
  final TextEditingController _newPasswordController    = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _twoFaController          = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureNew      = true;
  bool _obscureConfirm  = true;
  bool _rememberMe      = false;

  bool _termsAccepted   = false;
  bool _privacyAccepted = false;
  String _recoveryRole  = 'Admin';

  bool _showSuccessOverlay = false;
  String _welcomeRole = '';
  String _welcomeName = '';

  Offset _pointerOffset = Offset.zero;
  late AnimationController _floatController;
  late bool _isDaytime;

  @override
  void initState() {
    super.initState();
    final hour = DateTime.now().hour;
    _isDaytime = hour >= 6 && hour < 17;

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _twoFaController.dispose();
    super.dispose();
  }

  void _switchView(String view) {
    setState(() {
      _currentView  = view;
      _otpStep      = 'request';
      _emailController.clear();
      _otpController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _twoFaController.clear();
      _termsAccepted   = false;
      _privacyAccepted = false;
      Provider.of<AuthProvider>(context, listen: false).clearError();
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogin() async {
    final authProvider     = Provider.of<AuthProvider>(context, listen: false);
    final settingsProvider = Provider.of<AdminSettingsProvider>(context, listen: false);

    if (_idController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please enter your ID/Email and Password.');
      return;
    }
    FocusScope.of(context).unfocus();
    final success = await authProvider.login(_idController.text, _passwordController.text);
    if (!mounted) return;

    if (success) {
      if (authProvider.requires2FA) {
        _switchView('2fa');
      } else {
        await settingsProvider.fetchSettings();
        if (!mounted) return;

        final role = authProvider.userRole;
        final name = authProvider.userName;

        if (role == null || role.isEmpty || name == null || name.isEmpty) {
          _showErrorSnackBar('Login failed. Please try again.');
          return;
        }

        Provider.of<ThemeProvider>(context, listen: false).setTheme(settingsProvider.theme);

        setState(() {
          _welcomeRole = role;
          _welcomeName = name;
          _showSuccessOverlay = true;
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          if (_welcomeRole == 'Nurse') {
            context.go('/nurse-home');
          } else if (_welcomeRole == 'Guardian') {
            context.go('/guardian-home');
          } else {
            context.go('/admin-home');
          }
        });
      }
    } else {
      if (authProvider.errorMessage != null) {
        _showErrorSnackBar(authProvider.errorMessage!);
      }
    }
  }

  Future<void> _handleVerify2FA() async {
    final authProvider     = Provider.of<AuthProvider>(context, listen: false);
    final settingsProvider = Provider.of<AdminSettingsProvider>(context, listen: false);

    if (_twoFaController.text.length < 4) {
      _showErrorSnackBar('Please enter a valid PIN.');
      return;
    }
    FocusScope.of(context).unfocus();
    final success = await authProvider.verify2FA(_twoFaController.text);
    if (!mounted) return;

    if (success) {
      await settingsProvider.fetchSettings();
      if (!mounted) return;

      final role = authProvider.userRole;
      final name = authProvider.userName;

      if (role == null || role.isEmpty || name == null || name.isEmpty) {
        _showErrorSnackBar('Verification failed. Please try again.');
        return;
      }

      Provider.of<ThemeProvider>(context, listen: false).setTheme(settingsProvider.theme);

      setState(() {
        _welcomeRole = role;
        _welcomeName = name;
        _showSuccessOverlay = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        if (_welcomeRole == 'Nurse') {
          context.go('/nurse-home');
        } else if (_welcomeRole == 'Guardian') {
          context.go('/guardian-home');
        } else {
          context.go('/admin-home');
        }
      });
    } else {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Invalid PIN');
    }
  }

  Future<void> _handleRequestOtp() async {
    if (_currentView == 'first-time' && (!_termsAccepted || !_privacyAccepted)) {
      _showErrorSnackBar('Please accept the Terms and Privacy Policy.');
      return;
    }
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showErrorSnackBar('Please enter a valid email address.');
      return;
    }
    FocusScope.of(context).unfocus();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendOtp(_emailController.text, _recoveryRole);
    if (!mounted) return;

    if (success) {
      setState(() { _otpStep = 'verify'; });
    } else {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Failed to send OTP.');
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.length != 6) {
      _showErrorSnackBar('Please enter the 6-digit code.');
      return;
    }
    FocusScope.of(context).unfocus();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.verifyOtp(_emailController.text, _otpController.text, _recoveryRole);
    if (!mounted) return;

    if (success) {
      setState(() { _otpStep = 'reset'; });
    } else {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Invalid OTP code.');
    }
  }

  Future<void> _handleResetPassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match.');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      _showErrorSnackBar('Password must be at least 6 characters.');
      return;
    }
    FocusScope.of(context).unfocus();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.resetPassword(
      _emailController.text,
      _otpController.text,
      _newPasswordController.text,
      _confirmPasswordController.text,
      _recoveryRole,
    );
    if (!mounted) return;

    if (success) {
      _showSuccessSnackBar('Account secured successfully! You may now log in.');
      _switchView('login');
    } else {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Failed to set password.');
    }
  }

  void _showDocModal(String type) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type == 'terms' ? 'Terms of Service' : 'Privacy Policy',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00212E)),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      'Effective Date: ${DateTime.now().toLocal().toString().split(' ')[0]}\n\n'
                      'This system is the proprietary property of the Government-Supported Elder Care Facility management. Unauthorized access, use, or modification of this system or of the data contained herein is strictly prohibited and may subject you to criminal prosecution and civil penalties.\n\n'
                      'By accessing this system, you agree that your actions may be monitored and recorded. You consent to the strict adherence to all operational protocols regarding patient and facility data confidentiality.\n\n'
                      'All personal and medical records contained within this dashboard are protected under national health information privacy laws. You agree to utilize this information solely for authorized care administration and acknowledge that improper sharing of this data will result in immediate termination of access and potential legal action.\n\n'
                      'If you require assistance or clarification regarding these policies, please contact your immediate supervisor or the Facility Administrator.',
                      style: const TextStyle(color: Colors.blueGrey, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () { Navigator.pop(context); },
                    child: const Text('Acknowledge & Close', style: TextStyle(color: Color(0xFF00A8E8), fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Color> _getBackgroundColors() {
    if (_isDaytime) {
      return [const Color(0xFF4FC3F7), const Color(0xFF0288D1)];
    }
    return [const Color(0xFF00212E), const Color(0xFF0066CC)];
  }

  List<Color> _getBubbleColors(int index) {
    if (_isDaytime) {
      switch (index) {
        case 0:  return [const Color(0xFF81D4FA).withValues(alpha: 0.6), Colors.transparent];
        case 1:  return [const Color(0xFFB3E5FC).withValues(alpha: 0.5), Colors.transparent];
        case 2:  return [const Color(0xFF29B6F6).withValues(alpha: 0.4), Colors.transparent];
        case 3:  return [const Color(0xFFE1F5FE), const Color(0xFF4FC3F7)];
        case 4:  return [const Color(0xFFFFFFFF), const Color(0xFF03A9F4)];
        default: return [Colors.white.withValues(alpha: 0.5), Colors.transparent];
      }
    } else {
      switch (index) {
        case 0:  return [const Color(0xFF0FB2EA).withValues(alpha: 0.4), Colors.transparent];
        case 1:  return [const Color(0xFF00A8E8).withValues(alpha: 0.3), Colors.transparent];
        case 2:  return [const Color(0xFF0066CC).withValues(alpha: 0.5), Colors.transparent];
        case 3:  return [const Color(0xFFE8F4FD), const Color(0xFF0FB2EA)];
        case 4:  return [const Color(0xFFFFFFFF), const Color(0xFF00A8E8)];
        default: return [const Color(0xFF0FB2EA).withValues(alpha: 0.4), Colors.transparent];
      }
    }
  }

  Widget _buildBackgroundShapes(Size size) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        final floatOffset = math.sin(_floatController.value * math.pi) * 20;

        return Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: _getBackgroundColors(),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              top: -100 + (_pointerOffset.dy * 40) + floatOffset,
              right: -50 + (_pointerOffset.dx * 40),
              child: FadeInDown(
                duration: const Duration(milliseconds: 1500),
                child: Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: _getBubbleColors(0)),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutBack,
              top: 150 + (_pointerOffset.dy * -30) - floatOffset,
              left: -80 + (_pointerOffset.dx * -30),
              child: FadeInLeft(
                duration: const Duration(milliseconds: 1500),
                child: Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: _getBubbleColors(1)),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              bottom: 100 + (_pointerOffset.dy * 60) + (floatOffset * 1.5),
              right: -100 + (_pointerOffset.dx * 60),
              child: FadeInUp(
                duration: const Duration(milliseconds: 1500),
                child: Container(
                  width: 350, height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: _getBubbleColors(2)),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 850),
              curve: Curves.easeOutBack,
              top: 80 + (_pointerOffset.dy * 25) - floatOffset,
              right: 40 + (_pointerOffset.dx * 25),
              child: FadeInDown(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 1500),
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getBubbleColors(3),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeOutBack,
              top: 280 + (_pointerOffset.dy * -45) + floatOffset,
              left: 30 + (_pointerOffset.dx * -45),
              child: FadeInLeft(
                delay: const Duration(milliseconds: 600),
                duration: const Duration(milliseconds: 1500),
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getBubbleColors(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoading    = authProvider.isLoading;
    final size         = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _isDaytime ? const Color(0xFF4FC3F7) : const Color(0xFF00212E),
      body: Listener(
        onPointerMove: (event) {
          setState(() {
            _pointerOffset = Offset(
              (event.position.dx - size.width / 2) / (size.width / 2),
              (event.position.dy - size.height / 2) / (size.height / 2),
            );
          });
        },
        onPointerHover: (event) {
          setState(() {
            _pointerOffset = Offset(
              (event.position.dx - size.width / 2) / (size.width / 2),
              (event.position.dy - size.height / 2) / (size.height / 2),
            );
          });
        },
        onPointerDown: (event) {
          setState(() {
            _pointerOffset = Offset(
              (event.position.dx - size.width / 2) / (size.width / 2),
              (event.position.dy - size.height / 2) / (size.height / 2),
            );
          });
        },
        onPointerUp: (event) {
          setState(() { _pointerOffset = Offset.zero; });
        },
        child: Stack(
          children: [
            _buildBackgroundShapes(size),
            SafeArea(
              child: Column(
                children: [
                  if (_currentView != 'login')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () { _switchView('login'); },
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                          label: const Text('Back', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FadeInDown(
                              duration: const Duration(milliseconds: 800),
                              child: ColorFiltered(
                                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  height: 100,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.security, size: 80, color: Colors.white);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_currentView == 'login')
                              FadeInDown(
                                delay: const Duration(milliseconds: 200),
                                duration: const Duration(milliseconds: 800),
                                child: const Column(
                                  children: [
                                    Text('Welcome Back!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                                    SizedBox(height: 8),
                                    Text('Enter your credentials to access the system', style: TextStyle(color: Colors.white70, fontSize: 15)),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 40),
                            FadeInUp(
                              delay: const Duration(milliseconds: 400),
                              duration: const Duration(milliseconds: 800),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 24),
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.fastOutSlowIn,
                                  alignment: Alignment.topCenter,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 500),
                                    switchInCurve: Curves.easeOutExpo,
                                    switchOutCurve: Curves.easeInExpo,
                                    transitionBuilder: (Widget child, Animation<double> animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.0, 0.05),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: SizedBox(
                                      key: ValueKey<String>('$_currentView-$_otpStep'),
                                      width: double.infinity,
                                      child: _buildCurrentForm(isLoading),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showSuccessOverlay)
              Container(
                color: const Color(0xFF00212E).withValues(alpha: 0.95),
                width: double.infinity,
                height: double.infinity,
                child: FadeInUp(
                  duration: const Duration(milliseconds: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF00A8E8), strokeWidth: 3),
                      const SizedBox(height: 30),
                      Text(
                        'Welcome back, ${_welcomeRole == 'Facility Admin' ? 'Admin' : _welcomeRole}',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(_welcomeName, style: const TextStyle(color: Color(0xFF90E0EF), fontSize: 20, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 20),
                      const Text('Preparing your dashboard...', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentForm(bool isLoading) {
    if (_currentView == 'first-time' || _currentView == 'forgot-password') {
      return _buildOtpFlow(isLoading);
    } else if (_currentView == '2fa') {
      return _build2FAForm(isLoading);
    } else if (_currentView == 'faqs') {
      return _buildFaqs();
    } else if (_currentView == 'troubles') {
      return _buildTroubles();
    } else {
      return _buildLoginForm(isLoading);
    }
  }

  Widget _buildLoginForm(bool isLoading) {
    return Column(
      key: const ValueKey('login_form'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('Sign In', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF00212E))),
        const SizedBox(height: 32),
        TextFormField(
          controller: _idController,
          enabled: !isLoading,
          style: const TextStyle(color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            labelText: 'Email Address',
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A8E8), width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
          enabled: !isLoading,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.blueGrey, size: 20),
              onPressed: () { setState(() { _obscurePassword = !_obscurePassword; }); },
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A8E8), width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              height: 24, width: 24,
              child: Checkbox(
                value: _rememberMe,
                onChanged: isLoading ? null : (val) { setState(() { _rememberMe = val ?? false; }); },
                activeColor: const Color(0xFF00A8E8),
                side: const BorderSide(color: Colors.blueGrey, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Remember me', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
            const Spacer(),
            TextButton(
              onPressed: isLoading ? null : () { _switchView('forgot-password'); },
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Forgot password?', style: TextStyle(color: Color(0xFF00A8E8), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: const Color(0xFF0066CC).withValues(alpha: 0.4),
            ),
            child: isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('First time user?', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
            const SizedBox(width: 4),
            TextButton(
              onPressed: isLoading ? null : () { _switchView('first-time'); },
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Account Setup', style: TextStyle(color: Color(0xFF00A8E8), fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: isLoading ? null : () { _switchView('faqs'); },
          child: const Text('Need Help?', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildOtpFlow(bool isLoading) {
    final isFirstTime = _currentView == 'first-time';
    return Column(
      key: ValueKey('otp_flow_$_otpStep'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(isFirstTime ? 'Account Setup' : 'Reset Password', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF00212E))),
        const SizedBox(height: 8),
        Text(
          _otpStep == 'request' ? 'Enter your registered email address and role.'
          : _otpStep == 'verify' ? 'Enter the 6-digit secure code sent to your email.'
          : 'Create your new permanent password.',
          style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (_otpStep == 'request') ...[
          DropdownButtonFormField<String>(
            initialValue: _recoveryRole,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Account Type',
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A8E8), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
            items: ['Admin', 'Nurse', 'Guardian'].map((role) {
              return DropdownMenuItem(value: role, child: Text(role));
            }).toList(),
            onChanged: isLoading ? null : (val) { setState(() { _recoveryRole = val!; }); },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'Email Address',
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A8E8), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
          ),
          if (isFirstTime) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  height: 24, width: 24,
                  child: Checkbox(
                    value: _termsAccepted,
                    onChanged: (v) { setState(() { _termsAccepted = v ?? false; }); },
                    activeColor: const Color(0xFF00A8E8),
                    side: const BorderSide(color: Colors.blueGrey, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () { _showDocModal('terms'); },
                    child: const Text('I agree to the Terms of Service', style: TextStyle(fontSize: 13, color: Color(0xFF00A8E8), fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  height: 24, width: 24,
                  child: Checkbox(
                    value: _privacyAccepted,
                    onChanged: (v) { setState(() { _privacyAccepted = v ?? false; }); },
                    activeColor: const Color(0xFF00A8E8),
                    side: const BorderSide(color: Colors.blueGrey, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () { _showDocModal('privacy'); },
                    child: const Text('I consent to the Privacy Policy', style: TextStyle(fontSize: 13, color: Color(0xFF00A8E8), fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ],
        if (_otpStep == 'verify') ...[
          TextFormField(
            controller: _otpController,
            enabled: !isLoading,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w800, color: Color(0xFF00212E)),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A8E8), width: 2)),
              contentPadding: const EdgeInsets.symmetric(vertical: 24),
            ),
          ),
        ],
        if (_otpStep == 'reset') ...[
          TextFormField(
            controller: _newPasswordController,
            enabled: !isLoading,
            obscureText: _obscureNew,
            style: const TextStyle(color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'New Password',
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey),
              suffixIcon: IconButton(
                icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.blueGrey, size: 20),
                onPressed: () { setState(() { _obscureNew = !_obscureNew; }); },
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A8E8), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _confirmPasswordController,
            enabled: !isLoading,
            obscureText: _obscureConfirm,
            style: const TextStyle(color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.blueGrey, size: 20),
                onPressed: () { setState(() { _obscureConfirm = !_obscureConfirm; }); },
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A8E8), width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            ),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : () {
              if (_otpStep == 'request')      { _handleRequestOtp(); }
              else if (_otpStep == 'verify')  { _handleVerifyOtp(); }
              else if (_otpStep == 'reset')   { _handleResetPassword(); }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: const Color(0xFF0066CC).withValues(alpha: 0.4),
            ),
            child: isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _otpStep == 'request' ? 'Send Code' : _otpStep == 'verify' ? 'Verify Code' : 'Save Password',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _build2FAForm(bool isLoading) {
    return Column(
      key: const ValueKey('2fa_form'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('Security Check', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF00212E))),
        const SizedBox(height: 8),
        const Text('Enter your 6-digit secure PIN.', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
        const SizedBox(height: 32),
        TextFormField(
          controller: _twoFaController,
          enabled: !isLoading,
          keyboardType: TextInputType.number,
          obscureText: _obscurePassword,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.w800, color: Color(0xFF00212E)),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A8E8), width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 24),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.blueGrey),
              onPressed: () { setState(() { _obscurePassword = !_obscurePassword; }); },
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: isLoading ? null : _handleVerify2FA,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066CC),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: const Color(0xFF0066CC).withValues(alpha: 0.4),
            ),
            child: isLoading
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Verify PIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
          ),
        ),
      ],
    );
  }

  Widget _buildTroubles() {
    return Column(
      key: const ValueKey('troubles_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Having Troubles?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF00212E))),
        const SizedBox(height: 8),
        const Text('Select an option below to recover your account.', style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
        const SizedBox(height: 32),
        OutlinedButton(
          onPressed: () { _switchView('forgot-password'); },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: Color(0xFF00A8E8), width: 1.5),
            backgroundColor: const Color(0xFFF8FAFC),
          ),
          child: const Text('Reset Password', style: TextStyle(color: Color(0xFF0066CC), fontWeight: FontWeight.bold, fontSize: 15)),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () { _switchView('faqs'); },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: Color(0xFF00A8E8), width: 1.5),
            backgroundColor: const Color(0xFFF8FAFC),
          ),
          child: const Text('FAQs', style: TextStyle(color: Color(0xFF0066CC), fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildFaqs() {
    return Column(
      key: const ValueKey('faqs_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Support FAQs', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF00212E))),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How do I request an account?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00212E), fontSize: 14)),
              SizedBox(height: 8),
              Text('Accounts are provisioned by your Facility Administrator. Contact them directly to receive your credentials.', style: TextStyle(fontSize: 13, color: Colors.blueGrey, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What is Account Setup?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00212E), fontSize: 14)),
              SizedBox(height: 8),
              Text('A security process to establish a permanent password for newly provisioned employee or guardian accounts.', style: TextStyle(fontSize: 13, color: Colors.blueGrey, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}