import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_guardians_provider.dart';

class AssignEldersModal extends StatefulWidget {
  final Map<String, dynamic> guardian;

  const AssignEldersModal({super.key, required this.guardian});

  @override
  State<AssignEldersModal> createState() => _AssignEldersModalState();
}

class _AssignEldersModalState extends State<AssignEldersModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleLink(String residentId) async {
    final guardianId = widget.guardian['guardianId'] ?? widget.guardian['_id'];
    final success = await context.read<AdminGuardiansProvider>().linkResidentToGuardian(guardianId, residentId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elder assigned successfully!', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFF10B981)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to assign elder.', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)),
      );
    }
  }

  void _handleUnlink(String residentId) async {
    final guardianId = widget.guardian['guardianId'] ?? widget.guardian['_id'];
    final success = await context.read<AdminGuardiansProvider>().unlinkResidentFromGuardian(guardianId, residentId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elder unassigned successfully.', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFF10B981)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to unassign elder.', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AdminGuardiansProvider>();
    final guardianId = widget.guardian['guardianId'] ?? widget.guardian['_id'];
    
    final currentGuardian = provider.guardians.firstWhere(
      (g) => g['guardianId'] == guardianId || g['_id'] == guardianId,
      orElse: () => widget.guardian,
    );

    final List<dynamic> assignedElders = currentGuardian['assignedElders'] ?? [];
    final List<String> assignedResidentIds = assignedElders.map((e) => (e['residentId'] ?? e['_id']).toString()).toList();

    final availableResidents = provider.residents.where((r) {
      final rId = (r['residentId'] ?? r['_id']).toString();
      if (assignedResidentIds.contains(rId)) return false;

      if (_searchTerm.isEmpty) return true;
      final fName = (r['firstName'] ?? '').toString().toLowerCase();
      final lName = (r['lastName'] ?? '').toString().toLowerCase();
      final searchLower = _searchTerm.toLowerCase();
      
      return fName.contains(searchLower) || lName.contains(searchLower) || rId.toLowerCase().contains(searchLower);
    }).toList();

    final String firstName = currentGuardian['firstName'] ?? '';
    final String lastName = currentGuardian['lastName'] ?? '';
    final String fullName = '$firstName $lastName'.trim();

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Elders',
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'For Guardian: ',
                              style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              fullName,
                              style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Currently Assigned',
                        style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: assignedElders.length >= 10 
                            ? (isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2))
                            : (isDark ? const Color(0xFF082F49).withValues(alpha: 0.3) : const Color(0xFFE1F5FE)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${assignedElders.length} / 10',
                          style: TextStyle(
                            fontFamily: 'Montserrat', 
                            fontSize: 12, 
                            fontWeight: FontWeight.w900, 
                            color: assignedElders.length >= 10 
                              ? (isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48)) 
                              : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8))
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  if (assignedElders.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), style: BorderStyle.solid),
                      ),
                      child: Text(
                        'No elders currently assigned to this guardian.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    )
                  else
                    ...assignedElders.map((elder) {
                      final eFirstName = elder['firstName'] ?? '';
                      final eLastName = elder['lastName'] ?? '';
                      final eId = elder['residentId'] ?? elder['_id'] ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$eFirstName $eLastName', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                  const SizedBox(height: 4),
                                  Text(eId, style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => _handleUnlink(eId),
                              style: TextButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2),
                                foregroundColor: isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Unassign', style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }),
                    
                  const SizedBox(height: 32),
                  Text(
                    'Available Residents',
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchTerm = val),
                      style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Search elders...',
                        hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (availableResidents.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No unassigned residents match your search.',
                          style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    )
                  else
                    ...availableResidents.map((res) {
                      final rFirstName = res['firstName'] ?? '';
                      final rLastName = res['lastName'] ?? '';
                      final rId = res['residentId'] ?? res['_id'] ?? '';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$rFirstName $rLastName', style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                  const SizedBox(height: 4),
                                  Text(rId, style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: assignedElders.length >= 10 ? null : () => _handleLink(rId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF00A8E8) : const Color(0xFF00A8E8),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Assign', style: TextStyle(fontFamily: 'Montserrat', fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}