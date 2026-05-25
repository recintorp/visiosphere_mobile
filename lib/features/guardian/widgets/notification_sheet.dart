import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guardian_provider.dart';

class NotificationSheet extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const NotificationSheet({super.key, this.onNavigateTab});

  String _formatNotificationTime(String? isoString) {
    if (isoString == null) return '';
    try {
      final date = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inHours < 1) return '${difference.inMinutes}m ago';
      if (difference.inDays < 1) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';

      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  void _handleNotificationTap(BuildContext context, Map<String, dynamic> notif, GuardianProvider provider) {
    if (notif['assessmentId'] != null && notif['residentId'] != null) {
      DateTime? targetDate;
      if (notif['reportDate'] != null) {
        targetDate = DateTime.parse(notif['reportDate']).toLocal();
      } else if (notif['createdAt'] != null) {
        targetDate = DateTime.parse(notif['createdAt']).toLocal();
      }
      
      if (targetDate != null) {
        provider.navigateToReport(targetDate, notif['residentId']);
      }
    }

    provider.deleteNotification(notif['_id']);

    Navigator.pop(context);

    if (onNavigateTab != null) {
      onNavigateTab!(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<GuardianProvider>();
    final notifications = provider.notifications;
    final hasUnread = provider.unreadNotificationCount > 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                if (hasUnread)
                  TextButton(
                    onPressed: () {
                      provider.markAllNotificationsAsRead();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Mark all as read',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: theme.colorScheme.onSurfaceVariant),
                    onPressed: () => Navigator.pop(context),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_active_outlined, 
                            size: 64, 
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No new notifications right now.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifications[index];
                      final isRead = notif['isRead'] == true;
                      final isSystem = notif['type'] == 'system';
                      final isReport = notif['type'] == 'new_report';
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Dismissible(
                          key: Key(notif['_id'].toString()),
                          direction: DismissDirection.horizontal,
                          onDismissed: (direction) {
                            provider.deleteNotification(notif['_id']);
                          },
                          background: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ),
                          child: InkWell(
                            onTap: () => _handleNotificationTap(context, notif, provider),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: !isRead 
                                      ? theme.colorScheme.primary.withValues(alpha: 0.3)
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSystem 
                                          ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                                          : (isReport 
                                              ? const Color(0xFF10B981).withValues(alpha: 0.15) 
                                              : theme.colorScheme.primary.withValues(alpha: 0.15)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isSystem ? Icons.info_outline_rounded
                                      : (isReport ? Icons.assignment_rounded : Icons.chat_bubble_outline_rounded),
                                      color: isSystem ? const Color(0xFFF59E0B) : (isReport ? const Color(0xFF10B981) : theme.colorScheme.primary),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                notif['title'] ?? 'Notification',
                                                style: TextStyle(
                                                  fontWeight: !isRead ? FontWeight.w900 : FontWeight.w700,
                                                  color: theme.colorScheme.onSurface,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _formatNotificationTime(notif['createdAt']),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          notif['message'] ?? '',
                                          style: TextStyle(
                                            color: !isRead ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                            fontSize: 13,
                                            height: 1.4,
                                            fontWeight: !isRead ? FontWeight.w600 : FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isRead) ...[
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.only(top: 6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}