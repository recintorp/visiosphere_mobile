import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'admin_home_screen.dart';
import 'admin_nurses_screen.dart';
import 'admin_elders_screen.dart';
import 'admin_guardians_screen.dart';
import 'admin_assessments_screen.dart';
import 'admin_audit_screen.dart';
import 'admin_settings_screen.dart';
import '../../providers/admin_settings_provider.dart';

class AdminMainWrapper extends StatefulWidget {
  const AdminMainWrapper({super.key});

  @override
  State<AdminMainWrapper> createState() => _AdminMainWrapperState();
}

class _AdminMainWrapperState extends State<AdminMainWrapper> {
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
        return AdminHomeScreen(key: const ValueKey(0), onMenuTap: toggleMenu);
      case 1:
        return AdminNursesScreen(key: const ValueKey(1), onMenuTap: toggleMenu);
      case 2:
        return AdminEldersScreen(key: const ValueKey(2), onMenuTap: toggleMenu);
      case 3:
        return AdminGuardiansScreen(key: const ValueKey(3), onMenuTap: toggleMenu);
      case 4:
        return AdminAssessmentsScreen(key: const ValueKey(4), onMenuTap: toggleMenu);
      case 5:
        return AdminAuditScreen(key: const ValueKey(5), onMenuTap: toggleMenu);
      case 6:
        return AdminSettingsScreen(key: const ValueKey(6), onMenuTap: toggleMenu);
      default:
        return AdminHomeScreen(key: const ValueKey(0), onMenuTap: toggleMenu);
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
    final settingsProvider = context.watch<AdminSettingsProvider>();

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
          
          if (settingsProvider.enableSidebarToggle) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Color(0xFF001F2D), size: 14),
                          SizedBox(width: 6),
                          Text('Admin', style: TextStyle(color: Color(0xFF001F2D), fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/nurse'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.medical_services, color: Colors.white70, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          _buildDrawerItem(
            Icons.home,
            'Admin Hub',
            _currentIndex == 0,
            onTap: () => switchScreen(0),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _currentIndex >= 1 && _currentIndex <= 3,
              tilePadding: const EdgeInsets.symmetric(horizontal: 20.0),
              leading: const Icon(Icons.people, color: Colors.white),
              title: const Text('Account Management',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildDrawerSubItem(
                        Icons.medical_services_outlined,
                        'Nurses',
                        isSelected: _currentIndex == 1,
                        onTap: () => switchScreen(1),
                      ),
                      Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                      _buildDrawerSubItem(
                        Icons.elderly,
                        'Elders',
                        isSelected: _currentIndex == 2,
                        onTap: () => switchScreen(2),
                      ),
                      Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                      _buildDrawerSubItem(
                        Icons.family_restroom, 
                        'Guardians', 
                        isSelected: _currentIndex == 3,
                        onTap: () => switchScreen(3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.videocam, 'CCTV Analytics Hub', false),
          _buildDrawerItem(
            Icons.assignment, 
            'Daily Assessments & Reports', 
            _currentIndex == 4,
            onTap: () => switchScreen(4),
          ),
          _buildDrawerItem(
            Icons.receipt_long, 
            'Audit Trail & Logs', 
            _currentIndex == 5,
            onTap: () => switchScreen(5),
          ),
          const Spacer(),
          _buildDrawerItem(
            Icons.settings, 
            'System Settings', 
            _currentIndex == 6,
            onTap: () => switchScreen(6),
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

  Widget _buildDrawerItem(IconData icon, String title, bool isSelected, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: onTap ?? () {},
      ),
    );
  }

  Widget _buildDrawerSubItem(IconData icon, String title, {bool isSelected = false, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? const Color(0xFF001F2D) : const Color(0xFF0FB2EA), size: 18),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF001F2D) : const Color(0xFF0FB2EA),
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
      dense: true,
      visualDensity: VisualDensity.compact,
      onTap: onTap ?? () {},
    );
  }

  Widget _buildBackgroundLayer(Size size) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.fastOutSlowIn,
      width: size.width,
      height: size.height,
      transformAlignment: Alignment.centerLeft,
      transform: Matrix4.identity()
        ..translate(
          isMenuOpen ? size.width * 0.61 : 0.0,
          isMenuOpen ? size.height * 0.12 : 0.0,
          0.0,
        )
        ..scale(isMenuOpen ? 0.78 : 1.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(isMenuOpen ? 30 : 0),
      ),
      child: SizedBox(
        width: size.width,
        height: size.height,
      ),
    );
  }

  Widget _buildAnimatedContent(Size size) {
    return GestureDetector(
      onTap: isMenuOpen ? toggleMenu : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.fastOutSlowIn,
        width: size.width,
        height: size.height,
        transformAlignment: Alignment.centerLeft,
        transform: Matrix4.identity()
          ..translate(
            isMenuOpen ? size.width * 0.65 : 0.0,
            isMenuOpen ? size.height * 0.08 : 0.0,
            0.0,
          )
          ..scale(isMenuOpen ? 0.85 : 1.0),
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