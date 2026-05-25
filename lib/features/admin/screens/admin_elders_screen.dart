import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:go_router/go_router.dart';
import '../providers/admin_elders_provider.dart';
import '../providers/admin_dashboard_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../widgets/elder_card.dart';
import '../widgets/generate_report_modal.dart';
import '../widgets/archived_reports_modal.dart';

class AdminEldersScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;
  final bool isNurseView;

  const AdminEldersScreen({super.key, this.onMenuTap, this.isNurseView = false});

  @override
  State<AdminEldersScreen> createState() => _AdminEldersScreenState();
}

class _AdminEldersScreenState extends State<AdminEldersScreen> {
  final TextEditingController _searchController = TextEditingController();

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        final dashboardProvider = context.read<AdminDashboardProvider>();
        
        bool isSimulatingAdmin = widget.isNurseView && authProvider.userRole == 'Facility Admin';

        context.read<AdminEldersProvider>().fetchResidents(
          userRole: isSimulatingAdmin ? 'Nurse' : authProvider.userRole,
          userId: isSimulatingAdmin ? dashboardProvider.nurseId : authProvider.userId,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddResidentModal(BuildContext context, bool isDark) {
    final firstNameCtrl = TextEditingController();
    final middleNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    String selectedHouse = _houses[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              Text('Add New Resident', style: TextStyle(fontFamily: 'Montserrat', fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              Text('Create a new elder profile for the facility', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 14)),
              const SizedBox(height: 24),
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
                    value: selectedHouse,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0066CC)),
                    style: TextStyle(fontFamily: 'Montserrat', color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                    items: _houses.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                    onChanged: (val) => setModalState(() => selectedHouse = val!),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (firstNameCtrl.text.trim().isEmpty || lastNameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('First and Last name required', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)));
                      return;
                    }
                    
                    final success = await context.read<AdminEldersProvider>().addResident({
                      'firstName': firstNameCtrl.text.trim(),
                      'middleName': middleNameCtrl.text.trim(),
                      'lastName': lastNameCtrl.text.trim(),
                      'house': selectedHouse,
                    });
                    
                    if (!context.mounted) return;
                    
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Resident Added Successfully', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFF10B981)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add resident', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)));
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A8E8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                  child: const Text('Save Resident', style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
      child: Text(label, style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A), letterSpacing: 0.5)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00A8E8), width: 2)),
      ),
    );
  }

  Future<void> _handleExcelImport() async {
    final provider = context.read<AdminEldersProvider>();
    final messenger = ScaffoldMessenger.of(context);
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result != null && result.files.single.path != null) {
        var file = result.files.single.path!;
        var bytes = File(file).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);
        
        List<Map<String, dynamic>> importedResidents = [];
        
        for (var table in excel.tables.keys) {
          for (var row in excel.tables[table]!.rows.skip(1)) {
            if (row.isEmpty || row[0]?.value == null) continue;
            
            String fullName = row[0]!.value.toString().trim();
            if (fullName.isEmpty) continue;

            List<String> nameParts = fullName.split(RegExp(r'\s+'));
            String fName = '';
            String mName = '';
            String lName = '';

            if (nameParts.length == 1) {
              fName = nameParts[0];
            } else if (nameParts.length == 2) {
              fName = nameParts[0];
              lName = nameParts[1];
            } else {
              fName = nameParts[0];
              lName = nameParts.last;
              mName = nameParts.sublist(1, nameParts.length - 1).join(' ');
            }

            String houseAssigned = provider.selectedHouse;
            if (houseAssigned == 'Overall Facility') houseAssigned = _houses[0];

            importedResidents.add({
              'firstName': fName,
              'middleName': mName,
              'lastName': lName,
              'house': houseAssigned,
            });
          }
        }

        if (importedResidents.isEmpty) {
          messenger.showSnackBar(const SnackBar(content: Text('No valid data found in Excel.', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)));
          return;
        }

        messenger.showSnackBar(const SnackBar(content: Text('Importing residents... This might take a moment.', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFF00A8E8)));
        
        int successCount = 0;
        for (var res in importedResidents) {
           bool ok = await provider.addResident(res);
           if(ok) successCount++;
        }
        
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(SnackBar(content: Text('Successfully imported $successCount residents.', style: const TextStyle(fontFamily: 'Montserrat')), backgroundColor: const Color(0xFF10B981)));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error importing Excel: $e', style: const TextStyle(fontFamily: 'Montserrat')), backgroundColor: const Color(0xFFE11D48)));
    }
  }

  void _showGenerateReportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const GenerateReportModal(),
    );
  }

  void _showArchivedReportsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ArchivedReportsModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: widget.isNurseView 
        ? null 
        : FloatingActionButton.extended(
            onPressed: () => _showAddResidentModal(context, isDark),
            backgroundColor: const Color(0xFF00A8E8),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 24),
            label: const Text(
              'Add Resident',
              style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCustomAppBar(isDark),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
                        : [const Color(0xFFE8F4FD), const Color(0xFFF8FAFC)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  right: -20,
                  top: 10,
                  child: Opacity(
                    opacity: isDark ? 0.3 : 0.6,
                    child: Image.asset(
                      'assets/images/logogo.png',
                      height: 140,
                      width: 140,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const SizedBox(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FadeInDown(
                            duration: const Duration(milliseconds: 500),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF00A8E8).withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]
                              ),
                              child: Text(
                                'Account Management',
                                style: TextStyle(fontFamily: 'Montserrat', fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), letterSpacing: 0.5),
                              ),
                            ),
                          ),
                          if (!widget.isNurseView)
                            FadeInDown(
                              duration: const Duration(milliseconds: 500),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: _showArchivedReportsModal,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFF64748B).withValues(alpha: 0.3)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.inventory_2_rounded, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                          const SizedBox(width: 6),
                                          Text('Archive', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w700, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _handleExcelImport,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF082F49).withValues(alpha: 0.5) : Colors.white,
                                        border: Border.all(color: isDark ? const Color(0xFF0369A1) : const Color(0xFF00A8E8).withValues(alpha: 0.3)),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.upload_file_rounded, size: 16, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)),
                                          const SizedBox(width: 4),
                                          Text('Import', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), fontWeight: FontWeight.w700, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                        ],
                      ),
                      const SizedBox(height: 12),
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          'Elders Directory',
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 32, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF0F172A), letterSpacing: -0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          'Daily attendance & master checklist.',
                          style: TextStyle(fontFamily: 'Montserrat', fontSize: 14, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w500, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => context.read<AdminEldersProvider>().setSearchTerm(value),
                  style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Search by Resident ID or Name...',
                    hintStyle: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Consumer<AdminEldersProvider>(
              builder: (context, provider, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Filter by House', style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                          InkWell(
                            onTap: _showGenerateReportModal,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.analytics_rounded, size: 16, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8)),
                                  const SizedBox(width: 6),
                                  Text('Generate Report', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8), fontWeight: FontWeight.w800, fontSize: 12)),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildHousePill('Overall Facility', provider, isDark),
                          ..._houses.map((h) => _buildHousePill(h, provider, isDark)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Status & Notes', style: TextStyle(fontFamily: 'Montserrat', fontSize: 13, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _buildAttendanceFilterPill('All', provider, isDark),
                          _buildAttendanceFilterPill('Present', provider, isDark),
                          _buildAttendanceFilterPill('Not Present', provider, isDark),
                          Container(width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6)),
                          _buildNotesFilterPill('All', provider, isDark),
                          _buildNotesFilterPill('WithNotes', provider, isDark),
                          _buildNotesFilterPill('NoNotes', provider, isDark),
                        ],
                      ),
                    ),
                  ],
                );
              }
            ),

            const SizedBox(height: 16),

            Expanded(
              child: Consumer<AdminEldersProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF00A8E8)));
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 48),
                          const SizedBox(height: 16),
                          Text(provider.errorMessage!, style: TextStyle(fontFamily: 'Montserrat', color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              final authProvider = context.read<AuthProvider>();
                              final dashboardProvider = context.read<AdminDashboardProvider>();
                              bool isSimulatingAdmin = widget.isNurseView && authProvider.userRole == 'Facility Admin';
                              
                              provider.fetchResidents(
                                userRole: isSimulatingAdmin ? 'Nurse' : authProvider.userRole,
                                userId: isSimulatingAdmin ? dashboardProvider.nurseId : authProvider.userId,
                              );
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00A8E8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            child: const Text('Retry', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }

                  final residents = provider.filteredResidents;

                  if (residents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.groups_rounded, size: 64, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          const SizedBox(height: 16),
                          Text('No residents found.', style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      final authProvider = context.read<AuthProvider>();
                      final dashboardProvider = context.read<AdminDashboardProvider>();
                      bool isSimulatingAdmin = widget.isNurseView && authProvider.userRole == 'Facility Admin';
                      
                      await provider.fetchResidents(
                        userRole: isSimulatingAdmin ? 'Nurse' : authProvider.userRole,
                        userId: isSimulatingAdmin ? dashboardProvider.nurseId : authProvider.userId,
                      );
                    },
                    color: const Color(0xFF00A8E8),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 100),
                      itemCount: residents.length,
                      itemBuilder: (context, index) {
                        final resident = residents[index];
                        final id = resident['_id'] ?? resident['id'] ?? '';
                        
                        return FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 50),
                          child: Dismissible(
                            key: Key(id),
                            background: _buildSwipeBackground(const Color(0xFF10B981), Icons.how_to_reg_rounded, 'Mark Present', Alignment.centerLeft),
                            secondaryBackground: _buildSwipeBackground(const Color(0xFFE11D48), Icons.person_off_rounded, 'Mark Absent', Alignment.centerRight),
                            confirmDismiss: (direction) async {
                              final status = direction == DismissDirection.startToEnd ? 'Present' : 'Not Present';
                              final messenger = ScaffoldMessenger.of(context);
                              await provider.updateAttendance(id, status);
                              messenger.clearSnackBars();
                              messenger.showSnackBar(SnackBar(
                                content: Text('Marked as $status', style: const TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600)),
                                backgroundColor: status == 'Present' ? const Color(0xFF10B981) : const Color(0xFFE11D48),
                                duration: const Duration(seconds: 1),
                              ));
                              return false; 
                            },
                            child: ElderCard(
                              resident: resident,
                              onTap: () {
                                context.push('/admin-elder-details', extra: resident);
                              },
                            ),
                          ),
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

  Widget _buildSwipeBackground(Color color, IconData icon, String text, Alignment alignment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHousePill(String house, AdminEldersProvider provider, bool isDark) {
    final isActive = provider.selectedHouse == house;
    final shortName = house.replaceAll('House of St. ', '');
    return GestureDetector(
      onTap: () => provider.setHouse(house),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A)) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
          boxShadow: isActive 
            ? [BoxShadow(color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A)).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] 
            : [],
        ),
        alignment: Alignment.center,
        child: Text(
          shortName.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: isActive ? (isDark ? const Color(0xFF0F172A) : Colors.white) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceFilterPill(String status, AdminEldersProvider provider, bool isDark) {
    final isActive = provider.filterAttendance == status;
    return GestureDetector(
      onTap: () => provider.setFilterAttendance(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00A8E8) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        ),
        alignment: Alignment.center,
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: isActive ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildNotesFilterPill(String status, AdminEldersProvider provider, bool isDark) {
    final isActive = provider.filterNotes == status;
    String label = status == 'All' ? 'ALL NOTES' : status == 'WithNotes' ? 'HAS NOTES' : 'NO NOTES';
    return GestureDetector(
      onTap: () => provider.setFilterNotes(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF59E0B) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? Colors.transparent : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: isActive ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F4FD),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 28),
            onPressed: widget.onMenuTap ?? () => Scaffold.of(context).openDrawer(),
          ),
          Image.asset(
            'assets/images/visio.png',
            height: 34,
            fit: BoxFit.contain,
            color: isDark ? Colors.white : null,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.security, color: Color(0xFF00A8E8), size: 32),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, size: 28, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                onPressed: () {},
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4757),
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}