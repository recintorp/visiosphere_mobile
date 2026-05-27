import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../admin/screens/dashboard_screen.dart';
import '../../admin/screens/admin_elders_screen.dart';
import '../../admin/screens/admin_guardians_screen.dart';
import '../../admin/screens/admin_assessments_screen.dart';
import '../../admin/screens/admin_settings_screen.dart';
import '../../admin/providers/admin_settings_provider.dart';
import '../../cctv/screens/cctv_analytics_screen.dart';
import '../../cctv/providers/cctv_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/foreground_service.dart';

class NurseMainWrapper extends StatefulWidget {
  const NurseMainWrapper({super.key});

  @override
  State<NurseMainWrapper> createState() => _NurseMainWrapperState();
}

class _NurseMainWrapperState extends State<NurseMainWrapper> {
  bool isMenuOpen    = false;
  int  _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    VisionSphereForegroundService.start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initFcmForegroundListener();
    });
  }

  @override
  void dispose() {
    VisionSphereForegroundService.stop();
    super.dispose();
  }

  void _initFcmForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;

      final data = message.data;

      final payload = <String, dynamic>{
        '_id':          data['incidentId'] ?? 'fcm-${DateTime.now().millisecondsSinceEpoch}',
        'incidentType': data['incidentType'] ?? '',
        'severity':     data['severity']     ?? 'Warning',
        'location':     data['location']     ?? 'Unknown',
        'description':  data['body']         ?? data['location'] ?? '',
        'message':      data['body']         ?? data['location'] ?? '',
        'rawMessage':   data['body']         ?? '',
        'type':         data['severity'] == 'Emergency' ? 'EMERGENCY' : 'WARNING',
        'timestamp':    DateTime.now().toIso8601String(),
        'acknowledged': false,
      };

      context.read<CctvProvider>().handleFcmAlert(payload);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!mounted) return;
      setState(() {
        _currentIndex = 0;
        isMenuOpen    = false;
      });
    });
  }

  void toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
    });
  }

  void switchScreen(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
    setState(() {
      isMenuOpen = false;
    });
  }

  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return DashboardScreen(key: const ValueKey(0), onMenuTap: toggleMenu, isNurseView: true);
      case 1:
        return AdminEldersScreen(key: const ValueKey(1), onMenuTap: toggleMenu, isNurseView: true);
      case 2:
        return AdminGuardiansScreen(key: const ValueKey(2), onMenuTap: toggleMenu);
      case 3:
        return AdminAssessmentsScreen(key: const ValueKey(3), onMenuTap: toggleMenu, isNurseView: true);
      case 4:
        return CctvAnalyticsScreen(key: const ValueKey(4), onMenuTap: toggleMenu);
      case 5:
        return AdminSettingsScreen(key: const ValueKey(5), onMenuTap: toggleMenu, isNurseView: true);
      default:
        return DashboardScreen(key: const ValueKey(0), onMenuTap: toggleMenu, isNurseView: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFF0FB2EA),
      body: SafeArea(
        child: Stack(
          children: [
            _buildMenu(isDark),
            _buildBackgroundLayer(size, isDark),
            _buildAnimatedContent(size, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(bool isDark) {
    final settingsProvider = context.watch<AdminSettingsProvider>();
    final authProvider     = context.watch<AuthProvider>();

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.65,
      height: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 28.0, 20.0, 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/visiologo.png',
                  height: 42,
                  width: 42,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, color: Colors.white, size: 42),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    onPressed: toggleMenu,
                    splashRadius: 24,
                  ),
                ),
              ],
            ),
          ),

          if (settingsProvider.enableSidebarToggle &&
              authProvider.userRole == 'Facility Admin') ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/admin-home'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.transparent,
                        child: const Icon(Icons.admin_panel_settings_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.medical_services_rounded,
                              color: isDark
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF0FB2EA),
                              size: 16),
                          const SizedBox(width: 6),
                          Text('Nurse',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF38BDF8)
                                    : const Color(0xFF0FB2EA),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                _buildDrawerItem(Icons.space_dashboard_rounded, 'Nurse Hub',
                    _currentIndex == 0, onTap: () => switchScreen(0)),
                _buildExpandableAccountMenu(isDark),
                _buildDrawerItem(Icons.assignment_rounded, 'Assessments & Reports',
                    _currentIndex == 3, onTap: () => switchScreen(3)),
                _buildDrawerItem(Icons.videocam_rounded, 'CCTV Live Hub',
                    _currentIndex == 4, onTap: () => switchScreen(4)),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Column(
              children: [
                _buildDrawerItem(Icons.settings_rounded, 'System Settings',
                    _currentIndex == 5, onTap: () => switchScreen(5)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final authProvider     = context.read<AuthProvider>();
                        final settingsProvider = context.read<AdminSettingsProvider>();
                        await VisionSphereForegroundService.stop();
                        await settingsProvider.resetState();
                        await authProvider.logout();
                        if (!mounted) return;
                        context.go('/');
                      },
                      icon: Icon(Icons.logout_rounded,
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0FB2EA),
                          size: 20),
                      label: Text('Sign Out',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0FB2EA),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        foregroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0FB2EA),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                        color:         Colors.white,
                        fontSize:      14,
                        fontWeight:    FontWeight.w600,
                        letterSpacing: 0.3,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableAccountMenu(bool isDark) {
    final isAnyChildSelected = _currentIndex >= 1 && _currentIndex <= 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isAnyChildSelected
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor:   Colors.transparent,
            splashColor:    Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            initiallyExpanded:  isAnyChildSelected,
            tilePadding:        const EdgeInsets.symmetric(horizontal: 16.0),
            iconColor:          Colors.white,
            collapsedIconColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.people_alt_rounded, color: Colors.white, size: 22),
                SizedBox(width: 16),
                Expanded(
                  child: Text('Accounts',
                      style: TextStyle(
                        color:         Colors.white,
                        fontSize:      14,
                        fontWeight:    FontWeight.w600,
                        letterSpacing: 0.3,
                      )),
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.only(bottom: 8.0),
            children: [
              _buildDrawerSubItem(Icons.elderly_rounded, 'Assigned Elders',
                  isSelected: _currentIndex == 1, isDark: isDark,
                  onTap: () => switchScreen(1)),
              _buildDrawerSubItem(Icons.family_restroom_rounded, 'Guardians',
                  isSelected: _currentIndex == 2, isDark: isDark,
                  onTap: () => switchScreen(2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSubItem(IconData icon, String title,
      {bool isSelected = false, required bool isDark, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(left: 48.0, right: 16.0, top: 4.0, bottom: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: isSelected
                        ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0FB2EA))
                        : Colors.white70,
                    size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                        color: isSelected
                            ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0FB2EA))
                            : Colors.white70,
                        fontSize:   13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundLayer(Size size, bool isDark) {
    return AnimatedContainer(
      duration:           const Duration(milliseconds: 400),
      curve:              Curves.fastOutSlowIn,
      width:              size.width,
      height:             size.height,
      transformAlignment: Alignment.centerLeft,
      transform: Matrix4.translationValues(
        isMenuOpen ? size.width * 0.61 : 0.0,
        isMenuOpen ? size.height * 0.12 : 0.0,
        0.0,
      )..multiply(Matrix4.diagonal3Values(
        isMenuOpen ? 0.78 : 1.0,
        isMenuOpen ? 0.78 : 1.0,
        1.0,
      )),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(isMenuOpen ? 32 : 0),
      ),
    );
  }

  Widget _buildAnimatedContent(Size size, bool isDark) {
    return GestureDetector(
      onTap: isMenuOpen ? toggleMenu : null,
      child: AnimatedContainer(
        duration:           const Duration(milliseconds: 400),
        curve:              Curves.fastOutSlowIn,
        width:              size.width,
        height:             size.height,
        transformAlignment: Alignment.centerLeft,
        transform: Matrix4.translationValues(
          isMenuOpen ? size.width * 0.65 : 0.0,
          isMenuOpen ? size.height * 0.08 : 0.0,
          0.0,
        )..multiply(Matrix4.diagonal3Values(
          isMenuOpen ? 0.85 : 1.0,
          isMenuOpen ? 0.85 : 1.0,
          1.0,
        )),
        decoration: BoxDecoration(
          color:        Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(isMenuOpen ? 32 : 0),
          boxShadow: isMenuOpen
              ? [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.5)
                        : const Color(0xFF001F2D).withValues(alpha: 0.15),
                    blurRadius:   30,
                    spreadRadius: 5,
                    offset:       const Offset(-10, 10),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMenuOpen ? 32 : 0),
          child: Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: AnimatedSwitcher(
              duration:       const Duration(milliseconds: 400),
              switchInCurve:  Curves.easeOutQuart,
              switchOutCurve: Curves.easeInQuart,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.02),
                      end:   Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _getScreenForIndex(_currentIndex),
            ),
          ),
        ),
      ),
    );
  }
}