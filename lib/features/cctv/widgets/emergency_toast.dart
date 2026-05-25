import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/cctv_provider.dart';

class EmergencyToast extends StatelessWidget {
  final CctvAlert alert;
  final CctvProvider provider;

  const EmergencyToast({
    super.key,
    required this.alert,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Color getAccentColor() {
      if (alert.severity == 'High') return isDark ? const Color(0xFFFB7185) : const Color(0xFFFF4757);
      if (alert.severity == 'Medium') return isDark ? const Color(0xFFFBBF24) : const Color(0xFFFFA502);
      return isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8);
    }

    final accentColor = getAccentColor();

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: FadeInDown(
        duration: const Duration(milliseconds: 300),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 0),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: accentColor, width: 5)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: isDark ? 0.3 : 1.0),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${alert.severity.toUpperCase()} ALERT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isDark ? accentColor : Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => provider.clearActiveToast(),
                      child: Icon(Icons.close, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF9A9EAB)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  alert.message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      alert.camera,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      alert.timestamp,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF9A9EAB),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 1.0, end: 0.0),
                  duration: const Duration(seconds: 6),
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      minHeight: 4,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}