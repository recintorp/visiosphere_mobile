import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/guardian_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../screens/guardian_home_screen.dart';
import '../screens/guardian_reports_screen.dart';
import '../screens/guardian_settings_screen.dart';

class GuardianMainWrapper extends StatefulWidget {
  const GuardianMainWrapper({super.key});

  @override
  State<GuardianMainWrapper> createState() => _GuardianMainWrapperState();
}

class _GuardianMainWrapperState extends State<GuardianMainWrapper> {
  bool isMenuOpen = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final guardianProvider = context.read<GuardianProvider>();
      final themeProvider = context.read<ThemeProvider>();
      
      final dbTheme = guardianProvider.appTheme;
      themeProvider.syncWithDbTheme(dbTheme);
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
        return GuardianHomeScreen(
          key: const ValueKey(0), 
          onMenuTap: toggleMenu,
          onNavigateTab: switchScreen,
        );
      case 1:
        return GuardianReportsScreen(key: const ValueKey(1), onMenuTap: toggleMenu);
      case 2:
        return GuardianSettingsScreen(key: const ValueKey(2), onMenuTap: toggleMenu);
      default:
        return GuardianHomeScreen(
          key: const ValueKey(0), 
          onMenuTap: toggleMenu,
          onNavigateTab: switchScreen,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFF0FB2EA),
      body: SafeArea(
        child: Stack(
          children: [
            _buildMenu(context, isDark),
            _buildBackgroundLayer(size, isDark),
            _buildAnimatedContent(size, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, bool isDark) {
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
                    color: Colors.white.withValues(alpha: 0.15),
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
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              children: [
                _buildDrawerItem(
                  Icons.home_outlined,
                  'Guardian Hub',
                  _currentIndex == 0,
                  isDark,
                  onTap: () => switchScreen(0),
                ),
                _buildDrawerItem(
                  Icons.folder_shared_outlined,
                  'Reports Archive',
                  _currentIndex == 1,
                  isDark,
                  onTap: () => switchScreen(1),
                ),
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
                _buildDrawerItem(
                  Icons.settings_outlined,
                  'Settings',
                  _currentIndex == 2,
                  isDark,
                  onTap: () => switchScreen(2),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final authProvider = context.read<AuthProvider>();
                        await authProvider.logout();
                        
                        if (!context.mounted) return;
                        context.go('/');
                      },
                      icon: Icon(Icons.logout_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0FB2EA), size: 20),
                      label: Text(
                        'Log Out',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0FB2EA),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        foregroundColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0FB2EA),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected, bool isDark, {VoidCallback? onTap}) {
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
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
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
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      width: size.width,
      height: size.height,
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
        color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(isMenuOpen ? 32 : 0),
      ),
    );
  }

  Widget _buildAnimatedContent(Size size, bool isDark) {
    return GestureDetector(
      onTap: isMenuOpen ? toggleMenu : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
        width: size.width,
        height: size.height,
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
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(isMenuOpen ? 32 : 0),
          boxShadow: isMenuOpen
              ? [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.5) : const Color(0xFF001F2D).withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(-10, 10),
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMenuOpen ? 32 : 0),
          child: RepaintBoundary(
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeOutQuart,
                switchOutCurve: Curves.easeInQuart,
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
                child: _getScreenForIndex(_currentIndex),
              ),
            ),
          ),
        ),
      ),
    );
  }
}