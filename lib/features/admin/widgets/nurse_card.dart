import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/facilities.dart';
import '../../auth/providers/auth_provider.dart';

class NurseCard extends StatelessWidget {
  final dynamic nurse;
  final VoidCallback onTap;

  const NurseCard({
    super.key,
    required this.nurse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String nurseId = nurse['nurseId'] ?? 'N/A';
    // The roster prints the nurse's own Display Name when she has set one.
    // resolveName prefers the server-resolved `profileName` (see
    // backend/models/Nurse.js) and falls back to the legal name, so a nurse who
    // has never renamed herself looks exactly as she did before.
    //
    // Her legal name is still shown on the Staff Details screen, which is where
    // an admin verifies or edits the staff record.
    final String firstName = nurse['firstName'] ?? '';
    final String fullName = AuthProvider.resolveName(nurse);
    final String house = nurse['houseAssigned']?.replaceAll('House of ', '') ?? 'Unassigned';
    final bool showHouse =
        Facilities.hasHouseChoice(context.read<AuthProvider>().facility);
    final String status = nurse['status'] ?? 'Inactive';
    final int assignedCount = (nurse['assignedElders'] as List?)?.length ?? 0;
    // Saint Anthony does not assign residents to nurses, so "0 Elders" there
    // would read as a problem with the record rather than a fact about the
    // facility. See Facilities.assignsEldersToNurses.
    final bool showAssignedCount = Facilities.assignsEldersToNurses(
        Facilities.facilityOf(nurse['nurseId'])
            ?? context.read<AuthProvider>().facility);
    
    final bool isFirstLogin = nurse['isFirstLogin'] ?? false;
    final String? linkedAdminId = nurse['linkedAdminId'];

    // Setup Status Logic
    String setupStatusText = 'REGISTERED';
    Color setupBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    Color setupTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    IconData setupIcon = Icons.check_circle_outline_rounded;

    if (linkedAdminId != null && linkedAdminId.toString().isNotEmpty) {
      setupStatusText = 'LINKED TO ADMIN';
      setupBgColor = isDark ? const Color(0xFF4C1D95).withValues(alpha: 0.3) : const Color(0xFFF3E8FF);
      setupTextColor = isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE);
      setupIcon = Icons.link_rounded;
    } else if (isFirstLogin) {
      setupStatusText = 'PENDING SETUP';
      setupBgColor = isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.3) : const Color(0xFFFFF7ED);
      setupTextColor = isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C);
      setupIcon = Icons.pending_actions_rounded;
    }
    
    // Active/Inactive Status Logic
    Color statusColor;
    Color statusBgColor;
    
    if (status == 'Active') {
      statusColor = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981);
      statusBgColor = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5);
    } else if (status == 'On Leave') {
      statusColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);
      statusBgColor = isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFFBEB);
    } else {
      statusColor = isDark ? const Color(0xFFFB7185) : const Color(0xFFF43F5E);
      statusBgColor = isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2);
    }

    // Avatar Initial
    final String initial = fullName.isNotEmpty
        ? fullName[0].toUpperCase()
        : (firstName.isNotEmpty ? firstName[0].toUpperCase() : 'N');

    // Accessibility Scanner reported this row three ways at once: the tap
    // target had no label ("Item label"), the ID / name / setup-status text was
    // painted but absent from the a11y tree ("Unexposed text"), and every row
    // described itself identically ("Item descriptions"). One spoken node
    // carrying the row's own values answers all three.
    final spoken = StringBuffer('$fullName, $nurseId, $status, $setupStatusText');
    if (showHouse) spoken.write(', house $house');
    if (showAssignedCount) spoken.write(', $assignedCount elders assigned');

    return Semantics(
      button: true,
      label: spoken.toString(),
      excludeSemantics: true,
      child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Main Content Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Circular Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00A8E8), Color(0xFF0066CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066CC).withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text and Badges Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fullName,
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    nurseId,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Status Dot & Text
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      color: statusColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 9,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Setup Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: setupBgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(setupIcon, size: 12, color: setupTextColor),
                              const SizedBox(width: 4),
                              Text(
                                setupStatusText,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: setupTextColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Footer Section (House & Elders)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), 
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Grace's only — see Facilities.hasHouseChoice. Kept as an empty
                  // box rather than removed: this footer is spaceBetween, so
                  // dropping the child outright would slide the item on the
                  // right over to the left.
                  if (!showHouse)
                    const SizedBox.shrink()
                  else
                    Row(
                      children: [
                        Icon(Icons.home_work_rounded, size: 16, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text(
                          house,
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  if (!showAssignedCount)
                    const SizedBox.shrink()
                  else
                  Row(
                    children: [
                      Icon(Icons.people_alt_rounded, size: 16, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)),
                      const SizedBox(width: 6),
                      Text(
                        '$assignedCount Elders',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}