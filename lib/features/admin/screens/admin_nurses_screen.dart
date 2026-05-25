import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_nurses_provider.dart';
import '../widgets/nurse_card.dart';

class AdminNursesScreen extends StatefulWidget {
  final VoidCallback? onMenuTap;

  const AdminNursesScreen({super.key, this.onMenuTap});

  @override
  State<AdminNursesScreen> createState() => _AdminNursesScreenState();
}

class _AdminNursesScreenState extends State<AdminNursesScreen> {
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
        context.read<AdminNursesProvider>().fetchNurses();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProvisionModal(BuildContext context) {
    final firstNameCtrl = TextEditingController();
    final middleNameCtrl = TextEditingController();
    final lastNameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedHouse = _houses[0];
    
    bool isDark = Theme.of(context).brightness == Brightness.dark;

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
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Provision Account',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF00212E),
                ),
              ),
              Text(
                'Create a new staff profile for the facility',
                style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : Colors.blueGrey, fontSize: 14),
              ),
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
              _buildFieldLabel('FACILITY EMAIL *', isDark),
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
                    value: selectedHouse,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    icon: Icon(Icons.keyboard_arrow_down, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0066CC)),
                    style: TextStyle(fontFamily: 'Montserrat', color: isDark ? Colors.white : const Color(0xFF00212E), fontWeight: FontWeight.w600),
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
                    final success = await context.read<AdminNursesProvider>().provisionNurse({
                      'firstName': firstNameCtrl.text,
                      'middleName': middleNameCtrl.text,
                      'lastName': lastNameCtrl.text,
                      'email': emailCtrl.text,
                      'houseAssigned': selectedHouse,
                    });
                    if (!context.mounted) return;
                    if (success) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account provisioned successfully', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFF10B981)),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to provision account', style: TextStyle(fontFamily: 'Montserrat')), backgroundColor: Color(0xFFE11D48)),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF00A8E8) : const Color(0xFF0FB2EA),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontFamily: 'Montserrat', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
          borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0FB2EA), width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProvisionModal(context),
        backgroundColor: const Color(0xFF0066CC),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        label: const Text(
          'Provision',
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
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF00A8E8).withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                            ]
                          ),
                          child: Text(
                            'Account Management',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF00A8E8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          'Nurses Registry',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        delay: const Duration(milliseconds: 200),
                        child: Text(
                          'Provision and manage medical staff accounts.',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 14,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4))
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        context.read<AdminNursesProvider>().setSearchTerm(value);
                      },
                      style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'Search by Nurse ID or Name...',
                        hintStyle: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w500),
                        prefixIcon: Icon(Icons.search_rounded, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 38,
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () {
                            context.read<AdminNursesProvider>().toggleSortOrder();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              boxShadow: [
                                BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))
                              ],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              children: [
                                Icon(Icons.sort_by_alpha_rounded, size: 16, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                const SizedBox(width: 6),
                                Text(
                                  'Sort',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Consumer<AdminNursesProvider>(
                            builder: (context, provider, child) {
                              return ListView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  _buildFilterPill('All', provider, isDark),
                                  _buildFilterPill('Active', provider, isDark),
                                  _buildFilterPill('Inactive', provider, isDark),
                                  _buildFilterPill('On Leave', provider, isDark),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<AdminNursesProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF00A8E8)),
                    );
                  }

                  if (provider.errorMessage != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFE11D48), size: 48),
                          const SizedBox(height: 16),
                          Text(
                            provider.errorMessage!,
                            style: TextStyle(fontFamily: 'Montserrat', color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: provider.fetchNurses,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A8E8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Retry', style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }

                  final nurses = provider.nurses;

                  if (nurses.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_search_rounded, size: 64, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          const SizedBox(height: 16),
                          Text(
                            'No nurses found.',
                            style: TextStyle(fontFamily: 'Montserrat', color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: provider.fetchNurses,
                    color: const Color(0xFF00A8E8),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 100),
                      itemCount: nurses.length,
                      itemBuilder: (context, index) {
                        final nurse = nurses[index];
                        return FadeInUp(
                          duration: const Duration(milliseconds: 400),
                          delay: Duration(milliseconds: index * 50),
                          child: NurseCard(
                            nurse: nurse,
                            onTap: () {
                              context.push('/admin-nurse-details', extra: nurse);
                            },
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

  Widget _buildFilterPill(String status, AdminNursesProvider provider, bool isDark) {
    final isActive = provider.filterStatus == status;
    return GestureDetector(
      onTap: () => provider.setFilterStatus(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A)) : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [BoxShadow(color: (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A)).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]
              : [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFF0F172A).withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        alignment: Alignment.center,
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Montserrat',
            color: isActive ? (isDark ? const Color(0xFF0F172A) : Colors.white) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.security, color: Color(0xFF00A8E8), size: 32),
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