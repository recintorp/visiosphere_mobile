import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_guardians_provider.dart';

class DeleteGuardianDialog extends StatefulWidget {
  final Set<String> guardianIds;

  const DeleteGuardianDialog({super.key, required this.guardianIds});

  @override
  State<DeleteGuardianDialog> createState() => _DeleteGuardianDialogState();
}

class _DeleteGuardianDialogState extends State<DeleteGuardianDialog> {
  bool _isDeleting = false;

  void _handleDelete() async {
    setState(() => _isDeleting = true);

    final success = await context.read<AdminGuardiansProvider>().deleteMultipleGuardians(widget.guardianIds);

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.guardianIds.length} account(s) deleted successfully.',
            style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error deleting accounts.',
            style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<AdminGuardiansProvider>();
    String displayName = '';

    if (widget.guardianIds.length == 1) {
      final id = widget.guardianIds.first;
      final guardian = provider.guardians.firstWhere(
        (g) => g['guardianId'] == id || g['_id'] == id,
        orElse: () => {},
      );
      displayName = "${guardian['firstName'] ?? ''} ${guardian['lastName'] ?? ''}".trim();
    } else {
      displayName = "${widget.guardianIds.length} accounts";
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.2) : const Color(0xFFFFF5F5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF881337) : const Color(0xFFFECDD3), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE11D48).withValues(alpha: isDark ? 0.3 : 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48), size: 32),
                ),
                const SizedBox(height: 16),
                Text(
                  'Confirm Deletion',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Are you absolutely sure you want to delete $displayName? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                height: 1.6,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isDeleting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDeleting ? null : _handleDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE11D48),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Yes, Delete',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}