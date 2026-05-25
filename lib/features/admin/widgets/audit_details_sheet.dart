import 'package:flutter/material.dart';

class AuditDetailsSheet extends StatelessWidget {
  final Map<String, dynamic> log;

  const AuditDetailsSheet({super.key, required this.log});

  String _getStatusText(String? status) {
    if (status == null) return 'Unknown';
    final lower = status.toLowerCase();
    if (lower == 'success') return 'Success';
    if (lower == 'alert') return 'Alert';
    if (lower == 'failed') return 'Failed';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color _getStatusColor(String? status, bool isDark) {
    final lower = status?.toLowerCase();
    if (lower == 'success') return isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
    if (lower == 'alert') return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
    if (lower == 'failed') return isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48);
    return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  }

  Color _getStatusBgColor(String? status, bool isDark) {
    final lower = status?.toLowerCase();
    if (lower == 'success') return isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4);
    if (lower == 'alert') return isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFFBEB);
    if (lower == 'failed') return isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2);
    return isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
  }

  String _formatLogDetails(Map<String, dynamic> log) {
    final event = log['event'] as String? ?? 'Unknown Event';
    final actorName = log['actorName'] as String? ?? 'System';
    final actorRole = log['actorRole'] as String? ?? '';
    final newValues = log['newValues'] as Map<String, dynamic>?;
    final oldValues = log['oldValues'] as Map<String, dynamic>?;

    final rolePrefix = actorRole.isNotEmpty ? '$actorRole ' : '';
    final actorStr = '$rolePrefix$actorName';

    if (event == 'Assessment Comment Added' && newValues != null) {
      final residentPart = newValues['residentName'] != null ? ' about ${newValues['residentName']}' : '';
      final commentPart = newValues['commentPreview'] != null ? ' with "${newValues['commentPreview']}"' : '';
      return '$actorStr commented on an assessment$residentPart$commentPart.';
    }

    if (event == 'Daily Report Submitted' && newValues != null) {
      final residentPart = newValues['residentName'] != null ? ' for ${newValues['residentName']}' : '';
      return '$actorStr submitted a daily assessment report$residentPart.';
    }

    if (event == 'Elder Assigned to Nurse' && newValues != null) {
      final residentPart = newValues['residentName'] ?? newValues['residentId'] ?? 'a resident';
      final nursePart = newValues['nurseName'] ?? newValues['nurseId'] ?? 'a nurse';
      return '$actorStr assigned $residentPart to $nursePart.';
    }

    if (event == 'Elder Linked to Guardian' && newValues != null) {
      final residentPart = newValues['residentName'] ?? newValues['residentId'] ?? 'a resident';
      final guardianPart = newValues['guardianName'] ?? newValues['guardianId'] ?? 'a guardian';
      return '$actorStr linked $residentPart to $guardianPart.';
    }

    if (event == 'Guardian Profile Updated' || event == 'Nurse Profile Updated') {
      return '$actorStr updated a profile. Changes were successfully saved to the system.';
    }

    if (event == 'Login' || event == 'Failed Login Attempt') {
      return '$actorStr attempted to authenticate into the system. Result: ${log['status']}.';
    }

    List<String> detailParts = [];
    if (newValues != null && newValues.isNotEmpty) {
      detailParts.add('Updated ${newValues.keys.join(', ')}');
    }
    if (oldValues != null && oldValues.isNotEmpty) {
      detailParts.add('from previous values');
    }

    if (detailParts.isNotEmpty) {
      return '$actorStr performed $event. ${detailParts.join(' ')}.';
    }

    return '$actorStr performed the action: $event.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final logDate = log['createdAt'] != null ? DateTime.parse(log['createdAt'].toString()) : DateTime.now();
    final formattedDate = '${logDate.year}-${logDate.month.toString().padLeft(2, '0')}-${logDate.day.toString().padLeft(2, '0')} ${logDate.hour.toString().padLeft(2, '0')}:${logDate.minute.toString().padLeft(2, '0')}';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Audit Record', style: TextStyle(fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF00212E))),
                      const SizedBox(height: 4),
                      Text('ID: ${log['_id']}', style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white, 
                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TIMESTAMP', style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 0.8)),
                            const SizedBox(height: 4),
                            Text(formattedDate, style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF00212E))),
                            
                            const SizedBox(height: 20),
                            
                            Text('CATEGORY', style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 0.8)),
                            const SizedBox(height: 4),
                            Text(log['category']?.toString() ?? 'N/A', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('STATUS', style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 0.8)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusBgColor(log['status'], isDark),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _getStatusText(log['status']),
                                style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w900, color: _getStatusColor(log['status'], isDark), letterSpacing: 0.8),
                              ),
                            ),

                            const SizedBox(height: 20),

                            Text('ACTOR', style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 0.8)),
                            const SizedBox(height: 4),
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(text: '${log['actorName']} ', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF00212E))),
                                  TextSpan(text: '(${log['actorRole'] ?? 'System'})', style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), height: 1),
                  ),

                  Text('EVENT TYPE', style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  Text(log['event']?.toString() ?? 'N/A', style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF00212E))),
                  
                  const SizedBox(height: 20),

                  Text('SYSTEM PURPOSE', style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  Text(log['purpose']?.toString() ?? 'Routine operational logging.', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), height: 1.5)),

                  const SizedBox(height: 24),

                  Text('ACTION DETAILS', style: TextStyle(fontFamily: 'Montserrat', fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF082F49).withValues(alpha: 0.3) : const Color(0xFFF0F9FF),
                      border: Border.all(color: isDark ? const Color(0xFF0369A1) : const Color(0xFFBAE6FD)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatLogDetails(log),
                      style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00435C), height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}