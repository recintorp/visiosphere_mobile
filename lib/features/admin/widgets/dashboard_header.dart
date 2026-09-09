import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

class DashboardHeader extends StatelessWidget {
  final String name;
  final String role;
  final int unreadCount;
  final VoidCallback? onMenuTap;
  final VoidCallback? onBellTap;

  const DashboardHeader({
    super.key,
    required this.name,
    required this.role,
    required this.unreadCount,
    this.onMenuTap,
    this.onBellTap,
  });

  String get _firstName => name.split(' ').first;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _dateLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = role.toLowerCase().contains('admin');

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.dashBg : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.dashSurface : const Color(0xFFDEEDF5),
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 6, 10, 6),
      child: Row(
        children: [
          // Hamburger
          IconButton(
            // tooltip IS the accessibility label for an IconButton. Without it
            // this announced only as "button".
            tooltip: 'Open navigation menu',
            icon: Icon(
              Icons.menu_rounded,
              color: isDark ? AppColors.dashTextPrimary : const Color(0xFF00212E),
              size:  21,
            ),
            onPressed:     onMenuTap ?? () => Scaffold.of(context).openDrawer(),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          const SizedBox(width: 2),
          // Greeting block
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:       MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$_greeting, ',
                      style: TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.dashTextSecondary : const Color(0xFF4A7A8A),
                        height: 1.1,
                      ),
                    ),
                    Text(
                      _firstName,
                      style: const TextStyle(
                        fontSize:   12,
                        fontWeight: FontWeight.w900,
                        color:      Color(0xFF00A8E8),
                        height:     1.1,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? const Color(0xFF00A8E8).withValues(alpha: isDark ? 0.18 : 0.10)
                            : const Color(0xFF00435C).withValues(alpha: isDark ? 0.30 : 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isAdmin
                              ? const Color(0xFF00A8E8).withValues(alpha: 0.32)
                              : const Color(0xFF00435C).withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        isAdmin ? 'ADMIN' : 'NURSE',
                        style: TextStyle(
                          fontSize:      7,
                          fontWeight:    FontWeight.w900,
                          letterSpacing: 0.7,
                          color: isAdmin
                              ? const Color(0xFF00A8E8)
                              : (isDark ? const Color(0xFF90e0ef) : const Color(0xFF00435C)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  _dateLabel,
                  style: TextStyle(
                    fontSize:   9,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.dashTextMuted : AppColors.dashTextMuted,
                  ),
                ),
              ],
            ),
          ),
          // Bell
          _BellButton(unreadCount: unreadCount, onTap: onBellTap, isDark: isDark),
        ],
      ),
    );
  }
}

class _BellButton extends StatelessWidget {
  final int unreadCount;
  final VoidCallback? onTap;
  final bool isDark;
  const _BellButton({required this.unreadCount, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasAlerts = unreadCount > 0;
    // Announced as an unnamed element before this: a GestureDetector carries no
    // role and no label of its own. The count belongs IN the name so it can be
    // heard without opening the panel.
    final semanticLabel = hasAlerts
        ? 'Alerts, $unreadCount unread'
        : 'Alerts, none unread';
    return Semantics(
      button: true,
      label:  semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
      onTap: onTap,
      // The circle stays 34dp; only the hit area grows to the 48dp Android
      // minimum, which is what the Touch target finding was about.
      child: Container(
        width:  48,
        height: 48,
        alignment: Alignment.center,
        color: Colors.transparent,
        child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width:  34,
            height: 34,
            decoration: BoxDecoration(
              color: hasAlerts
                  ? const Color(0xFFF87171).withValues(alpha: isDark ? 0.15 : 0.08)
                  : (isDark ? AppColors.dashSurface : const Color(0xFFEEF7FC)),
              shape: BoxShape.circle,
              border: Border.all(
                color: hasAlerts
                    ? const Color(0xFFF87171).withValues(alpha: 0.32)
                    : (isDark ? AppColors.dashBorder : const Color(0xFFB8DFF0)),
              ),
            ),
            child: Icon(
              // #F87171 on its own 8%-alpha chip measures 2.56:1 — under the
              // 3:1 WCAG asks of non-text. #DC2626 is 4.48:1 on the same chip.
              // The chip and the badge keep the original lighter red.
              hasAlerts ? Icons.notifications_rounded : Icons.notifications_none_rounded,
              color: hasAlerts
                  ? const Color(0xFFDC2626)
                  : (isDark ? const Color(0xFF4CC2EE) : const Color(0xFF00435C)),
              size: 16,
            ),
          ),
          if (hasAlerts)
            Positioned(
              right: -2,
              top:   -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color:  const Color(0xFFF87171),
                  shape:  BoxShape.circle,
                  border: Border.all(
                    color: isDark ? AppColors.dashBg : Colors.white,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   7,
                    fontWeight: FontWeight.w900,
                    height:     1.0,
                  ),
                ),
              ),
            ),
        ],
        ),
      ),
      ),
    );
  }
}