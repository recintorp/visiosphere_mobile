import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/admin_nurses_provider.dart';
import '../widgets/delete_nurse_dialog.dart';

class AdminNurseDetailsScreen extends StatefulWidget {
  final dynamic nurse;

  const AdminNurseDetailsScreen({super.key, required this.nurse});

  @override
  State<AdminNurseDetailsScreen> createState() => _AdminNurseDetailsScreenState();
}

class _AdminNurseDetailsScreenState extends State<AdminNurseDetailsScreen> {
  late dynamic _currentNurse;
  final TextEditingController _elderSearchCtrl = TextEditingController();
  List<dynamic> _availableElders = [];
  bool _isLoadingElders = false;

  @override
  void initState() {
    super.initState();
    _currentNurse = widget.nurse;
    _fetchElders();
  }

  @override
  void dispose() {
    _elderSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchElders() async {
    setState(() => _isLoadingElders = true);
    
    final provider = context.read<AdminNursesProvider>();
    final elders = await provider.fetchAvailableElders();
    
    if (!mounted) return;
    
    setState(() {
      _availableElders = elders;
      _isLoadingElders = false;
    });
  }

  void _handleAssign(dynamic elder) async {
    final currentAssigned = List<dynamic>.from(_currentNurse['assignedElders'] ?? []);
    if (currentAssigned.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum capacity of 10 elders reached.', style: TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
      return;
    }

    final provider = context.read<AdminNursesProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.assignElderToNurse(
      _currentNurse['nurseId'],
      elder['_id'],
    );

    if (!mounted) return;

    if (success) {
      currentAssigned.add(elder);
      setState(() {
        _currentNurse = {
          ..._currentNurse,
          'assignedElders': currentAssigned,
        };
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('${elder['firstName']} assigned successfully.', style: const TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to assign elder. Please try again.', style: TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
    }
  }

  void _handleRemove(String elderId) async {
    final provider = context.read<AdminNursesProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final success = await provider.unassignElderFromNurse(
      _currentNurse['nurseId'],
      elderId,
    );

    if (!mounted) return;

    if (success) {
      final currentAssigned = List<dynamic>.from(_currentNurse['assignedElders'] ?? []);
      currentAssigned.removeWhere((e) => e['_id'] == elderId);
      
      setState(() {
        _currentNurse = {
          ..._currentNurse,
          'assignedElders': currentAssigned,
        };
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Elder unassigned successfully.', style: TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Failed to unassign elder. Please try again.', style: TextStyle(fontFamily: 'Montserrat')),
          backgroundColor: Color(0xFFE11D48),
        ),
      );
    }
  }

  void _showDeleteDialog() {
    final provider = context.read<AdminNursesProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => DeleteNurseDialog(
        nurseName: '${_currentNurse['firstName']} ${_currentNurse['lastName']}',
        onConfirm: () async {
          final dialogNavigator = Navigator.of(dialogContext);
          final nurseId = _currentNurse['nurseId'];
          
          final success = await provider.deleteNurse(nurseId);
          
          dialogNavigator.pop(); 
          
          if (!mounted) return;
          
          if (success) {
            navigator.pop(); 
          } else {
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Failed to delete nurse account.', style: TextStyle(fontFamily: 'Montserrat')),
                backgroundColor: Color(0xFFE11D48),
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditModal(bool isDark) {
    final firstNameCtrl = TextEditingController(text: _currentNurse['firstName'] ?? '');
    final middleNameCtrl = TextEditingController(text: _currentNurse['middleName'] ?? '');
    final lastNameCtrl = TextEditingController(text: _currentNurse['lastName'] ?? '');
    final emailCtrl = TextEditingController(text: _currentNurse['email'] ?? '');

    String selectedHouse = _currentNurse['houseAssigned'] ?? 'House of St. Charbel';
    String selectedStatus = _currentNurse['status'] ?? 'Active';

    final List<String> houses = [
      'House of St. Charbel',
      'House of St. Francis',
      'House of St. Gabriel',
      'House of St. Rose of Lima',
      'House of St. Sebastian',
      'Louis S. Coson Hall'
    ];
    final List<String> statuses = ['Active', 'Inactive', 'On Leave'];

    if (!houses.contains(selectedHouse)) selectedHouse = houses[0];
    if (!statuses.contains(selectedStatus)) selectedStatus = statuses[0];

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
                      'Edit Profile',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF00212E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update administrative details for ${_currentNurse['nurseId']}.',
                      style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey, fontSize: 14),
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
                      _buildFieldLabel('EMAIL ADDRESS *', isDark),
                      _buildEntryField(emailCtrl, 'nurse@visiosphere.gov', isDark, keyboardType: TextInputType.emailAddress),
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
                            icon: Icon(Icons.keyboard_arrow_down, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)),
                            style: TextStyle(fontFamily: 'Montserrat', color: isDark ? Colors.white : const Color(0xFF00212E), fontWeight: FontWeight.w600),
                            items: houses.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                            onChanged: (val) => setModalState(() => selectedHouse = val!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFieldLabel('ACCOUNT STATUS *', isDark),
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
                            value: selectedStatus,
                            icon: Icon(Icons.keyboard_arrow_down, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)),
                            style: TextStyle(fontFamily: 'Montserrat', color: isDark ? Colors.white : const Color(0xFF00212E), fontWeight: FontWeight.w600),
                            items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                            onChanged: (val) => setModalState(() => selectedStatus = val!),
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
                              child: Text('Cancel', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () async {
                                final provider = context.read<AdminNursesProvider>();
                                final success = await provider.updateNurseProfile(
                                  _currentNurse['nurseId'],
                                  {
                                    'firstName': firstNameCtrl.text,
                                    'middleName': middleNameCtrl.text,
                                    'lastName': lastNameCtrl.text,
                                    'email': emailCtrl.text,
                                    'houseAssigned': selectedHouse,
                                    'status': selectedStatus,
                                  }
                                );

                                if (!context.mounted) return;

                                if (success) {
                                  setState(() {
                                    _currentNurse['firstName'] = firstNameCtrl.text;
                                    _currentNurse['middleName'] = middleNameCtrl.text;
                                    _currentNurse['lastName'] = lastNameCtrl.text;
                                    _currentNurse['email'] = emailCtrl.text;
                                    _currentNurse['houseAssigned'] = selectedHouse;
                                    _currentNurse['status'] = selectedStatus;
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
                                backgroundColor: isDark ? const Color(0xFF00A8E8) : const Color(0xFF00446B),
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
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF00212E),
            letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildEntryField(TextEditingController ctrl, String hint, bool isDark, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String firstName = _currentNurse['firstName'] ?? '';
    final String lastName = _currentNurse['lastName'] ?? '';
    final String fullName = '$firstName $lastName';
    final String initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'N';
    final List<dynamic> assignedElders = _currentNurse['assignedElders'] ?? [];
    
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
          'Staff Details',
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
                    const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48), size: 20),
                    const SizedBox(width: 12),
                    Text('Revoke Access', style: TextStyle(fontFamily: 'Montserrat', color: const Color(0xFFE11D48), fontWeight: FontWeight.w600)),
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
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32, top: 16),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00A8E8), Color(0xFF0066CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066CC).withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
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
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _currentNurse['nurseId'] ?? 'N/A',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Assigned Residents',
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: assignedElders.length >= 10 
                              ? (isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2)) 
                              : (isDark ? const Color(0xFF082F49).withValues(alpha: 0.3) : const Color(0xFFE8F4FD)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${assignedElders.length} / 10',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: assignedElders.length >= 10 ? const Color(0xFFE11D48) : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0066CC)),
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
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline_rounded, size: 42, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                            const SizedBox(height: 12),
                            Text('No elders assigned.', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    else
                      ...assignedElders.map((elder) => FadeInLeft(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${elder['firstName']} ${elder['lastName']}',
                                    style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    elder['residentId'] ?? elder['_id'],
                                    style: TextStyle(fontFamily: 'monospace', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF4C0519).withValues(alpha: 0.3) : const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  onPressed: () => _handleRemove(elder['_id']),
                                  icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFE11D48)),
                                  tooltip: 'Unassign',
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),

                    const SizedBox(height: 32),
                    Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    const SizedBox(height: 24),

                    Text(
                      'Available Directory',
                      style: TextStyle(fontFamily: 'Montserrat', fontSize: 18, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 16, offset: const Offset(0, 4))],
                        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
                      ),
                      child: TextField(
                        controller: _elderSearchCtrl,
                        onChanged: (val) => setState(() {}),
                        style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Search by name or ID...',
                          hintStyle: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 14),
                          prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_isLoadingElders)
                      const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator(color: Color(0xFF00A8E8))))
                    else
                      ..._availableElders.where((e) {
                        final isAlreadyAssigned = assignedElders.any((assigned) => assigned['_id'] == e['_id']);
                        if (isAlreadyAssigned) return false;
                        
                        final search = _elderSearchCtrl.text.toLowerCase();
                        if (search.isEmpty) return true;
                        
                        final name = '${e['firstName']} ${e['lastName']}'.toLowerCase();
                        return name.contains(search);
                      }).map((elder) => FadeInUp(
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.transparent),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${elder['firstName']} ${elder['lastName']}',
                                    style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    elder['residentId'] ?? elder['_id'],
                                    style: TextStyle(fontFamily: 'monospace', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: assignedElders.length >= 10 ? null : () => _handleAssign(elder),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isDark ? const Color(0xFF00A8E8) : const Color(0xFF0066CC),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                ),
                                child: const Text('Assign', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      )),
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