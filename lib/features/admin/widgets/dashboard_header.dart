import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../cctv/providers/cctv_provider.dart';

class DashboardHeader extends StatelessWidget {
  final String name;
  final String role;
  final int unreadCount;
  final VoidCallback? onMenuTap;
  final VoidCallback? onBellTap;
  final CctvProvider cctvProvider;

  const DashboardHeader({
    super.key,
    required this.name,
    required this.role,
    required this.unreadCount,
    required this.cctvProvider,
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
            icon: Icon(
              Icons.menu_rounded,
              color: isDark ? AppColors.dashTextPrimary : const Color(0xFF00212E),
              size:  21,
            ),
            onPressed:     onMenuTap ?? () => Scaffold.of(context).openDrawer(),
            visualDensity: VisualDensity.compact,
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
                    color: isDark ? AppColors.dashTextMuted : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          // Volume chip
          _VolumeChip(cctvProvider: cctvProvider, isDark: isDark),
          const SizedBox(width: 7),
          // Bell
          _BellButton(unreadCount: unreadCount, onTap: onBellTap, isDark: isDark),
        ],
      ),
    );
  }
}

class _VolumeChip extends StatelessWidget {
  final CctvProvider cctvProvider;
  final bool isDark;
  const _VolumeChip({required this.cctvProvider, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        isDark ? AppColors.dashSurface : const Color(0xFFEEF7FC),
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(
          color: isDark ? AppColors.dashBorder : const Color(0xFFB8DFF0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width:  22,
            height: 22,
            decoration: BoxDecoration(
              color: cctvProvider.isPlaying
                  ? const Color(0xFF00A8E8)
                  : (isDark ? const Color(0xFF00435C) : const Color(0xFFB8DFF0)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              cctvProvider.volume == 0
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              color: Colors.white,
              size:  11,
            ),
          ),
          const SizedBox(width: 3),
          SizedBox(
            width: 54,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight:        2,
                thumbShape:         const RoundSliderThumbShape(enabledThumbRadius: 4.5),
                overlayShape:       const RoundSliderOverlayShape(overlayRadius: 7),
                activeTrackColor:   const Color(0xFF00A8E8),
                inactiveTrackColor: isDark ? AppColors.dashSurface : const Color(0xFFB8DFF0),
                thumbColor:         const Color(0xFF00A8E8),
              ),
              child: Slider(value: cctvProvider.volume, onChanged: cctvProvider.setVolume),
            ),
          ),
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
    return GestureDetector(
      onTap: onTap,
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
              hasAlerts ? Icons.notifications_rounded : Icons.notifications_none_rounded,
              color: hasAlerts
                  ? const Color(0xFFF87171)
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
    );
  }
}