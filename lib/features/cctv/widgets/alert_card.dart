import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cctv_provider.dart';
import '../../auth/providers/auth_provider.dart';

class AlertCard extends StatelessWidget {
  final CctvAlert alert;
  final CctvProvider provider;

  const AlertCard({
    super.key,
    required this.alert,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isResolved = alert.status == 'Resolved';
    final userId = context.read<AuthProvider>().userId;

    Color getBorderColor() {
      if (alert.severity == 'High') return const Color(0xFFFF4757);
      if (alert.severity == 'Medium') return const Color(0xFFFFA502);
      return const Color(0xFF64748B);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: getBorderColor(),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            alert.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF003543),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        Text(
                          alert.timestamp,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF9A9EAB),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => provider.dismissAlert(alert.id, userId),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF9A9EAB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF003543),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.camera,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF9A9EAB),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isResolved 
                                ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFE6F9F0)) 
                                : (isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF0F0)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            alert.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isResolved 
                                  ? (isDark ? const Color(0xFF34D399) : const Color(0xFF2ED573)) 
                                  : (isDark ? const Color(0xFFFB7185) : const Color(0xFFFF4757)),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        if (!isResolved)
                          GestureDetector(
                            onTap: () => provider.acknowledgeAlert(alert.id, userId),
                            child: Text(
                              'ACKNOWLEDGE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}