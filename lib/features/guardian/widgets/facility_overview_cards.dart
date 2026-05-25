import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guardian_provider.dart';

class FacilityOverviewCards extends StatelessWidget {
  final DateTime currentTime;

  const FacilityOverviewCards({super.key, required this.currentTime});

  Widget _getLastAssessmentWidget(List<dynamic> assessments, ThemeData theme) {
    if (assessments.isEmpty) {
      return Text(
        'No reports\nyet',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.onSurface,
          height: 1.3,
        ),
      );
    }
    try {
      final lastAssessment = assessments.first;
      final DateTime dt = DateTime.parse(lastAssessment['createdAt']).toLocal();
      final now = DateTime.now();

      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(dt.year, dt.month, dt.day))
          .inDays;

      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$minute $period';

      String dateStr;
      if (diff == 0) {
        dateStr = 'Today';
      } else if (diff == 1) {
        dateStr = 'Yesterday';
      } else {
        dateStr = '${dt.month}/${dt.day}/${dt.year}';
      }

      // Splitting the Date and Time into perfectly aligned separate lines!
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              height: 1.2,
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              height: 1.2,
            ),
          ),
        ],
      );
    } catch (e) {
      return Text(
        'No reports\nyet',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.onSurface,
          height: 1.3,
        ),
      );
    }
  }

  Widget _getLiveTimeWidget(ThemeData theme) {
    int hour = currentTime.hour;
    final minute = currentTime.minute.toString().padLeft(2, '0');
    final second = currentTime.second.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    
    final timeStr = '$hour:$minute:$second $ampm';

    // Added "Today" to symmetrically match the Last Assessment card
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
            height: 1.2,
          ),
        ),
        Text(
          timeStr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewCard(IconData icon, String title, Widget valueWidget, Color color, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 20),
          valueWidget, // The nicely formatted text Column sits here
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<GuardianProvider>();
    final assessments = provider.assessments;

    return Row(
      children: [
        Expanded(
          child: _buildOverviewCard(
            Icons.assignment_turned_in_rounded,
            'Last Assessment',
            _getLastAssessmentWidget(assessments, theme),
            isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
            theme,
            isDark,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildOverviewCard(
            Icons.schedule_rounded,
            'Live Local Time',
            _getLiveTimeWidget(theme),
            isDark ? const Color(0xFF10B981) : const Color(0xFF059669),
            theme,
            isDark,
          ),
        ),
      ],
    );
  }
}