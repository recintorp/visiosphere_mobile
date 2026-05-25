import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guardian_provider.dart';

class GuardianAccountDetails extends StatelessWidget {
  const GuardianAccountDetails({super.key});

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Not Specified';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return dateStr.split('T')[0];
    }
  }

  String _formatGender(String? g) {
    if (g == 'F' || g == 'f') return 'Female';
    if (g == 'M' || g == 'm') return 'Male';
    return g != null && g.isNotEmpty ? g : 'Not Specified';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = context.watch<GuardianProvider>();
    final guardianData = provider.guardianData;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoTile(
              Icons.badge_rounded, 
              'Full Name', 
              '${guardianData?['firstName'] ?? ''} ${guardianData?['lastName'] ?? ''}'.trim(), 
              theme, 
              isFirst: true
          ),
          _buildDivider(theme, isDark),
          _buildInfoTile(
              Icons.person_rounded, 
              'Gender', 
              _formatGender(guardianData?['gender']), 
              theme
          ),
          _buildDivider(theme, isDark),
          _buildInfoTile(
              Icons.cake_rounded, 
              'Birthday', 
              _formatDate(guardianData?['birthday']), 
              theme
          ),
          _buildDivider(theme, isDark),
          _buildInfoTile(
              Icons.email_rounded, 
              'Email Address', 
              guardianData?['email'] ?? '-', 
              theme
          ),
          _buildDivider(theme, isDark),
          _buildInfoTile(
              Icons.phone_rounded, 
              'Contact Number', 
              guardianData?['phone'] ?? '-', 
              theme, 
              isLast: true
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, ThemeData theme, {bool isFirst = false, bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(28) : Radius.zero,
          topRight: isFirst ? const Radius.circular(28) : Radius.zero,
          bottomLeft: isLast ? const Radius.circular(28) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(28) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme, bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      indent: 76,
      endIndent: 24,
    );
  }
}