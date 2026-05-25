import 'package:flutter/material.dart';
import 'dashboard_stat_card.dart';

/// Replaces the old horizontal-scroll card row.
///
/// Layout (top → bottom):
///   1. Alert Hero card  — full width, prominent, context-adaptive
///   2. 3-tile stat row  — Elders | Nurses | Cameras (equal width, IntrinsicHeight)
class DashboardStatsRow extends StatelessWidget {
  final String eldersValue;
  final String nursesValue;
  final String camerasValue;
  final String alertsValue;
  final StatCardData? eldersStat;
  final StatCardData? nursesStat;
  final StatCardData? camerasStat;
  final StatCardData? alertsStat;
  final bool isNurseView;

  const DashboardStatsRow({
    super.key,
    required this.eldersValue,
    required this.nursesValue,
    required this.camerasValue,
    required this.alertsValue,
    this.eldersStat,
    this.nursesStat,
    this.camerasStat,
    this.alertsStat,
    this.isNurseView = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark      = Theme.of(context).brightness == Brightness.dark;
    final alertsCount = alertsStat?.current ?? int.tryParse(alertsValue) ?? 0;
    final camsOnline  = camerasStat?.cameraOnline ?? 0;
    final camsTotal   = camerasStat?.cameraTotal  ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AlertHeroCard(
          alertsCount: alertsCount,
          camsOnline:  camsOnline,
          camsTotal:   camsTotal,
          isDark:      isDark,
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: MiniStatTile(
                  title:    'Elders',
                  value:    eldersValue,
                  iconData: Icons.people_alt_rounded,
                  statData: eldersStat,
                ),
              ),
              const SizedBox(width: 8),
              if (!isNurseView) ...[
                Expanded(
                  child: MiniStatTile(
                    title:    'Nurses',
                    value:    nursesValue,
                    iconData: Icons.medical_services_rounded,
                    statData: nursesStat,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: MiniStatTile(
                  title:    'Cameras',
                  value:    camerasValue,
                  iconData: Icons.videocam_rounded,
                  statData: camerasStat,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Alert Hero Card ───────────────────────────────────────────────────────────

class _AlertHeroCard extends StatelessWidget {
  final int alertsCount;
  final int camsOnline;
  final int camsTotal;
  final bool isDark;

  const _AlertHeroCard({
    required this.alertsCount,
    required this.camsOnline,
    required this.camsTotal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasAlerts = alertsCount > 0;
    final camIssue  = camsTotal > 0 && camsOnline < camsTotal;

    final Color bg;
    final Color borderCol;
    final Color iconBg;
    final Color iconColor;
    final Color titleColor;
    final Color subColor;
    final IconData heroIcon;
    final String titleText;
    final String subText;

    if (hasAlerts) {
      bg         = isDark ? const Color(0xFF2A0A0A) : const Color(0xFFFFF5F5);
      borderCol  = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.6) : const Color(0xFFFECACA);
      iconBg     = isDark ? const Color(0xFFF87171).withValues(alpha: 0.15) : const Color(0xFFFEE2E2);
      iconColor  = const Color(0xFFF87171);
      titleColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
      subColor   = isDark ? const Color(0xFFEF4444).withValues(alpha: 0.7) : const Color(0xFFEF4444).withValues(alpha: 0.8);
      heroIcon   = Icons.warning_amber_rounded;
      titleText  = '$alertsCount Active Alert${alertsCount > 1 ? 's' : ''}';
      subText    = 'Immediate attention required';
    } else if (camIssue) {
      bg         = isDark ? const Color(0xFF1C1200) : const Color(0xFFFFFBEB);
      borderCol  = isDark ? const Color(0xFF92400E).withValues(alpha: 0.5) : const Color(0xFFFDE68A);
      iconBg     = isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : const Color(0xFFFEF3C7);
      iconColor  = const Color(0xFFF59E0B);
      titleColor = isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309);
      subColor   = isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.7) : const Color(0xFFD97706).withValues(alpha: 0.8);
      heroIcon   = Icons.videocam_off_rounded;
      titleText  = 'Camera Issue Detected';
      subText    = '$camsOnline of $camsTotal cameras online';
    } else {
      bg         = isDark ? const Color(0xFF00212E) : const Color(0xFFEEF7FC);
      borderCol  = isDark ? const Color(0xFF00435C) : const Color(0xFFB8DFF0);
      iconBg     = const Color(0xFF00A8E8).withValues(alpha: isDark ? 0.18 : 0.12);
      iconColor  = const Color(0xFF00A8E8);
      titleColor = isDark ? const Color(0xFFCCEDFA) : const Color(0xFF00435C);
      subColor   = isDark ? const Color(0xFF4CC2EE).withValues(alpha: 0.7) : const Color(0xFF0075A2).withValues(alpha: 0.8);
      heroIcon   = Icons.shield_rounded;
      titleText  = 'All Systems Normal';
      subText    = 'No active alerts · $camsOnline/$camsTotal cameras online';
    }

    return Container(
      decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: hasAlerts
                ? const Color(0xFFF87171).withValues(alpha: isDark ? 0.12 : 0.08)
                : const Color(0xFF00A8E8).withValues(alpha: isDark ? 0.08 : 0.05),
            blurRadius: 12,
            offset:     const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Container(
            width:  44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(heroIcon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize:       MainAxisSize.min,
              children: [
                Text(
                  titleText,
                  style: TextStyle(
                    fontSize:      15,
                    fontWeight:    FontWeight.w900,
                    letterSpacing: -0.3,
                    height:        1.1,
                    color:         titleColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subText,
                  style: TextStyle(
                    fontSize:   11,
                    fontWeight: FontWeight.w600,
                    color:      subColor,
                  ),
                ),
              ],
            ),
          ),
          if (hasAlerts) ...[
            const SizedBox(width: 10),
            Container(
              width:  42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF87171).withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: const Color(0xFFF87171).withValues(alpha: 0.35),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                alertsCount > 99 ? '99+' : alertsCount.toString(),
                style: const TextStyle(
                  fontSize:      18,
                  fontWeight:    FontWeight.w900,
                  letterSpacing: -0.5,
                  color:         Color(0xFFF87171),
                  height:        1.0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}