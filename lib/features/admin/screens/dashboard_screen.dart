import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/admin_dashboard_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_stat_card.dart';
import '../widgets/dashboard_stats_row.dart';
import '../widgets/dashboard_chart_card.dart';
import '../widgets/recent_weeks_strip.dart';
import '../../auth/providers/auth_provider.dart';
import '../../cctv/providers/cctv_provider.dart';
import '../../cctv/widgets/alerts_sheet.dart';
import '../../../core/constants/colors.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final bool isNurseView;

  const DashboardScreen({super.key, this.onMenuTap, this.isNurseView = false});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final cctv = context.read<CctvProvider>();
      context.read<AdminDashboardProvider>().fetchDashboardData(
        isNurseView:  widget.isNurseView,
        userId:       auth.userId,
        userRole:     auth.userRole,
        cctvProvider: cctv,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? Theme.of(context).scaffoldBackgroundColor
        : const Color(0xFFF2F8FC);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Consumer3<AdminDashboardProvider, AuthProvider, CctvProvider>(
          builder: (context, dashboard, auth, cctv, _) {
            final displayName = widget.isNurseView
                ? (dashboard.nurseName ?? auth.userName ?? 'Nurse')
                : (auth.userName ?? 'Administrator');

            return Column(
              children: [
                DashboardHeader(
                  name:         displayName,
                  role:         widget.isNurseView ? 'Nurse' : (auth.userRole ?? 'Facility Admin'),
                  unreadCount:  cctv.unreadCount,
                  onMenuTap:    widget.onMenuTap,
                  onBellTap:    () => showAlertsSheet(context),
                ),
                Expanded(
                  child: RefreshIndicator(
                    color:     const Color(0xFF00A8E8),
                    onRefresh: () => dashboard.fetchDashboardData(
                      isNurseView:  widget.isNurseView,
                      userId:       auth.userId,
                      userRole:     auth.userRole,
                      cctvProvider: cctv,
                    ),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              if (dashboard.isLoading)
                                _LoadingState(isNurseView: widget.isNurseView)
                              else ...[
                                if (dashboard.errorMessage != null) ...[
                                  _ErrorBanner(
                                    message: dashboard.errorMessage!,
                                    onRetry: () => dashboard.retry(
                                      isNurseView:  widget.isNurseView,
                                      userId:       auth.userId,
                                      userRole:     auth.userRole,
                                      cctvProvider: cctv,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                FadeInUp(
                                  duration: const Duration(milliseconds: 420),
                                  child: DashboardStatsRow(
                                    isNurseView:  widget.isNurseView,
                                    eldersValue:  dashboard.totalElders.toString().padLeft(2, '0'),
                                    nursesValue:  dashboard.activeNurses.toString().padLeft(2, '0'),
                                    camerasValue: dashboard.camerasOnline.toString().padLeft(2, '0'),
                                    alertsValue:  dashboard.alertsToday.toString().padLeft(2, '0'),
                                    eldersStat:   _statData(dashboard, 'elders'),
                                    nursesStat:   _statData(dashboard, 'nurses'),
                                    camerasStat:  _cameraStatData(dashboard),
                                    alertsStat:   _statData(dashboard, 'alerts'),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FadeInUp(
                                  duration: const Duration(milliseconds: 420),
                                  delay:    const Duration(milliseconds: 70),
                                  child: DashboardChartCard(
                                    rawData:   dashboard.weeklyStats,
                                    isLoading: dashboard.weeklyLoading,
                                    error:     dashboard.weeklyError,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                FadeInUp(
                                  duration: const Duration(milliseconds: 420),
                                  delay:    const Duration(milliseconds: 130),
                                  child: const RecentWeeksStrip(),
                                ),
                                const SizedBox(height: 20),
                              ],
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  StatCardData _statData(AdminDashboardProvider d, String key) {
    final delta = key == 'elders'  ? d.eldersDelta
                : key == 'nurses'  ? d.nursesDelta
                :                    d.alertsDelta;
    final trend = key == 'elders'  ? d.eldersTrend
                : key == 'nurses'  ? d.nursesTrend
                :                    d.alertsTrend;
    final dir = switch (trend) {
      'up'   => TrendDirection.up,
      'down' => TrendDirection.down,
      _      => TrendDirection.neutral,
    };
    final abs   = (delta ?? 0).abs();
    final label = delta == null || delta == 0
        ? 'No changes since last month'
        : '${dir == TrendDirection.up ? '+' : '-'}$abs since last month';
    return StatCardData(current: 0, diff: delta, direction: dir, label: label);
  }

  StatCardData _cameraStatData(AdminDashboardProvider d) {
    return StatCardData(
      current:      d.camerasOnline,
      direction:    TrendDirection.none,
      cameraOnline: d.camerasOnline,
      cameraTotal:  2,
      label:        '${d.camerasOnline} / 2 online',
    );
  }

  // _showAlertsSheet and _AlertsSheet used to live here, private to this file.
  // That is precisely why the bell worked on the dashboard and nowhere else:
  // the other six modules drew the same bell with no panel to open. Both moved
  // to features/cctv/widgets/alerts_sheet.dart so every module opens the same
  // one — see showAlertsSheet() above.
}

class _LoadingState extends StatelessWidget {
  final bool isNurseView;
  const _LoadingState({required this.isNurseView});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 340,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF00A8E8), strokeWidth: 2.5),
            const SizedBox(height: 16),
            Text(
              isNurseView ? 'Loading Nurse Hub...' : 'Loading Dashboard...',
              style: TextStyle(
                fontSize:   13,
                fontWeight: FontWeight.w700,
                color:      isDark ? AppColors.dashTextSecondary : const Color(0xFF00435C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color:        isDark ? const Color(0x33F87171) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFF87171), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color:      isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                fontWeight: FontWeight.w700,
                fontSize:   11,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color:        isDark ? AppColors.dashSurface : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border:       Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color:      isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                  fontWeight: FontWeight.w900,
                  fontSize:   11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
