import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/cctv_provider.dart';

/// The CCTV alerts panel behind the header bell.
///
/// WHY THIS LIVES HERE AND NOT IN dashboard_screen.dart
///
/// The panel used to be a private widget inside the dashboard, so the bell only
/// did anything on the dashboard. Every other module — Nurses, Elders,
/// Guardians, Assessments, Audit Trail, System Settings — drew the same bell but
/// had `onPressed: () {}` or no tap target at all, which is exactly what "the
/// notification button is not working in all modules except in dashboard"
/// describes. Moving the sheet here lets all of them open the SAME panel with
/// one call, instead of six copies of it drifting apart.

/// Open the alerts panel over whatever screen is showing.
///
/// The CctvProvider is read BEFORE the modal is pushed and re-injected with
/// .value, because showModalBottomSheet builds in a detached BuildContext that
/// is not below this screen's providers. Reading it inside the builder is what
/// would throw ProviderNotFoundException.
void showAlertsSheet(BuildContext context) {
  final isDark       = Theme.of(context).brightness == Brightness.dark;
  final cctvProvider = context.read<CctvProvider>();
  final authProvider = context.read<AuthProvider>();

  showModalBottomSheet(
    context:            context,
    backgroundColor:    Colors.transparent,
    isScrollControlled: true,
    builder: (_) => MultiProvider(
      providers: [
        ChangeNotifierProvider<CctvProvider>.value(value: cctvProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: AlertsSheet(isDark: isDark),
    ),
  );
}

/// The header bell used by every module OTHER than the dashboard.
///
/// The dashboard has its own bell inside DashboardHeader; this is the one for
/// the six module app bars that previously drew a decorative icon. Colour and
/// size are passed in so each screen keeps the look it already had — the only
/// visible change is that the badge now reflects the real unread count instead
/// of a red dot that was painted unconditionally.
class NotificationBellButton extends StatelessWidget {
  final Color color;
  final double size;
  final bool isDark;

  const NotificationBellButton({
    super.key,
    required this.color,
    required this.isDark,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<CctvProvider>().unreadCount;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: Icon(
            unread > 0
                ? Icons.notifications_rounded
                : Icons.notifications_none_rounded,
            size:  size,
            color: color,
          ),
          onPressed: () => showAlertsSheet(context),
        ),
        if (unread > 0)
          Positioned(
            right: size > 24 ? 8 : 4,
            top:   size > 24 ? 8 : 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 14),
              decoration: BoxDecoration(
                color:        const Color(0xFFFF4757),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  width: 1.5,
                ),
              ),
              child: Text(
                unread > 9 ? '9+' : unread.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   8,
                  fontWeight: FontWeight.w900,
                  height:     1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class AlertsSheet extends StatelessWidget {
  final bool isDark;
  const AlertsSheet({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Consumer<CctvProvider>(
      builder: (context, cctv, _) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: BoxDecoration(
            color:        isDark ? const Color(0xFF00212E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 14),
                width: 34, height: 4,
                decoration: BoxDecoration(
                  color:        isDark ? const Color(0xFF00435C) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CCTV Alerts',
                      style: TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF00212E),
                      ),
                    ),
                    Row(
                      children: [
                        if (cctv.unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:        const Color(0xFFF87171),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${cctv.unreadCount} Unread',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (cctv.alerts.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _ClearButton(isDark: isDark, cctv: cctv),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Divider(
                color:  isDark ? const Color(0xFF00435C) : const Color(0xFFE4EDF2),
                height: 1,
              ),
              Expanded(
                child: cctv.alerts.isEmpty
                    ? Center(
                        child: Text(
                          'No recent alerts',
                          style: TextStyle(
                            color:      isDark ? AppColors.dashTextMuted : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: cctv.alerts.length,
                        padding:   const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        itemBuilder: (context, i) {
                          final alert = cctv.alerts[i];
                          return Container(
                            margin:  const EdgeInsets.only(bottom: 9),
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color:        isDark ? const Color(0xFF001823) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border(
                                left: BorderSide(
                                  color: alert.severity == 'High'
                                      ? const Color(0xFFF87171)
                                      : const Color(0xFFF59E0B),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(alert.label,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize:   12,
                                          color: isDark ? Colors.white : const Color(0xFF00212E),
                                        )),
                                    Text(alert.timestamp,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? AppColors.dashTextMuted : const Color(0xFF94A3B8),
                                        )),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(alert.message,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    )),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(alert.camera,
                                        style: const TextStyle(
                                          fontSize:   10,
                                          fontWeight: FontWeight.w700,
                                          color:      Color(0xFF00A8E8),
                                        )),
                                    if (alert.status == 'Unresolved')
                                      GestureDetector(
                                        onTap: () {
                                          cctv.acknowledgeAlert(
                                              alert.id, context.read<AuthProvider>().userId);
                                          Navigator.pop(context);
                                        },
                                        child: const Text(
                                          'ACKNOWLEDGE',
                                          style: TextStyle(
                                            fontSize:   10,
                                            fontWeight: FontWeight.w900,
                                            color:      Color(0xFF22C55E),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Clear" in the panel header.
///
/// Asks first: clearing dismisses the alerts on the server as well, so they do
/// not reappear on the next refresh. That is the only way the button can mean
/// anything — a purely local clear would be undone by the next fetch — but it
/// also means it is not undoable, which is worth one tap of confirmation in a
/// care facility.
class _ClearButton extends StatelessWidget {
  final bool isDark;
  final CctvProvider cctv;
  const _ClearButton({required this.isDark, required this.cctv});

  Future<void> _confirmAndClear(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF00212E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Clear notifications?',
          style: TextStyle(
            fontSize:   16,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF00212E),
          ),
        ),
        content: Text(
          'This dismisses every alert currently listed. Resolved incidents stay '
          'in Alert History — only this panel is emptied.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                )),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear All',
                style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFF87171))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await cctv.clearNotifications();
    messenger.showSnackBar(
      const SnackBar(
        content:  Text('Notifications cleared.'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => _confirmAndClear(context),
      icon: Icon(Icons.clear_all_rounded,
          size: 16, color: isDark ? const Color(0xFF4CC2EE) : const Color(0xFF00435C)),
      label: Text(
        'Clear',
        style: TextStyle(
          fontSize:   11,
          fontWeight: FontWeight.w900,
          color: isDark ? const Color(0xFF4CC2EE) : const Color(0xFF00435C),
        ),
      ),
      style: TextButton.styleFrom(
        padding:        const EdgeInsets.symmetric(horizontal: 8),
        minimumSize:    Size.zero,
        tapTargetSize:  MaterialTapTargetSize.shrinkWrap,
        visualDensity:  VisualDensity.compact,
      ),
    );
  }
}
