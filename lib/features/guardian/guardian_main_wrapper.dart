import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'guardian_home_screen.dart';
import 'guardian_alerts_screen.dart';
import 'guardian_reports_screen.dart';
import 'guardian_settings_screen.dart';
import 'package:vector_math/vector_math_64.dart' show Vector4;

class GuardianMainWrapper extends StatefulWidget {
  const GuardianMainWrapper({super.key});

  @override
  State<GuardianMainWrapper> createState() => _GuardianMainWrapperState();
}

class _GuardianMainWrapperState extends State<GuardianMainWrapper> {
  bool isMenuOpen = false;
  int _currentIndex = 0;

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
        return GuardianHomeScreen(key: const ValueKey(0), onMenuTap: toggleMenu);
      case 1:
        return GuardianAlertsScreen(key: const ValueKey(1), onMenuTap: toggleMenu);
      case 2:
        return GuardianReportsScreen(key: const ValueKey(2), onMenuTap: toggleMenu);
      case 3:
        return GuardianSettingsScreen(key: const ValueKey(3), onMenuTap: toggleMenu);
      default:
        return GuardianHomeScreen(key: const ValueKey(0), onMenuTap: toggleMenu);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0FB2EA),
      body: SafeArea(
        child: Stack(
          children: [
            _buildMenu(),
            _buildBackgroundLayer(size),
            _buildAnimatedContent(size),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.65,
      height: double.infinity,
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/visiologo.png',
                  height: 40,
                  width: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, color: Colors.white, size: 40),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: toggleMenu,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          _buildDrawerItem(
            Icons.home_outlined,
            'Guardian Hub',
            _currentIndex == 0,
            onTap: () => switchScreen(0),
          ),
          _buildDrawerItem(
            Icons.notifications_active_outlined,
            'Real-Time Alerts',
            _currentIndex == 1,
            onTap: () => switchScreen(1),
          ),
          _buildDrawerItem(
            Icons.folder_shared_outlined,
            'Reports Archive',
            _currentIndex == 2,
            onTap: () => switchScreen(2),
          ),
          const Spacer(),
          _buildDrawerItem(
            Icons.settings_outlined,
            'Settings',
            _currentIndex == 3,
            onTap: () => switchScreen(3),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go('/');
                },
                icon: const Icon(Icons.logout, color: Color(0xFF0FB2EA), size: 20),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                      color: Color(0xFF0FB2EA),
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected, {Key? key, VoidCallback? onTap}) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        leading: Icon(icon, color: Colors.white, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildBackgroundLayer(Size size) {
    final double xOffset = isMenuOpen ? size.width * 0.61 : 0.0;
    final double yOffset = isMenuOpen ? size.height * 0.12 : 0.0;
    final double scale = isMenuOpen ? 0.78 : 1.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      width: size.width,
      height: size.height,
      transformAlignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..setTranslationRaw(xOffset, yOffset, 0.0)
        ..setDiagonal(Vector4(scale, scale, 1.0, 1.0)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(isMenuOpen ? 30 : 0),
      ),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildAnimatedContent(Size size) {
    final double xOffset = isMenuOpen ? size.width * 0.65 : 0.0;
    final double yOffset = isMenuOpen ? size.height * 0.08 : 0.0;
    final double scale = isMenuOpen ? 0.85 : 1.0;

    return GestureDetector(
      onTap: isMenuOpen ? toggleMenu : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
        width: size.width,
        height: size.height,
        transformAlignment: Alignment.centerLeft,
        transform: Matrix4.identity()
          ..setTranslationRaw(xOffset, yOffset, 0.0)
          ..setDiagonal(Vector4(scale, scale, 1.0, 1.0)),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(isMenuOpen ? 30 : 0),
          boxShadow: isMenuOpen
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 25,
                    spreadRadius: 5,
                    offset: const Offset(-8, 5),
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isMenuOpen ? 30 : 0),
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FBFF),
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
    );
  }
}