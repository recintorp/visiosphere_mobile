import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/admin_guardians_provider.dart';

class AdminGuardiansScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final bool isNurseView;

  const AdminGuardiansScreen({super.key, this.onMenuTap, this.isNurseView = false});

  @override
  State<AdminGuardiansScreen> createState() => _AdminGuardiansScreenState();
}

class _AdminGuardiansScreenState extends State<AdminGuardiansScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<AdminGuardiansProvider>();
        provider.fetchGuardians();
        provider.fetchResidents();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditGuardianModal(BuildContext context, {dynamic existingGuardian}) {
    final isEdit = existingGuardian != null;
    
    final firstNameCtrl = TextEditingController(text: isEdit ? existingGuardian['firstName'] : '');
    final middleNameCtrl = TextEditingController(text: isEdit ? existingGuardian['middleName'] : '');
    final lastNameCtrl = TextEditingController(text: isEdit ? existingGuardian['lastName'] : '');
    final emailCtrl = TextEditingController(text: isEdit ? existingGuardian['email'] : '');
    final phoneCtrl = TextEditingController(text: isEdit ? existingGuardian['phone'] : '');
    
    DateTime? selectedDate;
    if (isEdit && existingGuardian['birthday'] != null && existingGuardian['birthday'].toString().isNotEmpty) {
      try {
        selectedDate = DateTime.parse(existingGuardian['birthday'].toString());
      } catch (_) {}
    }
    
    String? selectedGender = isEdit ? existingGuardian['gender'] : 'M';
    String? selectedStatus = isEdit ? existingGuardian['status'] : 'Active';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isEdit ? 'Edit Guardian' : 'Add New Guardian',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF001F2D)),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.close, color: Colors.blueGrey, size: 24),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildModalLabel('FIRST NAME *'),
                            _buildModalTextField(firstNameCtrl, 'Enter first name'),
                            const SizedBox(height: 16),
                            _buildModalLabel('MIDDLE NAME'),
                            _buildModalTextField(middleNameCtrl, 'Enter middle name'),
                            const SizedBox(height: 16),
                            _buildModalLabel('LAST NAME *'),
                            _buildModalTextField(lastNameCtrl, 'Enter last name'),
                            const SizedBox(height: 16),
                            _buildModalLabel('EMAIL ADDRESS *'),
                            _buildModalTextField(emailCtrl, 'Enter email address', keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildModalLabel('PHONE NUMBER *'),
                            _buildModalTextField(phoneCtrl, 'Enter contact number', keyboardType: TextInputType.phone),
                            const SizedBox(height: 16),
                            _buildModalLabel('BIRTHDAY *'),
                            GestureDetector(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate ?? DateTime(1980),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: const ColorScheme.light(primary: Color(0xFF0FB2EA)),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setModalState(() => selectedDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      selectedDate == null ? 'mm / dd / yyyy' : '${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                                      style: TextStyle(
                                        color: selectedDate == null ? Colors.blueGrey.withValues(alpha: 0.5) : const Color(0xFF001F2D),
                                        fontSize: 14,
                                      ),
                                    ),
                                    Icon(Icons.calendar_today, color: Colors.blueGrey.withValues(alpha: 0.5), size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildModalLabel('GENDER *'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: selectedGender,
                                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey.withValues(alpha: 0.5)),
                                  items: const [
                                    DropdownMenuItem(value: 'M', child: Text('Male')),
                                    DropdownMenuItem(value: 'F', child: Text('Female')),
                                  ],
                                  onChanged: (val) => setModalState(() => selectedGender = val),
                                ),
                              ),
                            ),
                            if (isEdit) ...[
                              const SizedBox(height: 16),
                              _buildModalLabel('STATUS *'),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedStatus,
                                    icon: Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey.withValues(alpha: 0.5)),
                                    items: const [
                                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                                      DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                                      DropdownMenuItem(value: 'Unassigned', child: Text('Unassigned')),
                                    ],
                                    onChanged: (val) => setModalState(() => selectedStatus = val),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);
                                final provider = context.read<AdminGuardiansProvider>();
                                
                                if (firstNameCtrl.text.trim().isEmpty || lastNameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                                  messenger.showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                                  return;
                                }
                                
                                final data = {
                                  'firstName': firstNameCtrl.text.trim(),
                                  'middleName': middleNameCtrl.text.trim(),
                                  'lastName': lastNameCtrl.text.trim(),
                                  'email': emailCtrl.text.trim(),
                                  'phone': phoneCtrl.text.trim(),
                                  'birthday': selectedDate?.toIso8601String(),
                                  'gender': selectedGender,
                                  if (isEdit) 'status': selectedStatus,
                                };
                                
                                bool success;
                                if (isEdit) {
                                  final id = existingGuardian['guardianId'] ?? existingGuardian['_id'];
                                  success = await provider.updateGuardian(id, data);
                                } else {
                                  success = await provider.addGuardian(data);
                                }

                                if (success) {
                                  navigator.pop();
                                  messenger.showSnackBar(SnackBar(content: Text(isEdit ? 'Guardian Updated' : 'Guardian Added')));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0FB2EA),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(isEdit ? 'Save Changes' : 'Add Guardian', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLinkResidentBottomSheet(BuildContext context, String guardianId) {
    final provider = context.read<AdminGuardiansProvider>();
    String? selectedResidentId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24, left: 24, right: 24
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Link Resident',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF001F2D)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.blueGrey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Select a resident to link to this guardian account.', style: TextStyle(color: Colors.blueGrey, fontSize: 14)),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedResidentId,
                        hint: Text('-- Choose a Resident --', style: TextStyle(color: Colors.blueGrey.withValues(alpha: 0.5), fontSize: 14)),
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.blueGrey.withValues(alpha: 0.5)),
                        items: provider.residents.map((res) {
                          final rId = res['residentId'] ?? res['_id'] ?? '';
                          final fName = res['firstName'] ?? '';
                          final lName = res['lastName'] ?? '';
                          final house = res['house'] ?? '';
                          return DropdownMenuItem<String>(
                            value: rId.toString(),
                            child: Text('$rId - $fName $lName ($house)', overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) => setSheetState(() => selectedResidentId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedResidentId == null) return;
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        
                        final success = await provider.linkResidentToGuardian(guardianId, selectedResidentId!);
                        if (success) {
                          navigator.pop();
                          messenger.showSnackBar(const SnackBar(content: Text('Resident linked successfully!')));
                        } else {
                          messenger.showSnackBar(const SnackBar(content: Text('Failed to link resident.')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0FB2EA),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm Link', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String guardianId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Guardian', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F2D))),
        content: const Text('Are you sure you want to delete this guardian? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final provider = context.read<AdminGuardiansProvider>();
              
              final success = await provider.deleteMultipleGuardians({guardianId});
              if (success) {
                navigator.pop();
                messenger.showSnackBar(const SnackBar(content: Text('Guardian deleted successfully')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildModalLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF001F2D)),
      ),
    );
  }

  Widget _buildModalTextField(TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF001F2D)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.blueGrey.withValues(alpha: 0.5), fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.blueGrey.withValues(alpha: 0.2))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF0FB2EA))),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF0066CC)),
            onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
          ),
          Image.asset(
            'assets/images/visio.png',
            height: 36,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Color(0xFF0066CC)),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: const Icon(Icons.notifications), color: const Color(0xFF0066CC), onPressed: () {}),
              Positioned(
                right: 12,
                top: 12,
                child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      floatingActionButton: widget.isNurseView 
        ? null 
        : FloatingActionButton(
            onPressed: () => _showAddEditGuardianModal(context),
            backgroundColor: const Color(0xFF0FB2EA),
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomAppBar(),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 130,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F4FD),
                    borderRadius: BorderRadius.only(bottomRight: Radius.circular(60)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        child: const Text(
                          'Account Management',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F2D)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInDown(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 100),
                        child: const Text(
                          'Guardians Management',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0066CC)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F9FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blueGrey.withValues(alpha: 0.1)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => context.read<AdminGuardiansProvider>().setSearchTerm(value),
                      decoration: const InputDecoration(
                        hintText: 'Search by ID, Name, Email...',
                        hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.blueGrey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer<AdminGuardiansProvider>(
                    builder: (context, provider, child) {
                      return Row(
                        children: [
                          _buildSortPill('A-Z ↓', 'asc', provider),
                          const SizedBox(width: 8),
                          _buildSortPill('Z-A ↑', 'desc', provider),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<AdminGuardiansProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF0FB2EA)));
                  }

                  final guardians = provider.filteredGuardians;

                  if (guardians.isEmpty) {
                    return const Center(
                      child: Text('No guardians found.', style: TextStyle(color: Colors.blueGrey, fontSize: 16)),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: provider.fetchGuardians,
                    color: const Color(0xFF0FB2EA),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 80),
                      itemCount: guardians.length,
                      itemBuilder: (context, index) {
                        final guardian = guardians[index];
                        return FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 50),
                          child: _buildGuardianCard(guardian, context),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortPill(String label, String sortValue, AdminGuardiansProvider provider) {
    final isActive = provider.sortOrder == sortValue;
    return GestureDetector(
      onTap: () => provider.toggleSortOrder(sortValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0FB2EA) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFF0FB2EA) : Colors.blueGrey.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.blueGrey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildGuardianCard(dynamic guardian, BuildContext context) {
    final String firstName = guardian['firstName'] ?? '';
    final String lastName = guardian['lastName'] ?? '';
    final String fullName = '$firstName $lastName';
    final String guardianId = guardian['guardianId'] ?? 'N/A';
    final String email = guardian['email'] ?? 'No Email';
    final String phone = guardian['phone'] ?? 'No Phone';
    final String status = guardian['status'] ?? 'Unassigned';
    
    final eldersList = guardian['assignedElders'] as List<dynamic>? ?? [];
    final assignedStr = eldersList.isEmpty 
        ? 'Unassigned' 
        : eldersList.map((e) => '${e['firstName']} ${e['lastName']}').join(', ');

    Color statusColor = Colors.blueGrey;
    if (status.toLowerCase() == 'active') statusColor = Colors.green;
    if (status.toLowerCase() == 'inactive') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.blueGrey.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFE8F4FD), borderRadius: BorderRadius.circular(6)),
                      child: Text(guardianId, style: const TextStyle(color: Color(0xFF0066CC), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
                    ),
                  ],
                ),
                if (!widget.isNurseView)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.blueGrey),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddEditGuardianModal(context, existingGuardian: guardian);
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, guardian['guardianId'] ?? guardian['_id']);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blueGrey), SizedBox(width: 8), Text('Edit')])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                    ],
                  ),
              ],
            ),
            Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF001F2D))),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.email_outlined, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(child: Text(email, style: const TextStyle(color: Colors.blueGrey, fontSize: 13), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(phone, style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.blueGrey.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Assigned Elders:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 4),
                      Text(
                        assignedStr,
                        style: TextStyle(
                          color: eldersList.isEmpty ? Colors.blueGrey.withValues(alpha: 0.5) : const Color(0xFF001F2D),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!widget.isNurseView)
                  OutlinedButton.icon(
                    onPressed: () => _showLinkResidentBottomSheet(context, guardian['guardianId'] ?? guardian['_id']),
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('Link', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0FB2EA),
                      side: const BorderSide(color: Color(0xFF0FB2EA)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      minimumSize: Size.zero,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}