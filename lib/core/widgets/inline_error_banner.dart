import 'package:flutter/material.dart';

/// A validation / failure message drawn INSIDE the panel that raised it.
///
/// WHY THIS EXISTS: every one of these panels is a modal bottom sheet. A
/// SnackBar is painted by the Scaffold *behind* the sheet, so on a sheet that
/// covers most of the screen the message is either clipped or completely
/// hidden — the user taps Save, nothing appears to happen, and the form looks
/// broken. QA reported exactly that on Create/Edit Resident and New Report.
/// Anything the user must read in order to fix the form belongs in the form.
///
/// SnackBars are still correct for *success* confirmations, because the sheet
/// has closed by the time they are shown.
class InlineErrorBanner extends StatelessWidget {
  final String message;
  final bool isDark;

  /// Space above the banner. Panels that place it directly under a field pass
  /// a small value; panels that place it above the action row keep the default.
  final double topMargin;

  const InlineErrorBanner({
    super.key,
    required this.message,
    required this.isDark,
    this.topMargin = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: topMargin),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF4C0519).withValues(alpha: 0.35)
            : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF881337) : const Color(0xFFFECACA),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
