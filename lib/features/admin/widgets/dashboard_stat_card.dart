import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

enum TrendDirection { up, down, neutral, none }

class StatCardData {
  final int current;
  final int? diff;
  final TrendDirection direction;
  final String label;
  final int? cameraOnline;
  final int? cameraTotal;

  const StatCardData({
    required this.current,
    this.diff,
    this.direction = TrendDirection.neutral,
    this.label = 'No changes',
    this.cameraOnline,
    this.cameraTotal,
  });

  factory StatCardData.fromMap(Map<String, dynamic> map) {
    final rawDir = map['trend'] as String? ?? 'neutral';
    final direction = switch (rawDir) {
      'up'      => TrendDirection.up,
      'down'    => TrendDirection.down,
      'none'    => TrendDirection.none,
      _         => TrendDirection.neutral,
    };
    return StatCardData(
      current:      (map['current'] as num?)?.toInt() ?? 0,
      diff:         (map['delta']   as num?)?.toInt(),
      direction:    direction,
      label:        map['label']   as String? ?? 'No changes',
      cameraOnline: (map['online'] as num?)?.toInt(),
      cameraTotal:  (map['total']  as num?)?.toInt(),
    );
  }
}

/// Compact equal-width tile used in the 3-up stat row.
/// Sits inside an IntrinsicHeight Row — height is driven by the tallest tile.
class MiniStatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData iconData;
  final StatCardData? statData;

  const MiniStatTile({
    super.key,
    required this.title,
    required this.value,
    required this.iconData,
    this.statData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const accent     = Color(0xFF00A8E8);
    final cardBg     = isDark ? AppColors.dashSurface : Colors.white;
    final borderCol  = isDark ? const Color(0xFF00435C) : const Color(0xFFDEEDF5);
    final labelColor = isDark ? AppColors.dashTextMuted : const Color(0xFF7A9AAD);
    final valueColor = isDark ? AppColors.dashTextPrimary : const Color(0xFF00212E);

    // Trend indicator — minimal dot only, no pill
    Widget? trendDot;
    if (statData != null && statData!.direction != TrendDirection.none) {
      final d = statData!.direction;
      final dotColor = d == TrendDirection.up
          ? const Color(0xFF22C55E)
          : d == TrendDirection.down
              ? const Color(0xFFF87171)
              : (isDark ? AppColors.dashTextMuted : const Color(0xFFB0C8D4));
      trendDot = Container(
        width:  6,
        height: 6,
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      );
    }

    // Camera special: show "X/Y" sub-label instead of dot
    String? subLabel;
    if (statData?.direction == TrendDirection.none) {
      final on  = statData!.cameraOnline ?? 0;
      final tot = statData!.cameraTotal  ?? 0;
      subLabel = '$on/$tot';
    }

    return Container(
      decoration: BoxDecoration(
        color:        cardBg,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.18)
                : const Color(0xFF00A8E8).withValues(alpha: 0.06),
            blurRadius: 8,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:       MainAxisSize.min,
        children: [
          // Icon
          Container(
            width:  26,
            height: 26,
            decoration: BoxDecoration(
              color:        accent.withValues(alpha: isDark ? 0.15 : 0.09),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(iconData, size: 13, color: accent),
          ),
          const SizedBox(height: 8),
          // Value
          Text(
            value,
            style: TextStyle(
              fontSize:      24,
              fontWeight:    FontWeight.w900,
              letterSpacing: -1.0,
              height:        1.0,
              color:         valueColor,
            ),
          ),
          const SizedBox(height: 4),
          // Label row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  subLabel != null ? '$title · $subLabel' : title,
                  style: TextStyle(
                    fontSize:      10,
                    fontWeight:    FontWeight.w700,
                    letterSpacing: 0.1,
                    color:         labelColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trendDot != null) ...[
                const SizedBox(width: 4),
                trendDot,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Kept for backward-compat — wraps MiniStatTile.
/// DashboardStatsRow uses MiniStatTile directly now.
class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData iconData;
  final StatCardData? statData;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.iconData,
    this.statData,
  });

  @override
  Widget build(BuildContext context) =>
      MiniStatTile(title: title, value: value, iconData: iconData, statData: statData);
}