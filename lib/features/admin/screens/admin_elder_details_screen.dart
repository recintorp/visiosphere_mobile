import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/admin_elders_provider.dart';
import '../widgets/delete_elder_dialog.dart';

class AdminElderDetailsScreen extends StatefulWidget {
  final dynamic resident;

  const AdminElderDetailsScreen({super.key, required this.resident});

  @override
  State<AdminElderDetailsScreen> createState() => _AdminElderDetailsScreenState();
}

class _AdminElderDetailsScreenState extends State<AdminElderDetailsScreen> {
  late dynamic _currentResident;
  final TextEditingController _notesController = TextEditingController();
  bool _isEditingNotes = false;

  final List<String> _houses = [
    'House of St. Charbel',
    'House of St. Francis',
    'House of St. Gabriel',
    'House of St. Rose of Lima',
    'House of St. Sebastian',
    'Louis S. Coson Hall'
  ];

  @override
  void initState() {
    super.initState();
    _currentResident = widget.resident;
    _notesController.text = _currentResident['notes'] ?? '';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _showDeleteDialog() {
    final provider = context.read<AdminEldersProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    final firstName = _currentResident['firstName'] ?? '';
    final lastName = _currentResident['lastName'] ?? '';
    final residentId = _currentResident['_id'] ?? _currentResident['id'] ?? '';

    showDialog(
      context: context,
      builder: (dialogContext) => DeleteElderDialog(
        elderName: '$firstName $lastName',
        onConfirm: () async {
          final dialogNavigator = Navigator.of(dialogContext);
          
          final success = await provider.deleteResident(residentId);
          
          dialogNavigator.pop(); 
          
          if (!mounted) return;
          
          if (success) {
            navigator.pop(); 
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Resident deleted successfully.', style: TextStyle(fontFamily: 'Montserrat')),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Failed to delete resident.', style: TextStyle(fontFamily: 'Montserrat')),
                backgroundColor: Color(0xFFE11D48),
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditModal(bool isDark) {
    final firstNameCtrl = TextEditingController(text: _currentResident['firstName'] ?? '');
    final middleNameCtrl = TextEditingController(text: _currentResident['middleName'] ?? '');
    final lastNameCtrl = TextEditingController(text: _currentResident['lastName'] ?? '');

    String selectedHouse = _currentResident['house'] ?? _houses[0];
    if (!_houses.contains(selectedHouse)) selectedHouse = _houses[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Edit Resident Profile',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update details for ${_currentResident['residentId']}.',
                      style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildFieldLabel('FIRST NAME *', isDark),
                      _buildEntryField(firstNameCtrl, 'Enter first name', isDark),
                      const SizedBox(height: 16),
                      _buildFieldLabel('MIDDLE NAME', isDark),
                      _buildEntryField(middleNameCtrl, 'Optional', isDark),
                      const SizedBox(height: 16),
                      _buildFieldLabel('LAST NAME *', isDark),
                      _buildEntryField(lastNameCtrl, 'Enter last name', isDark),
                      const SizedBox(height: 16),
                      _buildFieldLabel('HOUSE ASSIGNMENT *', isDark),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(12),
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            value: selectedHouse,
                            icon: Icon(Icons.keyboard_arrow_down, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0066CC)),
                            style: TextStyle(fontFamily: 'Montserrat', color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                            items: _houses.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                            onChanged: (val) => setModalState(() => selectedHouse = val!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!, width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('Cancel', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                final provider = context.read<AdminEldersProvider>();
                                final residentId = _currentResident['_id'] ?? _currentResident['id'];
                                
                                final success = await provider.updateResident(
                                  residentId,
                                  {
                                    'firstName': firstNameCtrl.text,
                                    'middleName': middleNameCtrl.text,
                                    'lastName': lastNameCtrl.text,
                                    'house': selectedHouse,
                                  }
                                );

                                if (!context.mounted) return;

                                if (success) {
                                  setState(() {
                                    _currentResident['firstName'] = firstNameCtrl.text;
                                    _currentResident['middleName'] = middleNameCtrl.text;
                                    _currentResident['lastName'] = lastNameCtrl.text;
                                    _currentResident['house'] = selectedHouse;
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Profile updated successfully.', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFF10B981)),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to update profile.', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF00A8E8) : const Color(0xFF00A8E8),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('Save Changes', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  Widget _buildFieldLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildEntryField(TextEditingController ctrl, String hint, bool isDark) {
    return TextField(
      controller: ctrl,
      style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : Colors.grey, fontSize: 14),
        filled: true,
        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), width: 2),
        ),
      ),
    );
  }

  Future<void> _handleAttendanceUpdate(String status) async {
    final provider = context.read<AdminEldersProvider>();
    final residentId = _currentResident['_id'] ?? _currentResident['id'];
    
    final success = await provider.updateAttendance(residentId, status);
    
    if (!mounted) return;
    
    if (success) {
      setState(() {
        _currentResident['attendance'] = status;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked as $status', style: const TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: status == 'Present' ? const Color(0xFF10B981) : const Color(0xFFE11D48),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update attendance', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)),
      );
    }
  }

  Future<void> _handleSaveNotes() async {
    final provider = context.read<AdminEldersProvider>();
    final residentId = _currentResident['_id'] ?? _currentResident['id'];
    
    final success = await provider.saveNotes(residentId, _notesController.text);
    
    if (!mounted) return;
    
    if (success) {
      setState(() {
        _currentResident['notes'] = _notesController.text;
        _isEditingNotes = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes saved successfully', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFF10B981)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save notes', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String firstName = _currentResident['firstName'] ?? '';
    final String middleName = _currentResident['middleName'] ?? '';
    final String lastName = _currentResident['lastName'] ?? '';
    final String fullName = middleName.trim().isEmpty ? '$firstName $lastName' : '$firstName $middleName $lastName';
    final String initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'E';
    
    final String house = _currentResident['house'] ?? 'Unassigned';
    final String? attendance = _currentResident['attendance'];

    Color statusColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B); 
    Color statusBgColor = isDark ? const Color(0xFF78350F).withValues(alpha: 0.3) : const Color(0xFFFFFBEB);
    String attendanceText = 'Unmarked';

    if (attendance == 'Present') {
      statusColor = isDark ? const Color(0xFF34D399) : const Color(0xFF10B981); 
      statusBgColor = isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5);
      attendanceText = 'Present';
    } else if (attendance == 'Not Present') {
      statusColor = isDark ? const Color(0xFFFB7185) : const Color(0xFFE11D48); 
      statusBgColor = isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2);
      attendanceText = 'Absent';
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Resident Profile',
          style: TextStyle(fontFamily: 'Montserrat', color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteDialog();
              } else if (value == 'edit') {
                _showEditModal(isDark);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 20),
                    const SizedBox(width: 12),
                    Text('Edit Profile', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.person_off_rounded, color: Color(0xFFE11D48), size: 20),
                    const SizedBox(width: 12),
                    Text('Delete Resident', style: TextStyle(fontFamily: 'Montserrat', color: const Color(0xFFE11D48), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02), blurRadius: 8, offset: const Offset(0, 4))
                ],
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
              ),
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 16),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF0284C7).withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6))
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: TextStyle(fontFamily: 'Montserrat', fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A), letterSpacing: -0.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      _currentResident['residentId'] ?? 'N/A',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.home_work_rounded, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('House Assignment', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                  const SizedBox(height: 4),
                                  Text(house, style: TextStyle(fontFamily: 'Montserrat', color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: const Duration(milliseconds: 100),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          boxShadow: [BoxShadow(color: statusColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Today\'s Attendance', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(12)),
                                  child: Text(attendanceText.toUpperCase(), style: TextStyle(fontFamily: 'Montserrat', color: statusColor, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleAttendanceUpdate('Present'),
                                    icon: const Icon(Icons.how_to_reg_rounded, size: 18),
                                    label: const Text('Present', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: attendance == 'Present' ? const Color(0xFF10B981) : (isDark ? const Color(0xFF0F172A) : Colors.white),
                                      foregroundColor: attendance == 'Present' ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      elevation: 0,
                                      side: BorderSide(color: attendance == 'Present' ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleAttendanceUpdate('Not Present'),
                                    icon: const Icon(Icons.person_off_rounded, size: 18),
                                    label: const Text('Absent', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: attendance == 'Not Present' ? const Color(0xFFE11D48) : (isDark ? const Color(0xFF0F172A) : Colors.white),
                                      foregroundColor: attendance == 'Not Present' ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      elevation: 0,
                                      side: BorderSide(color: attendance == 'Not Present' ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    FadeInUp(
                      duration: const Duration(milliseconds: 300),
                      delay: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Monitoring Notes', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                if (!_isEditingNotes)
                                  InkWell(
                                    onTap: () => setState(() => _isEditingNotes = true),
                                    child: Icon(Icons.edit_note_rounded, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), size: 24),
                                  )
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_isEditingNotes) ...[
                              TextField(
                                controller: _notesController,
                                maxLines: 5,
                                style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                decoration: InputDecoration(
                                  hintText: 'Enter behavioral observations, health concerns...',
                                  hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8))),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _notesController.text = _currentResident['notes'] ?? '';
                                        _isEditingNotes = false;
                                      });
                                    },
                                    child: Text('Cancel', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _handleSaveNotes,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF00A8E8),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Save Notes', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              )
                            ] else ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                ),
                                child: Text(
                                  _notesController.text.trim().isEmpty ? 'No notes added for this resident yet.' : _notesController.text,
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    color: _notesController.text.trim().isEmpty ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                    fontSize: 14,
                                    height: 1.5,
                                    fontWeight: _notesController.text.trim().isEmpty ? FontWeight.w500 : FontWeight.w600,
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
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