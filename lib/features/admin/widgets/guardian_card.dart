import 'package:flutter/material.dart';

class GuardianCard extends StatelessWidget {
  final Map<String, dynamic> guardian;
  final bool isSelected;
  final ValueChanged<bool?> onSelect;
  final VoidCallback onTap;
  final VoidCallback onAssignElders;

  const GuardianCard({
    super.key,
    required this.guardian,
    required this.isSelected,
    required this.onSelect,
    required this.onTap,
    required this.onAssignElders,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String firstName = guardian['firstName'] ?? '';
    final String lastName = guardian['lastName'] ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String id = guardian['guardianId'] ?? 'N/A';
    final String email = guardian['email'] ?? 'No email';
    final String phone = guardian['phone'] ?? '';
    final String status = (guardian['status'] ?? 'PENDING').toString().toUpperCase();
    final List<dynamic> assignedElders = guardian['assignedElders'] ?? [];

    Color statusColor;
    Color statusBgColor;

    switch (status) {
      case 'ACTIVE':
        statusColor = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981); 
        statusBgColor = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4);
        break;
      case 'INACTIVE':
        statusColor = isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48); 
        statusBgColor = isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2);
        break;
      case 'PENDING':
      default:
        statusColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B); 
        statusBgColor = isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFFBEB);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
              ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)) 
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)), 
          width: isSelected ? 2 : 1
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox for bulk actions
                Transform.scale(
                  scale: 1.1,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: onSelect,
                    activeColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
                    checkColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), width: 1.5),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Main Card Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: ID and Status Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF082F49).withValues(alpha: 0.5) : const Color(0xFFE1F5FE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              id,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Guardian Name
                      Text(
                        fullName,
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // Contact Info
                      Row(
                        children: [
                          Icon(Icons.email_outlined, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                fontFamily: 'Montserrat',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            phone.isEmpty ? 'No phone provided' : phone,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      const SizedBox(height: 12),
                      
                      // Footer: Assigned Elders & Action Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.family_restroom_rounded, 
                                size: 16, 
                                color: assignedElders.isEmpty 
                                    ? (isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8)) 
                                    : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8))
                              ),
                              const SizedBox(width: 6),
                              Text(
                                assignedElders.isEmpty ? 'No elders assigned' : '${assignedElders.length} Assigned',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: assignedElders.isEmpty 
                                      ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)) 
                                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: onAssignElders,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF00A8E8) : const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Assign Elders',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: isDark ? Colors.white : Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}